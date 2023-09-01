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
    case key = "https://d09d-138-122-73-139.ngrok.io"
}

final class WebsocketViewModel: ObservableObject, WebSocketDelegate {

   // @Published var webSocketTask: URLSessionWebSocketTask?
    
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var photoData: Data? = nil
    
    var socket: WebSocket?
    
    @Published var isAnotherUserTapping: Bool = false
    
    @Published var newMessage: String = ""
    @Published var user = CurrentUser(userName: UUID().uuidString, message: "")
    @Published var chatMessage: [Message] = []
    
    @Published var messageReceived = ""
    
    init() {
        setupWebSocket()
    }
    
    deinit {
        socket?.disconnect(closeCode: 0)
    }
    func setupWebSocket() {
        var request = URLRequest(url: URL(string: "\(APIKey.key.rawValue)/toki")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func send(newMessageToSend: String, messageType: String, data: Data? = nil) {
        
        let newMsgToSend = newMessageToSend.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !newMsgToSend.isEmpty else {return}
        let messageToSend = user.userName + "|" +  newMsgToSend + "|" + messageType
        
        if messageType == "2" {
            if let data = data {
                socket?.write(data: data)
            }
        } else {
            socket?.write(string: messageToSend, completion: {
                if messageType == "1" {
                    DispatchQueue.main.async {
                        self.chatMessage.append(Message(message: newMsgToSend, isSentByUser: true, messageType: "1", data: nil))
                        self.newMessage = ""
                    }
                }
            })
        }
    }
    
    func sendButtonDidTapped() {
        if newMessage.isEmpty {
            guard let data = photoData else {
                return
            }
            send(newMessageToSend: " ", messageType: "2", data: data)

        } else {
            let newMessageToSend = newMessage.trimmingCharacters(in: .whitespaces)
            if !newMessageToSend.isEmpty {
                send(newMessageToSend: newMessageToSend, messageType: "1")
            }
        }
    }
    
}

extension WebsocketViewModel {
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
           // isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
           // isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let message):
            handlerWebsocketMessage(message: message)
        case .binary(let data):
            self.chatMessage.append(Message(message: "", isSentByUser: false, messageType: "3", data: data))
        case .ping(_):
          print("Received ping")
        case .pong(_):
            print("Received pong")
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
          //  isConnected = false
            print("Cancelou")
        case .error(let error):
          //  isConnected = false
            print("Error: \(String(describing: error?.localizedDescription))")
            case .peerClosed:
                   break
        }
    }
}

extension WebsocketViewModel {
    func handlerWebsocketMessage(message: String) {
        let messageComponents = message.components(separatedBy: "|")

        guard messageComponents.count >= 3 else {
            return
        }
        
        let messageType = messageComponents[2]
        let content = messageComponents[1]
        DispatchQueue.main.async {
        if messageType == "0" {
            self.isAnotherUserTapping = content == "1"
        } else if messageType == "1" || messageType == "2" {
            self.chatMessage.append(Message(message: content, isSentByUser: false, messageType: messageType, data: nil))
        } else {
            print("Unknown message type: \(messageType)")
        }
    }
    }
}
