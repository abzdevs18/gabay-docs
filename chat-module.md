# Chat Module Documentation

## 1. Overview

The Gabay chat module is a real-time messaging system designed to facilitate communication between users within the platform. It supports direct messaging, group chats, file attachments, typing indicators, and user presence. The system is built with a modern technology stack, featuring a Node.js backend with Socket.IO and a React-based frontend using Next.js.

## 2. Architecture

The chat system follows a client-server architecture.

*   **Backend**: A Node.js server that handles WebSocket connections, authentication, business logic, and database interactions.
*   **Frontend**: A React application that provides the user interface for chatting, manages client-side state, and communicates with the backend server.
*   **Database**: A relational database (managed by Prisma) to store chat data, including rooms, messages, and user information.
*   **Real-time Communication**: Socket.IO is used for real-time, bidirectional communication between the client and server.

### Technology Stack

*   **Backend**: Node.js, Express, Socket.IO, Prisma, Bull (for message queues), Redis.
*   **Frontend**: React, Next.js, Socket.IO Client, Axios, React Context API.
*   **Database**: PostgreSQL (or any other Prisma-supported database).

## 3. Backend Components

The backend is responsible for the core functionality of the chat system.

### 3.1. Server Setup (`api/chat-server.js`)

*   **Purpose**: Initializes the Express server and integrates the Socket.IO server.
*   **Key Responsibilities**:
    *   Sets up an HTTP server.
    *   Attaches Socket.IO to the server.
    *   Handles CORS (Cross-Origin Resource Sharing).
    *   Implements Socket.IO middleware for authentication. It verifies the user's JWT token before establishing a connection.
    *   Initializes and injects the `ChatService` to handle chat-related events.

### 3.2. Core Logic (`api/src/services/chat.service.ts`)

*   **Purpose**: Contains the main business logic for the chat system.
*   **Key Responsibilities**:
    *   **Connection Management**: Handles user connections and disconnections.
    *   **Room Management**: Manages joining and leaving chat rooms.
    *   **Direct Chat**: Creates or finds existing direct chat rooms between two users.
    *   **Message Handling**:
        *   Receives new messages from clients.
        *   Validates user permissions.
        *   Saves messages to the database using Prisma.
        *   Broadcasts new messages to the appropriate room members.
    *   **Typing Indicators**: Manages and broadcasts typing status updates.
    *   **User Presence**: Tracks and updates user online/offline status.
    *   **File Uploads**: Handles file attachments, likely interacting with a file storage service (e.g., AWS S3).

### 3.3. Database Models (`api/prisma/schema/schema.prisma`)

*   **Purpose**: Defines the database schema for the chat module.
*   **Key Models**:
    *   `ChatRoom`: Represents a chat room, which can be a direct message or a group chat.
        *   `id`, `name`, `type` (`DIRECT`, `GROUP`), `createdAt`, `updatedAt`.
    *   `ChatRoomMembership`: Links users to chat rooms.
        *   `id`, `userId`, `roomId`, `role` (`ADMIN`, `MEMBER`), `createdAt`.
    *   `Message`: Represents a single message in a chat room.
        *   `id`, `content`, `roomId`, `authorId`, `type` (`TEXT`, `IMAGE`, etc.), `createdAt`.
    *   `MessageAttachment`: Stores information about message attachments.
    *   `MessageRead`: Tracks when a user has read a message (for read receipts).
    *   `MessageReaction`: Stores message reactions.
    *   `MessageMention`: Manages user mentions in messages.

## 4. Frontend Components

The frontend provides the user interface and manages the client-side logic.

### 4.1. API Service (`frontend/src/modules/chat/services/chatService.ts`)

*   **Purpose**: A singleton service that encapsulates all communication with the backend chat server.
*   **Key Responsibilities**:
    *   **Socket.IO Connection**: Manages the Socket.IO client connection, including connection, disconnection, and authentication.
    *   **Event Emission**: Provides methods to send events to the server (e.g., `sendMessage`, `joinRoom`, `sendTypingIndicator`).
    *   **Event Listening**: Sets up listeners for server-sent events (e.g., `chat:message`, `chat:room_created`).
    *   **API Requests**: Uses Axios to make HTTP requests for actions like file uploads.

