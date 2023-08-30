//
//  ContentView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI

struct CurrentUser: Codable {
    let userName: String
    let message: String
}

struct Message: Hashable {
    let  message: String
    let isSentByUser: Bool
}

struct ContentView: View {
    @State var webSocketTask: URLSessionWebSocketTask?
    @State var webSocketTaskIsTapping: URLSessionWebSocketTask?
    
    @State var isAnotherUserTapping: Bool = false
    
    @State var newMessage: String = ""
    @State var user = CurrentUser(userName: UUID().uuidString, message: "")
    @State var chatMessage: [Message] = []
    
    @State var messageReceived = ""
    
    
    @State private var isTyping = false
    private let typingThreshold = 1.0  // Defina o limite de tempo para considerar que o usuário parou de digitar
    @State private var typingTimer: Timer?
    
    
    var body: some View {
        ZStack {
            
            ScrollView(showsIndicators: false) {
                
                ForEach(chatMessage, id: \.self) { message in
                    HStack {
                        if message.isSentByUser {
                            Spacer()
                            
                            Text(message.message)
                                .padding(8)
                                .background(message.isSentByUser ? Color.blue : Color.gray)
                                .cornerRadius(8)
                            
                        } else {
                            Text(message.message)
                                .padding(8)
                                .background(message.isSentByUser ? Color.blue : Color.gray)
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                }.padding(.vertical)
            }
            
        }
        .padding()
        .onAppear {
            setupWebSocket()
        }.toolbar {
            ToolbarItem(placement: .bottomBar) {
                VStack {
                    if isAnotherUserTapping {
                        Text("Digitando")
                    }
                    
                    HStack {
                        TextEditor(text: $newMessage)
                            .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal).onChange(of: newMessage) { newText in
                                if newText.isEmpty {
                                    sendingTappingStatus(isTapping: "0")
                                    isTyping = false
                                    typingTimer?.invalidate()
                                } else if !isTyping {
                                    // O usuário começou a digitar
                                    isTyping = true
                                    typingTimer = Timer.scheduledTimer(withTimeInterval: typingThreshold, repeats: false) { _ in
                                        if !self.newMessage.isEmpty && self.isTyping {
                                            sendingTappingStatus(isTapping: "1")
                                        }
                                    }
                                }
                            }
                        
                        Button {
                            send(newMessageToSend: newMessage)
                        } label: {
                            Image(systemName: "arrowshape.turn.up.forward.circle.fill")
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    func setupWebSocket() {
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: URL(string: "ws://127.0.0.1:8080/toki")!)
        webSocketTaskIsTapping = urlSession.webSocketTask(with: URL(string: "ws://127.0.0.1:8080/isTappingSocket")!)

        webSocketTask?.resume()
        received()
    }
    
    func send(newMessageToSend: String) {
        
        let messageToSend = user.userName + "|" + newMessageToSend
        
        let message = URLSessionWebSocketTask.Message.string(messageToSend)
        
        Task {
            do {
                try await  webSocketTask?.send(message)
                self.chatMessage.append(Message(message: newMessage, isSentByUser: true))
                self.newMessage = ""
            } catch {
                print("Error \(error.localizedDescription)")
            }
        }
    }
    
    func received() {
        let chatMessageThread = DispatchQueue(label: "chatMessageThread", qos: .background)
        
        chatMessageThread.async {
            while(true) {
                webSocketTask?.receive(completionHandler: { result in
                    switch result {
                    case .success(let message):
                        switch message {
                        case .data(let data):
                            print("Received Data: \(data)")
                        case .string(let message):
                            let message = String(message.split(separator: "|").last ?? "")
                            self.chatMessage.append(Message(message: message, isSentByUser: false))
                        @unknown default:
                            print("unknown")
                        }
                    case .failure(let error):
                        print("Error on \(error)")
                    }
                })
            }
        }
    }
    
    func sendingTappingStatus(isTapping: String) {
        let messageToSend = user.userName + "|" + isTapping
        
        let message = URLSessionWebSocketTask.Message.string(messageToSend)
        
        Task {
            do {
                try await webSocketTaskIsTapping?.send(message)
                self.chatMessage.append(Message(message: newMessage, isSentByUser: true))
                self.newMessage = ""
            } catch {
                print("Error \(error.localizedDescription)")
            }
        }
    }
    
    func receivedIsTapping() {
        let chatMessageIsTapping = DispatchQueue(label: "chatMessageIsTapping", qos: .background)
        
        chatMessageIsTapping.async {
            while(true) {
                webSocketTaskIsTapping?.receive(completionHandler: { result in
                    switch result {
                    case .success(let message):
                        switch message {
                        case .data(let data):
                            print("Received Data: \(data)")
                        case .string(let message):
                            let message = String(message.split(separator: "|").last ?? "")
                            if message == "1" {
                                self.isAnotherUserTapping = true
                            } else {
                                self.isAnotherUserTapping = false
                            }
                        @unknown default:
                            print("unknown")
                        }
                    case .failure(let error):
                        print("Error on \(error)")
                    }
                })
            }
        }
    }
}

struct User: Codable {
    let userName: String
    let message: String
}
