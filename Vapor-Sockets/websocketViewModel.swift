//
//  websocketViewModel.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import PhotosUI
import Starscream


//"messageType*|*subMessage*|*"

final class WebsocketViewModel: ObservableObject {
    
    @AppStorage("userID") private var userID = ""
    @Published var user: CurrentUser = CurrentUser(userName: UUID().uuidString)
    
    @Published var chatMessage: [WSMessage] = []
    @Published var newMessage: String = ""
    @Published var messageReceived = ""
    
    @Published var isSockedConnected: Bool = false
    @Published var isAnotherUserTapping: Bool = false
    
    private var hasReceivedPong: Bool = false
    private var isFirstPing: Bool = true
    
    private var timer: Timer?
    private var socket: WebSocket?
    
    init() {
        initWebSocket()
        startHeartBeatController()
    }
    
    deinit {
        socket?.disconnect(closeCode: 0)
    }
    
    private func setupUserInfo() {
        if userID.isEmpty {
            self.userID = UUID().uuidString
            self.user = CurrentUser(userName: userID)
        } else {
            user = CurrentUser(userName: self.userID)
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

    
    func getWSMessage(header: WSMessageHeader, payload: String) -> String {
        return "\(header.wsEncode)\(payload)"
    }
    
    func sendMessage(messageHeader: WSMessageHeader, message: String) {
        switch messageHeader.messageType {
            
        case .Chat:
            guard let msgType = messageHeader.subMessageType as? ChatMessageType else {
                print("Wrong format to chatMessageType, subMsgType: \(messageHeader.subMessageType)")
                return
            }
            sendMessageChat(type: msgType, message: message)
        case .Status:
            guard let msgType = messageHeader.subMessageType as? StatusMessageType else {
                print("Wrong format to statusMessageType, subMsgType: \(messageHeader.subMessageType)")
                return
            }
            sendStatusMessage(type: msgType, message: message)
            print("ola")
        }
    }
    
    func sendStatusMessage(type: StatusMessageType, message: String) {
        let headMessageType = NewMessageType.Status
        switch type {
        case .Alive:
            sendAlive()
        case .Disconnect:
            sendDisconnected()
        }
    }
    
    
    func sendDisconnected() {
        let header = WSMessageHeader(messageType: .Status, subMessageType: StatusMessageType.Disconnect)
        
        let socketMessage = getWSMessage(header: header, payload: "\(user.userName)|i am disconnecting")
        
        socket?.write(string: socketMessage, completion: {
           print("Disconnecting message has sent")
        })
    }
    
    func sendAlive() {
        let header = WSMessageHeader(messageType: .Status, subMessageType: StatusMessageType.Alive)
        
        let socketMessage = getWSMessage(header: header, payload: "\(user.userName)|i am alive")
        
        socket?.write(string: socketMessage, completion: {
           print("Alive message was sent")
        })
    }
        
    func sendMessageChat(type: ChatMessageType, message: String) {
        let header = WSMessageHeader(messageType: .Chat, subMessageType: type)

        switch type {
        case .ContentString:
            sendContentString(header: header, message: message)
        case .ContentData:
            break
        case .Reaction:
            break
        case .Reply:
            break
        case .TypingStatus:
            sendTypingStatus(typingStatus: message)
        }
    }
    #warning("Mudar o socketMessage criar funcao para i")
    func sendTypingStatus(typingStatus: String) {
        let header = WSMessageHeader(messageType: .Chat, subMessageType: ChatMessageType.TypingStatus)
        let socketMessage = getWSMessage(header: header, payload: "\(user.userName)|\(typingStatus)")

        socket?.write(string: socketMessage, completion: {
            print("Typing message was sent")
        })
        
    }
    
    func sendContentString(header: WSMessageHeader, message: String) {        
        let messageContent = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let timestamp = Date.now
        
        let wsMessage = WSMessage(
            messageID: UUID().uuidString,
            senderID: user.userName,
            timestamp: timestamp,
            content: messageContent,
            isSendByUser: true)
        
        let socketMessage = getWSMessage(header: header, payload: wsMessage.description)
        
        socket?.write(string: socketMessage, completion: {
            DispatchQueue.main.async {
                withAnimation {
                    self.chatMessage.append(wsMessage)
                }
                self.newMessage = ""
            }
        })
    }
    
    func sendButtonDidTapped() {
        
        let newMessageToSend = newMessage.trimmingCharacters(in: .whitespaces)
        if !newMessageToSend.isEmpty {
            let messageHeader = WSMessageHeader(messageType: .Chat, subMessageType: ChatMessageType.ContentString)
            sendMessage(messageHeader: messageHeader, message: newMessageToSend)
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
        let messageSplied = message.components(separatedBy: "*|")
        
        guard messageSplied.count >= 3 else {
            print("Mensagem Invalida")
            return
        }
        
        let payload = messageSplied[2]

        guard let messageTypeCode = Int(messageSplied[0]),
              let messageType = NewMessageType(rawValue: messageTypeCode),
              let subMessageTypeCode = Int(messageSplied[1])
        else {
            return
        }
        
        switch messageType {
        case .Chat:
            guard let chatMessageType = ChatMessageType(rawValue: subMessageTypeCode) else {
                print("Invalid code to chat: \(subMessageTypeCode)")
                return
            }
            
            handlerChatMessage(type: chatMessageType, message: payload)
        case .Status:
            print("ola")
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
        let messageHeader = WSMessageHeader(messageType: .Status, subMessageType: StatusMessageType.Alive)
        sendAlive()
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

extension WebsocketViewModel {
    
    private func handlerChatMessage(type: ChatMessageType, message: String) {
        switch type {
        case .ContentString:
            handlerChatContentStringMessage(message: message)
        case .ContentData:
            print("contentData")
        case .Reaction:
            print("reaction")
        case .Reply:
            print("reply")
        case .TypingStatus:
            handlerChatTypingMessage(message: message)
        }
    }
    
    private func handlerChatContentStringMessage(message: String) {
        let messageSplited = message.components(separatedBy: "|")
        
        guard messageSplited.count >= 4 else {
            print("Message not enough fields - Expected fiedls: \(3) but received: \(messageSplited.count) - message: \(message)")
            return
        }
        
        let messageID = messageSplited[0]
        let sendID = messageSplited[1]
        let strTimeInterval = messageSplited[2]
        let content = messageSplited[3]
        
        guard let timeInterval = Double(strTimeInterval) else {
            print("Erro ao converter timestamp value: \(strTimeInterval)")
            return
        }
        

        let timestamp = Date(timeIntervalSince1970: timeInterval)

        let wsMessage = WSMessage(messageID: messageID, senderID: sendID, timestamp: timestamp, content: content, isSendByUser: false)
        
        withAnimation {
            self.chatMessage.append(wsMessage)
        }
    }
    
    private func handlerChatTypingMessage(message: String) {
        let messageSplited = message.components(separatedBy: "|")
        
        guard messageSplited.count >= 2 else {
            print("Message not enough fields - Expected fiedls: \(3) but received: \(messageSplited.count) - message: \(message)")
            return
        }
        
        let userID = messageSplited[0]
        let isTyping = messageSplited[1] == "1"
        
        self.isAnotherUserTapping = isTyping
    }
}

extension  WebsocketViewModel {
    private func decodeMessage(message: String) {
        
    }
}
