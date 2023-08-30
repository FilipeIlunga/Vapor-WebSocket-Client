//
//  ContentView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import PhotosUI

struct CurrentUser: Codable {
    let userName: String
    let message: String
}

//0 isTyping
//1 message
//2 data
struct Message: Hashable {
    let  message: String
    let isSentByUser: Bool
    let messageType: String
    let data: Data?
}


struct ContentView: View {
    @State var webSocketTask: URLSessionWebSocketTask?
    @State var webSocketTaskIsTapping: URLSessionWebSocketTask?
    
    @State var selectedItems: [PhotosPickerItem] = []
    @State var photoData: Data? = nil
    
    
    @State var isAnotherUserTapping: Bool = false
    
    @State var newMessage: String = ""
    @State var user = CurrentUser(userName: UUID().uuidString, message: "")
    @State var chatMessage: [Message] = []
    
    @State var messageReceived = ""
    
    
    @State private var isTyping = false
    private let typingThreshold = 1.0  // Defina o limite de tempo para considerar que o usuário parou de digitar
    @State private var typingTimer: Timer?
    
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
        
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
            
            PhotosPicker(selection: $selectedItems) {
                Image(systemName: "square.and.arrow.up.fill")
            }.onChange(of: selectedItems) { newValue in
                guard let item = selectedItems.first else { return }
                
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                        
                    case .success(let data):
                        self.photoData = data
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
            
        }.onDisappear {
            send(newMessageToSend: "0", messageType: "0")
        }
        .padding()
        .onAppear {
            setupWebSocket()
        }.toolbar {
            ToolbarItem(placement: .bottomBar) {
                VStack {
                    if isAnotherUserTapping {
                        TypingAnimationView()
                    }
                    
                    HStack {
                        TextEditor(text: $newMessage)
                        
                            .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal).onChange(of: newMessage) { newText in
                                if newText.isEmpty {
                                    send(newMessageToSend: "0", messageType: "0")
                                } else {
                                    send(newMessageToSend: "1", messageType: "0")
                                }
                            }
                        
                        Button {
                            if newMessage.isEmpty {
                                guard let data = photoData else {
                                    return
                                }
                                send(newMessageToSend: " ", messageType: "2", data: data)

                            } else {
                                send(newMessageToSend: newMessage, messageType: "1")
                            }
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
        send(newMessageToSend: " ", messageType: "3")
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
                    try await  webSocketTask?.send(message)
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
        let chatMessageThread = DispatchQueue(label: "chatMessageThread", qos: .background)
        
        chatMessageThread.async {
            while(true) {
                webSocketTask?.receive(completionHandler: { result in
                    switch result {
                    case .success(let message):
                        switch message {
                        case .data(let data):
                            self.chatMessage.append(Message(message: "", isSentByUser: false, messageType: "3", data: data))
                        case .string(let message):
                            let messageSplited = message.split(separator: "|")
                            let messageType = String(messageSplited[2])
                            
                            if messageType == "0" {
                                self.isAnotherUserTapping = messageSplited[1] == "1"
                            } else if messageType == "1" {
                                self.chatMessage.append(Message(message: String(messageSplited[1]), isSentByUser: false, messageType: "0", data: nil))
                            } else {
                                self.chatMessage.append(Message(message: String(messageSplited[1]), isSentByUser: false, messageType: "0", data: nil))
                            }
                        @unknown default:
                            print("unknown")
                        }
                    case .failure(let error):
                        print("Error on \(error.localizedDescription)")
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