### 4.2. State Management (`frontend/src/modules/chat/context/ChatContext.tsx`)

*   **Purpose**: Manages the global state for the chat feature using React's Context API and a `useReducer` hook.
*   **Key Responsibilities**:
    *   **State**: Holds the chat state, including the active room, list of rooms, users, messages, loading status, and errors.
    *   **Initialization**:
        *   Initializes the `ChatService`.
        *   Connects to the chat server upon user authentication.
        *   Fetches initial chat data (`chat:get_init_data`).
    *   **Event Handling**: Listens for events from the `ChatService` and updates the state accordingly (e.g., adding a new message to the state when a `chat:message` event is received).
    *   **Actions**: Provides functions that components can call to interact with the chat system (e.g., `sendMessage`, `setActiveRoom`).

### 4.3. Main UI (`frontend/src/shad-components/shad/components/registrar/components/ChatComponent.tsx`)

*   **Purpose**: The main container component for the chat interface.
*   **Key Responsibilities**:
    *   Renders the overall chat layout, including the room list, message display area, and message input.
    *   Uses the `ChatContext` to access chat data and actions.
    *   Displays the list of chat rooms and allows the user to switch between them.
    *   Renders the messages for the currently active room.

### 4.4. Message Input (`frontend/src/shad-components/shad/components/registrar/components/chat/MessageInput.tsx`)

*   **Purpose**: A component for composing and sending messages.
*   **Key Responsibilities**:
    *   Provides a text input for typing messages.
    *   Handles sending messages when the user presses "Enter" or clicks a send button.
    *   Integrates with file uploads, emoji pickers, and other message composition features.
    *   Calls the `sendMessage` function from the `ChatContext` to send the message.
    *   Sends typing indicator events to the server.

## 5. End-to-End Flow: Sending a Message

1.  **User Action**: The user types a message in the `MessageInput` component and hits "Send".
2.  **Frontend (Component)**: The `MessageInput` component calls the `sendMessage` function from the `ChatContext`.
3.  **Frontend (Context)**: The `ChatContext` calls the `sendMessage` method on the `chatService` instance.
4.  **Frontend (Service)**: The `chatService` emits a `chat:message` event to the backend Socket.IO server with the message payload.
5.  **Backend (Server)**: The Socket.IO server receives the `chat:message` event.
6.  **Backend (Service)**: The `ChatService` on the backend handles the event.
    *   It verifies that the user is a member of the room.
    *   It saves the message to the database using Prisma.
    *   It broadcasts a `chat:message` event to all other members of the same room.
7.  **Frontend (Service)**: The `chatService` on each client in the room receives the broadcasted `chat:message` event.
8.  **Frontend (Context)**: The `ChatContext`'s event listener for `chat:message` is triggered. It dispatches an action to update the state, adding the new message to the message list for the corresponding room.
9.  **Frontend (UI)**: The `ChatComponent` re-renders due to the state change, and the new message appears in the message display area for all users in the room.

## 6. Key Features

*   Real-time messaging
*   Direct (1-on-1) and group chats
*   File attachments
*   Typing indicators
*   User presence (online/offline status)
*   Read receipts (optional, based on schema)
*   Message reactions (optional, based on schema)
*   User mentions (optional, based on schema)
*   Authentication via JWT

## 7. Setup and Configuration

### Backend

1.  **Environment Variables**: Configure the `.env` file with database credentials, JWT secret, and other necessary settings.
2.  **Database Migration**: Run `npx prisma migrate dev` to apply the database schema.
3.  **Start Server**: Run `npm run dev` (or the appropriate start script) in the `api` directory to start the backend server.

### Frontend

1.  **Environment Variables**: Configure any necessary environment variables, such as the backend API URL.
2.  **Install Dependencies**: Run `npm install` in the `frontend` directory.
3.  **Start Application**: Run `npm run dev` in the `frontend` directory to start the Next.js development server.