//
//  websocketViewModel.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import PhotosUI
import Starscream

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
    
     func send(newMessageToSend: String, messageType: MessageType) {
        
        let newMsgToSend = newMessageToSend.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let timestamp = Date.now
        let message = WSMessage(senderID: user.userName,messageType: messageType, timestamp: timestamp, content: newMsgToSend, isSendByUser: true)
        
        socket?.write(string: message.description, completion: {
            if messageType == .chatMessage {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.chatMessage.append(message)
                        }
                        self.newMessage = ""
                    }
                }
            })

    }
    
    func sendButtonDidTapped() {
        
        let newMessageToSend = newMessage.trimmingCharacters(in: .whitespaces)
        if !newMessageToSend.isEmpty {
            send(newMessageToSend: newMessageToSend, messageType: MessageType.chatMessage)
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
                print("send Ping on start connection")
                withAnimation {
                    self.hasReceivedPong = false
                }
                self.isFirstPing = false
            } else if self.hasReceivedPong  {
                    self.socket?.write(ping: Data())
                withAnimation {
                    self.hasReceivedPong = false
                }
                    print("send ping")
            } else if !self.isSockedConnected {
                    self.initWebSocket()
                    print("Websocket is disconnected, trying connection")
            } else {
                self.socket?.write(ping: Data())
                withAnimation {
                    self.hasReceivedPong = false
                }
                print("Mandou apos conexao")
            }
        }
    }
}

extension WebsocketViewModel {
    private func handlerWebsocketMessage(message: String) {
        let messageSplied = message.components(separatedBy: "|")
        
        guard messageSplied.count >= 4 else {
            print("Mensagem Invalida")
            return
        }
        
        let userID = messageSplied[0]
        let stringTimestamp = messageSplied[2]
        let messageContent = messageSplied[3]
        
        guard let timeInterval = Double(stringTimestamp), let messageTypeRawValue = Int(messageSplied[1]), let messageType = MessageType(rawValue: messageTypeRawValue) else {
            print("Erro ao converter timestamp")
            return
        }
        
        let timestamp = Date(timeIntervalSince1970: timeInterval)

        
        DispatchQueue.main.async {
            
            if messageType == .typingStatus {
                self.isAnotherUserTapping = messageContent == "1"
            } else if messageType == .chatMessage {
                let messageReceived = WSMessage(senderID: userID, messageType: messageType, timestamp: timestamp, content: messageContent, isSendByUser: false)
                withAnimation {
                    self.chatMessage.append(messageReceived)
                }
            } else {
                print("Unknown message type: \(messageType)")
            }
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
        self.send(newMessageToSend: "i am alive", messageType: .alive)
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


