//
//  websocketViewModel.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import PhotosUI
import Starscream
import CoreData

final class WebsocketViewModel: ObservableObject {
    
    @AppStorage("userID") private var userID = ""
    @Published var user: User = User(userName: UUID().uuidString)
    
    @Published var chatMessage: [WSChatMessage] = []
    @Published var newMessage: String = ""
    @Published var messageReceived = ""
    
    @Published var isSockedConnected: Bool = false
    @Published var isAnotherUserTapping: Bool = false
    
    private var hasReceivedPong: Bool = false
    private var isFirstPing: Bool = true
    
    private var timer: Timer?
    private var socket: WebSocket?
    
    init() {
        self.chatMessage = getAllMessages()
        initWebSocket()
        startHeartBeatController()
        setupUserInfo()
    }
    
    deinit {
        socket?.disconnect(closeCode: 0)
    }
    
    private func setupUserInfo() {
        if userID.isEmpty {
            self.userID = UUID().uuidString
            self.user = User(userName: userID)
        } else {
            user = User(userName: self.userID)
        }
    }
    
    private func initWebSocket() {
        var request = URLRequest(url: URL(string: "\(APIKeys.websocketAddress.rawValue)/chatWS")!)
        request.setValue("chat", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        // socket?.callbackQueue = DispatchQueue(label: "com.vluxe.starscream.myapp")
        socket?.delegate = self
        socket?.connect()
    }

    func sendStatusMessage(type: StatusMessageType) {
        let statusMessage = StatusMessage(userID: user.userName, type: type)
        
        guard let payload = try? statusMessage.encode() else {
            print("Error on get payload from aliveMessage \(statusMessage)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(messageType: .Status, subMessageTypeCode: type.code, payload: payload)
        
        guard let wsMessage = try? wsMessageCodable.encode() else {
            print("Error on encode WSMessage: \(wsMessageCodable)")
            return
        }
        
        if type == .Disconnect {
            timer?.invalidate()
        } else {
            if timer?.isValid == true {
                startHeartBeatController()
            }
        }
        
        socket?.write(string: wsMessage, completion: {
           print("\(type) message was sent")
        })
    }
    

    func sendTypingStatus(isTyping: Bool) {
        let typingMessage = TypingMessage(userID: user.userName, isTyping: isTyping)
        
        guard let payload = try? typingMessage.encode() else {
            print("Error on get payload from aliveMessage \(typingMessage)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(messageType: .Chat, subMessageTypeCode: ChatMessageType.TypingStatus.code, payload: payload)

        guard let wsMessage = try? wsMessageCodable.encode() else {
            print("Error on encode WSMessage: \(wsMessageCodable)")
            return
        }
        
        socket?.write(string: wsMessage, completion: {
            print("Typing message was sent")
        })
    }
    
    func sendRecation(message: WSChatMessage, reaction: WSReaction) {
        let reactionMessage = ReactionMessage(userID: user.userName, messageID: UUID().uuidString, messageReacted: message, reactionIcon: reaction)
        
        guard let payload = try? reactionMessage.encode() else {
            print("Error on get payload from reationMessage \(reaction)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(messageType: .Chat, subMessageTypeCode: ChatMessageType.Reaction.code, payload: payload)

        
        guard let wsMessage = try? wsMessageCodable.encode() else {
            print("Error on encode WSMessage: \(wsMessageCodable)")
            return
        }
        
        socket?.write(string: wsMessage, completion: {
            self.setupReaction(to: message, reaction: reaction)
            print("Reaction message was sent")
        })
        
    }
    
    func sendContentString(message: String) {
        let messageContent = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let timestamp = Date.now
        
        let wsMessage = WSChatMessage(
            messageID: UUID().uuidString,
            senderID: user.userName,
            timestamp: timestamp,
            content: messageContent,
            isSendByUser: true, reactions: [])
                
        guard let payload = try? wsMessage.encode() else {
            print("Error on get payload from aliveMessage \(wsMessage)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(messageType: .Chat, subMessageTypeCode: ChatMessageType.ContentString.code, payload: payload)

        guard let wsMessageEncoded = try? wsMessageCodable.encode() else {
            print("Error on encode WSMessage: \(wsMessageCodable)")
            return
        }
                
        socket?.write(string: wsMessageEncoded, completion: {
            DispatchQueue.main.async {
                withAnimation {
                    self.chatMessage.append(wsMessage)
                    self.saveMessage(wsMessage)
                }
                self.newMessage = ""
            }
        })
    }
    
    func sendButtonDidTapped() {
        let newMessageToSend = newMessage.trimmingCharacters(in: .whitespaces)
        if !newMessageToSend.isEmpty {
            sendContentString(message: newMessageToSend)
        }
    }
}

extension WebsocketViewModel: WebSocketDelegate {
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        
        switch event {
        case .connected(let headers):
            connectionConfirmMessage(headers: headers)
        case .disconnected(let reason, let code):
            self.handlerDisconnectionsMessage(reason: reason, code: code)
        case .text(let message):
            handlerWebsocketMessage(message: message)
        case .binary(let data):
            handlerWebsocketMessage(message: data)
        case .ping(_):
            print("Received ping")
        case .pong(let pong):
            self.handlerPongMessage(data: pong)
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            handlerCancelConectionMessage()
        case .error(let error):
            handlerErrorMessage(error: error)
        case .peerClosed:
            break
        }
    }
    
}

extension WebsocketViewModel {
    private func startHeartBeatController() {
        timer =  Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            if self.isFirstPing {
                self.socket?.write(ping: Data())
                print("Sending ping on start connection")
                withAnimation {
                    self.hasReceivedPong = false
                }
                self.isFirstPing = false
            } else if self.hasReceivedPong  {
                self.socket?.write(ping: Data())
                withAnimation {
                    self.hasReceivedPong = false
                }
                print("Sending ping")
            } else if !self.isSockedConnected {
                self.initWebSocket()
                print("Websocket is disconnected, trying connection")
            } else {
                self.socket?.write(ping: Data())
                withAnimation {
                    self.hasReceivedPong = false
                }
                print("Sending ping after reestablishing connection")
            }
        }
    }
}

extension WebsocketViewModel {
    private func handlerWebsocketMessage(message: String) {
        
        do {
            let wsMessage: WSMessageHeader = try message.decodeWSEncodable(type: WSMessageHeader.self)
            
            switch wsMessage.messageType {
                
            case .Chat:
                guard let chatMessageType: ChatMessageType = ChatMessageType(rawValue: wsMessage.subMessageTypeCode) else {
                    print("Invalid chatMessageType code: \(wsMessage.subMessageTypeCode)")
                    return
                }
                
                handleChatMessageReceived(type: chatMessageType, payload: wsMessage.payload)
                
            case .Status:
                
                guard let statusMessageType: StatusMessageType = StatusMessageType(rawValue: wsMessage.subMessageTypeCode) else {
                    print("Invalid statusMessageType code: \(wsMessage.subMessageTypeCode)")
                    return
                }
                
                handleStatusMessagReceivede(type: statusMessageType, payload: wsMessage.payload)
            }
        } catch {
            
        }

    }
    
    private func handleChatMessageReceived(type: ChatMessageType, payload: String) {
        switch type {
        case .ContentString:
            handleChatContentString(payload: payload)
        case .ContentData:
            print("binary")
        case .Reaction:
            handleChatReactionMessage(payload: payload)
        case .Reply:
            print("Reply")
        case .TypingStatus:
            handlerTypingStatus(payload: payload)
        }
    }
    
    
    
    private func handleStatusMessagReceivede(type: StatusMessageType, payload: String) {
        do {
            let statusMessage: StatusMessage = try payload.decodeWSEncodable(type: StatusMessage.self)
            switch type {
            case .Alive:
                print("Received alive Message: \(statusMessage)")
            case .Disconnect:
                print("Received disconnected Message: \(statusMessage)")
            }
        } catch {
            print("Error on \(#function): \(error.localizedDescription)")
        }
    }
    
    private func handleChatContentString(payload: String) {
        do {
            var wsChatMessage: WSChatMessage = try payload.decodeWSEncodable(type: WSChatMessage.self)
            wsChatMessage.isSendByUser = false
            
            let isForwardedMessage: Bool = self.chatMessage.filter { message in
                message.messageID == wsChatMessage.messageID && message.timestamp == wsChatMessage.timestamp
            }.count >= 1
            
            guard  !isForwardedMessage else {
                print("Messagem reeviada pelo servidor")
                return
            }
            self.chatMessage.append(wsChatMessage)
            self.saveMessage(wsChatMessage)
            
        } catch {
            print("Error on decode data: \(payload)")
        }
    }
    
    private func handleChatReactionMessage(payload: String) {
        do {
            var reactionMessage = try payload.decodeWSEncodable(type: ReactionMessage.self)
            
            setupReaction(to: reactionMessage.messageReacted, reaction: reactionMessage.reactionIcon)
            
        } catch {
            print("Error on decode reaction message")
        }
    }
    
    private func setupReaction(to message: WSChatMessage, reaction: WSReaction) {
        
        guard let messageIndex = chatMessage.firstIndex(where: { $0.messageID == message.messageID }) else {
            print("Message not found in chat")
            return
        }
        
        withAnimation {
            DispatchQueue.main.async {
                self.chatMessage[messageIndex].reactions.append(reaction)
                self.updateAddReaction(messageID: self.chatMessage[messageIndex].messageID, reaction: reaction)
            }
        }
        
    }
    
    private func handlerTypingStatus(payload: String) {
        
        do {
            let typingMessage: TypingMessage = try payload.decodeWSEncodable(type: TypingMessage.self)
            let wsMessageCodable = WSMessageHeader(messageType: .Chat, subMessageTypeCode: ChatMessageType.TypingStatus.code, payload: payload)
            
            isAnotherUserTapping = typingMessage.isTyping
        } catch {
            print("Error on \(#function): \(error.localizedDescription)")
        }
    }
    
    private func handlerStatusMessage(type: StatusMessageType) {
        switch type {
        case .Alive:
            print("")
        case .Disconnect:
            print("print")
        }
    }
    
    private func handlerPongMessage(data: Data?) {
        withAnimation {
            hasReceivedPong = true
        }
        print("Received pong")
    }
    
    private func connectionConfirmMessage(headers: [String: String]) {
        self.isSockedConnected = true
        sendStatusMessage(type: .Alive)
        print("websocket is connected: \(headers)")
    }
    
    private func handlerDisconnectionsMessage(reason: String, code: UInt16) {
        self.isSockedConnected = false
        print("websocket is disconnected: \(reason) with code: \(code)")
    }
    
    private func handlerWebsocketMessage(message: Data) {
        print("Received binary message: \(message)")
    }
    
    private func handlerErrorMessage(error: Error?) {
        isSockedConnected = false
        print("Error: \(String(describing: error?.localizedDescription))")
    }
    
    private func handlerCancelConectionMessage() {
        isSockedConnected = false
        print("Websocket canceled connection to app")
    }
}

extension  WebsocketViewModel {
    
    func getAllMessages() -> [WSChatMessage] {
        let result: [WSChatMessage] = getAllStorageMessages().compactMap {$0.toWSMessage()}
        return result
    }
    
    private func getAllStorageMessages() -> [ChatMessage] {

        let request = ChatMessage.fetchRequest()
        var fetchedMessages: [ChatMessage] = []
        
        do {
            fetchedMessages = try PersistenceController.shared.viewContext.fetch(request)
        } catch let error {
            print("Error while fetching messages: \(error)")
        }
        return fetchedMessages
    }
    
    func saveMessage(_ wsMessage: WSChatMessage) {
        
        let context = PersistenceController.shared.viewContext
        let message = ChatMessage(context: context)
        
        message.id = wsMessage.messageID
        message.senderID = wsMessage.senderID
        message.timestamp = wsMessage.timestamp
        message.content = wsMessage.content
        message.isSendByUser =  wsMessage.isSendByUser
        
        wsMessage.reactions.forEach { reaction in
            let messageReaction = Reaction(context: context)
            messageReaction.count = Int16(reaction.count)
            messageReaction.emoji = reaction.emoji
        }
        
        PersistenceController.shared.save()
    }
    
    func updateAddReaction(messageID: String, reaction: WSReaction) {
        
        let context = PersistenceController.shared.viewContext
                
        let tempObj = getAllStorageMessages().first { message in
            message.id == messageID
        }
        guard let objectToUp = tempObj else {
            return
        }
        
        context.perform {
            do {
                let objectToUpdate = try context.existingObject(with: objectToUp.objectID)
                
                guard let chatMessageEntity = objectToUpdate as? ChatMessage else {
                    print("Error on parse entity")
                    return
                }
                
                let reactionToSave = Reaction(context: context)
                reactionToSave.count = Int16(reaction.count)
                reactionToSave.emoji = reaction.emoji
                chatMessageEntity.addToMessageReactions(reactionToSave)
                
                try context.save()
                
            } catch {
                print("Error on \(#function): \(error.localizedDescription)")
            }
        }
        
    }
    
    func isNextMessageFromUser(message: WSChatMessage) -> Bool {
        if let currentIndex = chatMessage.firstIndex(where: { $0.messageID == message.messageID }) {
            if currentIndex < chatMessage.count - 1 {
                let nextMessage = chatMessage[currentIndex + 1]
                
                if nextMessage.senderID == message.senderID {
                    return true
                }
            }
        }

        return false
    }
    
    func isFirstMessage(_ message: WSChatMessage) -> Bool {
        return  chatMessage.first == message
    }

    
}
