# Connecting Expo React Native Application to Notification Engine

## Overview
This guide explains how to integrate your Expo-based React Native application with our WebSocket-based notification engine. The notification engine provides real-time notifications to your app using Socket.IO.

## Prerequisites
- Expo CLI
- Node.js (version 14 or higher)
- Valid tenant token and user credentials
- Expo project initialized

## Dependencies

Install the required dependencies in your Expo project:

```bash
expo install socket.io-client
expo install @react-native-async-storage/async-storage
expo install expo-notifications
```

## Connection Setup

### 1. Initialize Socket.IO Client

Create a new file `services/NotificationService.js`:

```javascript
import io from 'socket.io-client';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';

class NotificationService {
    constructor() {
        this.socket = null;
        this.setupNotifications();
    }

    async setupNotifications() {
        // Request notification permissions
        const { status } = await Notifications.requestPermissionsAsync();
        if (status !== 'granted') {
            console.log('Notification permissions not granted');
            return;
        }

        // Configure notification behavior
        Notifications.setNotificationHandler({
            handleNotification: async () => ({
                shouldShowAlert: true,
                shouldPlaySound: true,
                shouldSetBadge: true,
            }),
        });
    }

    initializeSocket(tenantToken, userId) {
        try {
            const options = {
                auth: {
                    tenantToken,
                    userId,
                },
                reconnection: true,
                reconnectionDelay: 1000,
                reconnectionDelayMax: 5000,
                timeout: 20000,
            };

            this.socket = io('YOUR_NOTIFICATION_SERVER_URL', options);
            this.setupSocketListeners();
            return true;
        } catch (error) {
            console.error('Error initializing socket:', error);
            return false;
        }
    }

    setupSocketListeners() {
        if (!this.socket) return;

        this.socket.on('connect', () => {
            console.log('Socket connected');
        });

        this.socket.on('disconnect', () => {
            console.log('Socket disconnected');
        });

        this.socket.on('connect_error', (error) => {
            console.error('Connection error:', error);
        });

        this.socket.on('notification', this.handleNotification);
    }

    async handleNotification(notificationData) {
        try {
            const { title, message, type, displayType, priority, category } = notificationData;

            switch (displayType) {
                case 'NOTIFICATION':
                    await Notifications.scheduleNotificationAsync({
                        content: {
                            title,
                            body: message,
                            data: { type, priority, category },
                        },
                        trigger: null, // Show immediately
                    });
                    break;

                case 'ALERT':
                    // Handle in-app alerts using your preferred UI library
                    // Example: Alert.alert(title, message);
                    break;

                case 'TOAST':
                    // Handle in-app toasts using your preferred UI library
                    // Example: Toast.show(message);
                    break;
            }
        } catch (error) {
            console.error('Error handling notification:', error);
        }
    }

    disconnect() {
        if (this.socket) {
            this.socket.disconnect();
            this.socket = null;
        }
    }
}

export default new NotificationService();
```

### 2. Usage in Your App

In your `App.js` or main component:

```javascript
import React, { useEffect } from 'react';
import { View } from 'react-native';
import NotificationService from './services/NotificationService';

export default function App() {
    useEffect(() => {
        // Initialize notification service after user authentication
        const initializeNotifications = async () => {
            const tenantToken = 'YOUR_TENANT_TOKEN';
            const userId = 'USER_ID';
            
            NotificationService.initializeSocket(tenantToken, userId);
        };

        initializeNotifications();

        // Cleanup on component unmount
        return () => {
            NotificationService.disconnect();
        };
    }, []);

    return (
        <View>
            {/* Your app content */}
        </View>
    );
}
```

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| reconnection | Enable auto-reconnection | true |
| reconnectionDelay | Initial delay between reconnection attempts | 1000ms |
| reconnectionDelayMax | Maximum delay between reconnection attempts | 5000ms |
| timeout | Connection timeout | 20000ms |

## Notification Types

The notification engine supports different types of notifications:

- `TOAST`: In-app toast messages
- `ALERT`: In-app modal alerts
- `NOTIFICATION`: System notifications using Expo Notifications

## Security Considerations

1. Store tenant tokens securely using AsyncStorage with encryption.
2. Implement proper token refresh mechanisms.
3. Handle connection errors and implement appropriate retry strategies.
4. Clean up socket connections when the app is closed or backgrounded.

## Best Practices

1. **Connection Management**
   - Connect to the notification server after user authentication
   - Implement proper reconnection logic
   - Handle network changes appropriately

2. **Resource Management**
   - Disconnect socket when the app goes to background
   - Reconnect when the app comes to foreground
   - Clean up resources when the app is closed

3. **Battery Optimization**
   - Use appropriate reconnection delays
   - Handle background notifications efficiently
   - Implement proper cleanup in background state

## Troubleshooting

Common issues and solutions:

1. **Connection Failures**
   - Verify tenant token and user ID
   - Check network connectivity
   - Verify server URL and port

2. **Missing Notifications**
   - Check notification permissions
   - Verify socket connection status
   - Check for any network restrictions

3. **Background Notification Issues**
   - Ensure proper Expo notification configuration
   - Verify background notification permissions
   - Check notification payload format

## API Reference

### Socket Events

| Event | Description |
|-------|-------------|
| connect | Fired upon successful connection |
| disconnect | Fired when socket disconnects |
| notification | Received when a new notification arrives |
| connect_error | Fired when connection fails |

### Notification Object Structure

```json
{
    "id": "notification_id",
    "message": "Notification message",
    "type": "INFO|WARNING|ERROR",
    "displayType": "TOAST|ALERT|NOTIFICATION",
    "priority": "LOW|MEDIUM|HIGH",
    "category": "GENERAL|SYSTEM|CUSTOM",
    "title": "Notification title",
    "createdAt": "2024-01-01T00:00:00Z"
}
```

## Additional Expo Configuration

### 1. Update app.json

Add the following to your `app.json`:

```json
{
  "expo": {
    "plugins": [
      [
        "expo-notifications",
        {
          "icon": "./assets/notification-icon.png",
          "color": "#ffffff",
          "sounds": ["./assets/notification-sound.wav"]
        }
      ]
    ]
  }
}
```

### 2. Background Notifications

To handle notifications when the app is in the background, add this to your `App.js`:

```javascript
import * as Notifications from 'expo-notifications';

Notifications.addNotificationResponseReceivedListener((response) => {
    // Handle notification interaction when app is in background
    const data = response.notification.request.content.data;
    // Navigate or perform actions based on notification data
});
```

## Support

For additional support or questions, please contact our support team or refer to the API documentation. 