//
//  websocketViewModel.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import _PhotosUI_SwiftUI

final class WebsocketViewModel: ObservableObject {
    
    @Published var webSocketTask: URLSessionWebSocketTask?
    
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var photoData: Data? = nil
    
    
    @Published var isAnotherUserTapping: Bool = false
    
    @Published var newMessage: String = ""
    @Published var user = CurrentUser(userName: UUID().uuidString, message: "")
    @Published var chatMessage: [Message] = []
    
    @Published var messageReceived = ""
    
    
    init() {
        setupWebSocket()
    }
    
    func setupWebSocket() {
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: URL(string: "ws://127.0.0.1:8080/toki")!)
        webSocketTask?.resume()
        send(newMessageToSend: "i am listening now", messageType: "3")
        received()
    }
    
    func send(newMessageToSend: String, messageType: String, data: Data? = nil) {
        let messageToSend = user.userName + "|" + newMessageToSend + "|" + messageType
        
        if messageType == "2" {
            if let data = data {
                let messageData = URLSessionWebSocketTask.Message.data(data)
                
                Task {
                    do {
                        try await webSocketTask?.send(messageData)
                    } catch {
                        print("Error on sendData")
                    }
                }
            }
        } else {
            let message = URLSessionWebSocketTask.Message.string(messageToSend)
            
            Task {
                do {
                    try await webSocketTask?.send(message)
                    if messageType == "1" {
                        self.chatMessage.append(Message(message: newMessage, isSentByUser: true, messageType: "1", data: nil))
                        self.newMessage = ""
                    }
                } catch {
                    print("Error \(error.localizedDescription)")
                }
            }
        }
    }
    
    func received() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleWebSocketMessage(message)
                self.received() // Continue a receber dados
            case .failure(let error):
                print("Error on receive: \(error)")
            }
        }
    }

    func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            self.chatMessage.append(Message(message: "", isSentByUser: false, messageType: "3", data: data))
        case .string(let message):
            let messageComponents = message.components(separatedBy: "|")
            
            guard messageComponents.count >= 3 else {
                return
            }
            
            let messageType = messageComponents[2]
            let content = messageComponents[1]
            
            if messageType == "0" {
                self.isAnotherUserTapping = content == "1"
            } else if messageType == "1" || messageType == "2" {
                self.chatMessage.append(Message(message: content, isSentByUser: false, messageType: messageType, data: nil))
            } else {
                print("Unknown message type: \(messageType)")
            }
        default:
            print("Unknown message format")
        }
    }
    
}
