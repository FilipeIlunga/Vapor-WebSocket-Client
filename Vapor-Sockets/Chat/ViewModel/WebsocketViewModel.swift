//
//  websocketViewModel.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import Starscream
import CoreData
import _PhotosUI_SwiftUI

struct SendableImage: Transferable {
    let image: Image
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
        #if canImport(AppKit)
            guard let nsImage = NSImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(nsImage: nsImage)
            return ProfileImage(image: image)
        #elseif canImport(UIKit)
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(uiImage: uiImage)
            return SendableImage(image: image)
        #else
            throw TransferError.importFailed
        #endif
        }
    }
}

enum ImageState {
    case empty
    case loading(Progress)
    case success(Image)
    case failure(Error)
}

enum TransferError: Error {
    case importFailed
}

final class WebsocketViewModel: ObservableObject {
    
    var pack: [Packet] = []
    
    @AppStorage("userID") private var userID = ""
    @Published var user: User = User(userName: UUID().uuidString)
    
    @Published var image: UIImage?
    
    @Published var chatMessage: [WSChatMessage] = []
    @Published var newMessage: String = ""
    
    @Published var imageToSend: UIImage?
    
    @Published private(set) var imageState: ImageState = .empty

    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }
    
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
        disconnectSocket()
    }
    
     func disconnectSocket() {
         sendStatusMessage(type: .Disconnect)
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
    
     func initWebSocket() {
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
        
        guard let payload = try? WSCoder.shared.encode(data: statusMessage) else {
            print("Error on get payload from aliveMessage \(statusMessage)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(fromUserID: user.userName, messageType: .Status, subMessageTypeCode: type.code, payload: payload)
        
        guard let wsMessage = try? WSCoder.shared.encode(data: wsMessageCodable) else {
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
        
        guard let payload = try?  WSCoder.shared.encode(data: typingMessage) else {
            print("Error on get payload from aliveMessage \(typingMessage)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(fromUserID: user.userName, messageType: .Chat, subMessageTypeCode: ChatMessageType.TypingStatus.code, payload: payload)

        guard let wsMessage = try? WSCoder.shared.encode(data: wsMessageCodable) else {
            print("Error on encode WSMessage: \(wsMessageCodable)")
            return
        }
        
        socket?.write(string: wsMessage, completion: {
            print("Typing message was sent")
        })
    }
    
    func sendRecation(message: WSChatMessage, reaction: WSReaction) {
        let reactionMessage = ReactionMessage(userID: user.userName, messageID: UUID().uuidString, messageReacted: message, reactionIcon: reaction)
        
        guard let payload = try? WSCoder.shared.encode(data: reactionMessage) else {
            print("Error on get payload from reationMessage \(reaction)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(fromUserID: user.userName, messageType: .Chat, subMessageTypeCode: ChatMessageType.Reaction.code, payload: payload)

        
        guard let wsMessage = try? WSCoder.shared.encode(data: wsMessageCodable) else {
            print("Error on encode WSMessage: \(wsMessageCodable)")
            return
        }
        
        socket?.write(string: wsMessage, completion: {
            self.setupReaction(to: message, reaction: reaction)
            print("Reaction message was sent")
        })
        
    }
    
    func sendDeleteMessage(messageID: String) {
        let wsDeleteMessage = WSDeleteMessage(id: UUID().uuidString, messageTodeleteID: messageID)
        
        guard let payload = try? WSCoder.shared.encode(data: wsDeleteMessage) else {
            print("Error on get payload from aliveMessage \(wsDeleteMessage)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(fromUserID: user.userName, messageType: .Chat, subMessageTypeCode: ChatMessageType.DeleteMessage.code, payload: payload)
        
        guard let wsMessageEncoded = try? WSCoder.shared.encode(data: wsMessageCodable) else {
            print("Error on encode WSMessage: \(wsMessageCodable)")
            return
        }
        
        socket?.write(string: wsMessageEncoded, completion: {
            DispatchQueue.main.async {
                withAnimation {
                    self.deleteMessage(messageID: messageID)
                }
            }
        })
    }
    
    func sendContentString(message: String) {
        let messageContent = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let timestamp = Date.now
        let messageID = UUID().uuidString
        let wsMessage = WSChatMessage(
            messageID: messageID, imageDate: nil,
            senderID: user.userName,
            timestamp: timestamp,
            content: messageContent,
            isSendByUser: true, reactions: [])
        
        sendImage(messageID: messageID)

        guard let payload = try? WSCoder.shared.encode(data: wsMessage) else {
            print("Error on get payload from aliveMessage \(wsMessage)")
            return
        }
        
        let wsMessageCodable = WSMessageHeader(fromUserID: user.userName, messageType: .Chat, subMessageTypeCode: ChatMessageType.ContentString.code, payload: payload)

        guard let wsMessageEncoded = try? WSCoder.shared.encode(data: wsMessageCodable) else {
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

    func sendImage(messageID: String) {
        
        imageSelection?.loadTransferable(type: Data.self, completionHandler: { result in
            switch result {
            case .success(let imageData):
                guard let imageData = imageData else {
                    print("Error on \(#function): Erron on get image data")
                    return
                }
                self.encodeAndSendImageData(imageData: imageData, messageID: messageID)
            case .failure(let error):
                print("Error on \(#function): \(error.localizedDescription)")
            }
        })
        
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: SendableImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let sendableImage?):
                    self.imageState = .success(sendableImage.image)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    func encodeAndSendImageData(imageData: Data, messageID: String) {
        let chunkSize = 1024
        let totalSize = imageData.count
        let restSize = totalSize % chunkSize

        // Divida a imagem em pacotes
        var offset = 0
        while offset < totalSize {
            let chunkRange = offset..<(offset + min(chunkSize, totalSize - offset))
            let chunkData = imageData.subdata(in: chunkRange)

            // Verifica se é o último pacote
            let isLast = offset + chunkData.count >= totalSize && restSize == 0

            // Cria um novo pacote
            let packet = Packet(userID: self.userID, messageID: messageID, totalSize: totalSize, currentSize: offset, isLast: isLast, data: [UInt8](chunkData))

            do {
                // Encodifica o pacote
                let bytes = try BinaryEncoder.encode(packet)

                // Envia o pacote
                self.socket?.write(data: Data(bytes), completion: {
                    print("Sent package")
                })

                offset += chunkData.count
            } catch {
                print("Error on send packet: \(error.localizedDescription)")
                break
            }
        }

        if restSize > 0 {
            let restChunkRange = (offset - restSize)..<imageData.count
            let restChunkData = imageData.subdata(in: restChunkRange)

            let packet = Packet(userID: self.userID, messageID: messageID, totalSize: totalSize, currentSize: offset, isLast: true, data: [UInt8](restChunkData))

            do {
                let bytes = try BinaryEncoder.encode(packet)

                self.socket?.write(data: Data(bytes), completion: {
                    print("Sent last package")
                })
            } catch {
                print("Error on send packet: \(error.localizedDescription)")
            }
        }
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
            let wsMessage: WSMessageHeader = try  WSCoder.shared.decode(type: WSMessageHeader.self, from: message)
            
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
        case .DeleteMessage:
            handleDeleteMessageReceived(payload: payload)
        }
    }
    
    
    
    private func handleStatusMessagReceivede(type: StatusMessageType, payload: String) {
        do {
            let statusMessage: StatusMessage = try WSCoder.shared.decode(type: StatusMessage.self, from: payload)
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
    
    private func handleDeleteMessageReceived(payload: String) {
        do {
            var wsDeleteMessage: WSDeleteMessage = try WSCoder.shared.decode(type: WSDeleteMessage.self, from: payload)
            deleteMessage(messageID: wsDeleteMessage.messageTodeleteID)
        } catch {
            print("Error on \(#function): \(error)")
        }
    }
    
   
    private func handleChatContentString(payload: String) {
        do {
            var wsChatMessage: WSChatMessage = try WSCoder.shared.decode(type: WSChatMessage.self, from: payload)
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
            let reactionMessage = try WSCoder.shared.decode(type: ReactionMessage.self, from: payload)
           
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
            let typingMessage: TypingMessage = try WSCoder.shared.decode(type: TypingMessage.self, from: payload)
            
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
        do {
            let packet = try BinaryDecoder.decode(Packet.self, data: [UInt8](message))
            
            if packet.isLast {
                pack.append(packet)
                image = assembleImage(from: pack)
                      
                let imageData = image?.jpegData(compressionQuality: 0.9)
                guard let data = imageData else {
                    print("Error on \(#function): Error on get imageData")
                    return
                }
                setImageToMessage(messageID: packet.messageID, data: data)
                pack = []
                return
            } else {
                pack.append(packet)
            }
            
        } catch {
            
        }
        print("Received binary message: \(message)")
    }
    
    func setImageToMessage(messageID: String, data: Data) {
        let messageIndex = chatMessage.firstIndex { message in
            message.messageID == messageID
        }
        guard let index = messageIndex else {
            print("Error on get message index: \(messageIndex)")
            return
        }
        
        chatMessage[index].imageDate = data
    }
    
    func assembleImage(from packets: [Packet]) -> UIImage? {
        guard let firstPacket = packets.first, firstPacket.currentSize == 0 else {
            return nil
        }

        let totalSize = firstPacket.totalSize
        var imageData = Data(capacity: totalSize)
        
        packets.forEach { packet in
            imageData.append(contentsOf: packet.data)

        }

        return UIImage(data: imageData)
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
        
        guard let objectToUp = tempObj else { return }
        
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
    
    private func deleteMessage(messageID: String) {
        withAnimation {
            self.chatMessage.removeAll { message in
                message.messageID == messageID
            }
        }
        deleteCoreDataMessage(messageID: messageID)
    }
    
    private func deleteCoreDataMessage(messageID: String) {
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
               
                context.delete(chatMessageEntity)
                
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
