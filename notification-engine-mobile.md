# Mobile Notification Engine Integration

## Overview
This documentation covers how to integrate React Native mobile applications with our WebSocket-based notification engine.

## Setup Requirements

### 1. Dependencies
```json
{
  "dependencies": {
    "socket.io-client": "^4.7.2",
    "@react-native-async-storage/async-storage": "^1.21.0",
    "@react-native-community/netinfo": "^11.2.1",
    "react-native-background-timer": "^2.4.1"
  }
}
```

### 2. Permissions (Android)
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### 3. Capabilities (iOS)
```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

## Implementation

### 1. Mobile Notification Service
```typescript
// src/services/MobileNotificationService.ts
import { io, Socket } from 'socket.io-client';
import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import BackgroundTimer from 'react-native-background-timer';

export class MobileNotificationService {
  private static instance: MobileNotificationService;
  private socket: Socket | null = null;
  private connected: boolean = false;
  private notificationCallbacks: ((notification: any) => void)[] = [];
  private connectionCallbacks: ((status: boolean) => void)[] = [];
  private retryCount = 0;
  private maxRetries = 10;
  private heartbeatInterval: number | null = null;
  private backgroundTaskId: number | null = null;

  private constructor() {
    // Initialize network monitoring
    NetInfo.addEventListener(state => {
      if (state.isConnected && !this.connected) {
        this.reconnect();
      }
    });
  }

  static getInstance(): MobileNotificationService {
    if (!MobileNotificationService.instance) {
      MobileNotificationService.instance = new MobileNotificationService();
    }
    return MobileNotificationService.instance;
  }

  async connect(userId: string) {
    try {
      // Get stored tokens
      const userToken = await AsyncStorage.getItem('userToken');
      const tenantToken = await AsyncStorage.getItem('tenantToken');

      if (!userToken || !tenantToken) {
        throw new Error('Missing authentication tokens');
      }

      const NOTIFICATION_SERVER = 'YOUR_NOTIFICATION_SERVER_URL';

      const socketConfig = {
        path: '/socket.io',
        auth: {
          token: userToken,
          tenantToken,
          userId,
          platform: 'mobile'
        },
        transports: ['websocket'],
        reconnection: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 1000,
        timeout: 20000
      };

      this.socket = io(NOTIFICATION_SERVER, socketConfig);
      this.setupEventListeners();
      this.startHeartbeat();
    } catch (error) {
      console.error('Connection error:', error);
      this.handleConnectionError();
    }
  }

  private setupEventListeners() {
    if (!this.socket) return;

    this.socket.on('connect', () => {
      this.connected = true;
      this.retryCount = 0;
      this.connectionCallbacks.forEach(cb => cb(true));
    });

    this.socket.on('disconnect', () => {
      this.connected = false;
      this.connectionCallbacks.forEach(cb => cb(false));
      this.reconnect();
    });

    this.socket.on('notification', (notification) => {
      // Handle incoming notification
      this.notificationCallbacks.forEach(cb => cb(notification));
    });
  }

  private startHeartbeat() {
    // Clear existing heartbeat
    if (this.heartbeatInterval) {
      BackgroundTimer.clearInterval(this.heartbeatInterval);
    }

    // Start new heartbeat
    this.heartbeatInterval = BackgroundTimer.setInterval(() => {
      if (this.socket?.connected) {
        this.socket.emit('heartbeat');
      }
    }, 30000);
  }

  private async handleConnectionError() {
    if (this.retryCount >= this.maxRetries) {
      return;
    }

    const delay = Math.min(1000 * Math.pow(2, this.retryCount), 30000);
    this.retryCount++;

    await new Promise(resolve => setTimeout(resolve, delay));
    await this.reconnect();
  }

  private async reconnect() {
    const netInfo = await NetInfo.fetch();
    if (!netInfo.isConnected) return;

    try {
      await this.connect(await AsyncStorage.getItem('userId') || '');
    } catch (error) {
      console.error('Reconnection error:', error);
      this.handleConnectionError();
    }
  }

  onNotification(callback: (notification: any) => void) {
    this.notificationCallbacks.push(callback);
    return () => {
      this.notificationCallbacks = this.notificationCallbacks.filter(cb => cb !== callback);
    };
  }

  onConnectionChange(callback: (status: boolean) => void) {
    this.connectionCallbacks.push(callback);
    return () => {
      this.connectionCallbacks = this.connectionCallbacks.filter(cb => cb !== callback);
    };
  }

  disconnect() {
    if (this.heartbeatInterval) {
      BackgroundTimer.clearInterval(this.heartbeatInterval);
    }
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
    this.connected = false;
  }
}
```

### 2. Notification Hook
```typescript
// src/hooks/useNotifications.ts
import { useState, useEffect, useCallback } from 'react';
import { MobileNotificationService } from '../services/MobileNotificationService';
import { useAuth } from './useAuth';

