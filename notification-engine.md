# Gabay Notification Engine

## Overview
The Gabay Notification Engine is a powerful and flexible system for sending and managing real-time notifications across the application. It ensures that users receive timely and relevant updates through a variety of display methods, whether they are online or offline.

For detailed technical implementation, architecture, and API reference, please see the [**Gabay Notification Engine - Technical Documentation**](./notification-engine-technical.md).

## Core Features

### 1. Real-time and Offline Delivery
- **WebSocket Integration**: Delivers instant notifications to online users.
- **Offline Queueing**: If a user is offline, notifications are queued and delivered the moment they reconnect.

### 2. Rich Notification Content
- **Display Types**:
    - **Modal**: A full-screen dialog for critical, must-see information.
    - **Banner**: A top-of-page banner for important announcements.
    - **Toast**: A small, non-intrusive pop-up for quick updates.
- **Priority Levels**: Tag notifications as High, Medium, or Low priority.
- **Interactive Actions**: Include buttons and links in notifications that can navigate users within the app or to external sites.
- **Banner Images**: Add visual context with banner images.

### 3. Advanced Targeting and Scheduling
- **Targeting Options**: Send notifications to all users, specific departments, colleges, or even down to individual users.
- **Scheduling**: Deliver notifications immediately or schedule them for a future date and time.
- **System Generated**: Automatically trigger notifications from system events (e.g., a new document submission).

## Common Use Cases

Below are examples of how the notification engine is used across the platform.

### 1. Administrative & Admissions
*   **New Application Submitted**: The admissions department receives a high-priority modal notification with a link to review a new student application.
*   **Document Submission**: A registrar is notified via a banner when a student submits a required document.
*   **Enrollment Status Change**: A student receives a success toast when their enrollment is confirmed.

```typescript
// Example Payload for a New Application
{
  title: "New Application Submitted",
  message: "New admission application submitted by John Doe for Grade 7",
  type: "ALERT",
  displayType: "MODAL",
  metadata: {
    importance: "HIGH",
    category: 'ADMISSION'
  },
  actions: [{
    label: "View Application",
    action: "LINK",
    url: "/applications/basic-education?id=some_application_id"
  }]
}
```

### 2. Academic Notifications
*   **Grades Posted**: Students in a specific course are notified via a toast when their grades are published.
*   **Class Canceled**: An entire department can be notified with a banner alert if a class is canceled.

```typescript
// Example Payload for Grade Posting
{
  title: "New Grades Posted",
  message: "Grades for your course 'Introduction to Science' are now available.",
  type: "ACADEMIC",
  displayType: "TOAST",
  metadata: {
    importance: "HIGH",
    category: 'GRADES'
  },
  actions: [{
    label: "View Grades",
    action: "LINK",
    url: "/grades/some_course_id"
  }]
}
```

### 3. System-Wide Notifications
*   **Scheduled Maintenance**: All users receive a banner notification in advance of scheduled system downtime.
*   **New Feature Announcement**: A modal with a banner image can be used to announce a major new feature to all users.

```typescript
// Example Payload for Scheduled Maintenance
{
  title: "Scheduled Maintenance",
  message: "The Gabay platform will be temporarily unavailable for scheduled maintenance on Sunday at 2:00 AM.",
  type: "SYSTEM",
  displayType: "BANNER",
  metadata: {
    importance: "HIGH",
    category: 'SYSTEM'
  },
  schedule: {
    sendAt: "2024-12-25T02:00:00.000Z"
  }
}
```

## Best Practices

1.  **Use Priority Wisely**: Reserve `HIGH` priority and `MODAL` displays for truly critical information to avoid user fatigue.
2.  **Be Clear and Concise**: Write notification titles and messages that are easy to understand at a glance.
3.  **Provide Actionable Links**: Whenever possible, include a direct link in the `actions` array to guide the user to the relevant page.
