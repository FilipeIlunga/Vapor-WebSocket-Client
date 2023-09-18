# Real-Time Chat Built with Vapor and SwiftUI, using Websocket

# Introduction:
This project is an in-depth study of how websockets work and the creation of a chat system using WebSockets in conjunction with the Vapor framework on the server. The main goal is to provide a robust and reliable real-time chat experience, equipped with features that meet the needs of modern communication. Feel free to report issues, suggest improvements, or implement a chat system in your own app based on this repository. The project is open to collaboration and external contributions.

The server's codebase can be found in this repository: [Server repository](https://github.com/FilipeIlunga/Vapor-WebSocket-Server).

# Key Features:

## 1 - Message Persistence with CoreData
While the server acts as an efficient intermediary in the exchange of messages, the messages are not stored permanently on the server side. Instead, the messages are stored locally on the user's device using CoreData. This ensures that conversations are preserved even if the user is offline or if the server is unavailable.

## 2 - Communication Channel Persistence
Communication channel persistence ensures that users don't miss any important messages. If a user is offline, messages sent to them will be re-sent when they reconnect. This includes individual messages, message reactions, and other interactions.

## 3 - Heartbeat Protocol
The heartbeat protocol is used to check if the server is responding. If the server fails to respond within a time interval, the client will automatically attempt a new connection, ensuring an uninterrupted connection.

## 4 - Typing Indicators
Typing indicators allow users to see when someone is typing a message. This lets other users know that the person is interacting with the conversation and that a response may be on the way.

## 5 - Message Reactions:
Users can react to individual messages or to multiple messages in the chat. Reactions are displayed as icons below the message.