export const useNotifications = () => {
  const [notifications, setNotifications] = useState([]);
  const [isConnected, setIsConnected] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const { user } = useAuth();
  const notificationService = MobileNotificationService.getInstance();

  useEffect(() => {
    if (!user?.id) return;

    // Connect to notification service
    notificationService.connect(user.id);

    // Handle notifications
    const unsubscribeNotification = notificationService.onNotification((notification) => {
      setNotifications(prev => {
        const newNotifications = [notification, ...prev];
        return Array.from(
          new Map(newNotifications.map(item => [item.id, item])).values()
        );
      });
      setUnreadCount(prev => prev + 1);
    });

    // Handle connection status
    const unsubscribeConnection = notificationService.onConnectionChange((status) => {
      setIsConnected(status);
    });

    return () => {
      unsubscribeNotification();
      unsubscribeConnection();
    };
  }, [user?.id]);

  const markAsRead = useCallback(async (notificationId: string) => {
    // Implementation for marking notification as read
  }, []);

  return {
    notifications,
    isConnected,
    unreadCount,
    markAsRead
  };
};
```

### 3. Notification Component
```typescript
// src/components/NotificationList.tsx
import React from 'react';
import { View, FlatList, Text, StyleSheet } from 'react-native';
import { useNotifications } from '../hooks/useNotifications';

export const NotificationList = () => {
  const { notifications, isConnected } = useNotifications();

  const renderNotification = ({ item }) => (
    <View style={styles.notificationItem}>
      <Text style={styles.title}>{item.title}</Text>
      <Text style={styles.message}>{item.message}</Text>
    </View>
  );

  return (
    <View style={styles.container}>
      {!isConnected && (
        <View style={styles.offlineBanner}>
          <Text>Offline - Reconnecting...</Text>
        </View>
      )}
      <FlatList
        data={notifications}
        renderItem={renderNotification}
        keyExtractor={item => item.id}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  offlineBanner: {
    backgroundColor: '#ffebee',
    padding: 10,
    alignItems: 'center',
  },
  notificationItem: {
    padding: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  message: {
    fontSize: 14,
    marginTop: 5,
  },
});
```

## Background Processing

### Android Background Service
```typescript
// android/app/src/main/java/com/yourapp/NotificationService.java
public class NotificationService extends Service {
    private static final int NOTIFICATION_ID = 1;
    private static final String CHANNEL_ID = "NotificationService";

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        createNotificationChannel();
        startForeground(NOTIFICATION_ID, buildNotification());
        return START_STICKY;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Notification Service",
                NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
        }
    }

    private Notification buildNotification() {
        // Build and return notification
    }
}
```

### iOS Background Fetch
```swift
// ios/YourApp/AppDelegate.m
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Handle background fetch
    completionHandler(UIBackgroundFetchResultNewData);
}
```

## Push Notification Integration

### 1. Firebase Setup
```typescript
// src/services/PushNotificationService.ts
import messaging from '@react-native-firebase/messaging';

export class PushNotificationService {
  static async requestPermission() {
    const authStatus = await messaging().requestPermission();
    return authStatus === messaging.AuthorizationStatus.AUTHORIZED;
  }

  static async getFCMToken() {
    return await messaging().getToken();
  }

  static async registerDevice(userId: string, fcmToken: string) {
    // Register FCM token with your backend
  }
}
```

### 2. Notification Handling
```typescript
// App.tsx
import messaging from '@react-native-firebase/messaging';

messaging().setBackgroundMessageHandler(async remoteMessage => {
  // Handle background messages
});

function App() {
  useEffect(() => {
    const unsubscribe = messaging().onMessage(async remoteMessage => {
      // Handle foreground messages
    });

    return unsubscribe;
  }, []);

  return <AppContent />;
}
```

## Error Handling

### 1. Network Errors
```typescript
private async handleNetworkError() {
  const netInfo = await NetInfo.fetch();
  if (!netInfo.isConnected) {
    // Handle offline state
    return;
  }

  // Attempt reconnection
  await this.reconnect();
}
```

### 2. Token Expiration
```typescript
private async handleTokenExpiration() {
  try {
    // Refresh tokens
    const newTokens = await refreshTokens();
    await AsyncStorage.setItem('userToken', newTokens.userToken);
    await AsyncStorage.setItem('tenantToken', newTokens.tenantToken);
    
    // Reconnect with new tokens
    await this.reconnect();
  } catch (error) {
    // Handle refresh failure
  }
}
```

## Best Practices

1. **Battery Optimization**
   - Use WebSocket for real-time updates
   - Implement proper connection cleanup
   - Handle background state properly

2. **Data Management**
   - Cache notifications locally
   - Implement proper pagination
   - Handle offline state

3. **Error Handling**
   - Implement proper retry logic
   - Handle network changes
   - Provide user feedback

4. **Security**
   - Secure token storage
   - Implement proper authentication
   - Handle session expiration

## Testing

### 1. Connection Testing
```typescript
describe('MobileNotificationService', () => {
  it('should connect successfully', async () => {
    const service = MobileNotificationService.getInstance();
    await service.connect('testUser');
    expect(service.isConnected()).toBe(true);
  });
});
```

### 2. Notification Testing
```typescript
describe('Notification Handling', () => {
  it('should receive notifications', (done) => {
    const service = MobileNotificationService.getInstance();
    service.onNotification((notification) => {
      expect(notification).toBeDefined();
      done();
    });
  });
});
```

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Check network connectivity
   - Verify token validity
   - Check server status

2. **Battery Drain**
   - Review heartbeat interval
   - Check background processing
   - Optimize reconnection attempts

3. **Missing Notifications**
   - Verify socket connection
   - Check notification permissions
   - Review background settings 