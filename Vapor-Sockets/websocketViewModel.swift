//
//  websocketViewModel.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import PhotosUI
import Starscream

enum APIKey: String {
    case key = "https://6f13-2804-1814-8568-3500-ac6b-68e7-b7e8-b85d.ngrok.io"
}

final class WebsocketViewModel: ObservableObject, WebSocketDelegate {
    
    @Published var isSockedConnected: Bool = false
    
    @Published var hasReceivedPong = false
    private var isFirstPing = true
    var timer: Timer?
    
    var socket: WebSocket?
    
    @Published var isAnotherUserTapping: Bool = false
    
    @AppStorage("userID") var userID = ""
    
    @Published var newMessage: String = ""
    @Published var user = CurrentUser(userName: UUID().uuidString)
    @Published var chatMessage: [WSMessage] = []
    
    @Published var messageReceived = ""
    
    init() {
        
        if userID.isEmpty {
            self.userID = UUID().uuidString
            self.user = CurrentUser(userName: userID)
        } else {
            user = CurrentUser(userName: self.userID)
        }
       
        setupWebSocket()
        startPingTimer()
    }
    
    deinit {
        socket?.disconnect(closeCode: 0)
    }
    
    
    func setupWebSocket() {
        var request = URLRequest(url: URL(string: "\(APIKey.key.rawValue)/chatWS")!)
        request.setValue("chat", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.callbackQueue = DispatchQueue(label: "com.vluxe.starscream.myapp")
        socket?.delegate = self
        socket?.connect()
    }
    
    
    func startPingTimer() {
        timer =  Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            if self.isFirstPing {
                self.socket?.write(ping: Data())
                print("mandou")
                withAnimation {
                    self.hasReceivedPong = false
                }
                self.isFirstPing = false
            } else if self.hasReceivedPong  {
                    self.socket?.write(ping: Data())
                withAnimation {
                    self.hasReceivedPong = false
                }
                    print("mandou")
            } else if !self.isSockedConnected {
                    self.setupWebSocket()
                    print("Tentou conecao")
            } else {
                self.socket?.write(ping: Data())
                withAnimation {
                    self.hasReceivedPong = false
                }
                print("Mandou apos conexao")
            }
        }
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

extension WebsocketViewModel {
    
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
    func handlerWebsocketMessage(message: String) {
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
    
    func handlerPongMessage(data: Data?) {
        withAnimation {
            hasReceivedPong = true
        }
        print("Received pong")
    }
    
    func connectionConfirmMessage(headers: [String: String]) {
        self.isSockedConnected = true
        self.send(newMessageToSend: "i am alive", messageType: .alive)
        print("websocket is connected: \(headers)")
    }
    
    func handlerDisconnectionsMessage(reason: String, code: UInt16) {
        self.isSockedConnected = false
        print("websocket is disconnected: \(reason) with code: \(code)")
    }
    
    func handlerWebsocketMessage(message: Data) {
        print("Chegou msg em binario \(message)")
    }
    
    func handlerErrorMessage(error: Error?) {
        isSockedConnected = false
        print("Error: \(String(describing: error?.localizedDescription))")
    }
    
    func handlerCancelConectionMessage() {
        isSockedConnected = false
        print("Websocket cancelou conexão com o app")
    }
}
