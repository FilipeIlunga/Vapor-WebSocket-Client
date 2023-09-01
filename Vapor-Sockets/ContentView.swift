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

struct Message: Hashable {
    let  message: String
    let isSentByUser: Bool
    let messageType: String
    let data: Data?
}

struct ContentView: View {
    @StateObject var viewModel: WebsocketViewModel = WebsocketViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
                List(viewModel.chatMessage, id: \.self) { message in
                    HStack {
                        if message.isSentByUser {
                            Spacer()
                            Text(message.message)
                                .padding(8)
                                .background(message.isSentByUser ? Color.blue : Color.gray)
                                .cornerRadius(8)
                            
                        } else {
                            if let data = message.data, let uiimage = UIImage(data: data) {
                                Image(uiImage: uiimage)
                                    .resizable()
                            } else {
                                Text(message.message)
                                    .padding(8)
                                    .background(message.isSentByUser ? Color.blue : Color.gray)
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .lineSpacing(0.0)
                .listStyle(.plain)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            HStack {
                
                if viewModel.isAnotherUserTapping {
                    TypingAnimationView()
                        .padding(.horizontal)
                }
                Spacer()
            }.padding(.leading, 10)
            .padding(.bottom, 10)
            
            Divider()
            VStack {
                
                HStack {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                                 .frame(width: UIScreen.main.bounds.width * 0.75, height: 80)
                                 .foregroundColor(.green)
                                 .allowsHitTesting(false)
                        
                        TextEditor(text: $viewModel.newMessage)
                            .frame(width: UIScreen.main.bounds.width * 0.7, height: 75)
                            .scrollContentBackground(.hidden)
                            .onChange(of: viewModel.newMessage) { newText in
                                if newText.isEmpty {
                                    viewModel.send(newMessageToSend: "0", messageType: "0")
                                } else {
                                    viewModel.send(newMessageToSend: "1", messageType: "0")
                                }
                            }
                    }
                    
                    VStack {
                        Button {
                            viewModel.sendButtonDidTapped()
                        } label: {
                            Image(systemName: "arrowshape.turn.up.forward.circle.fill")
                        }.font(.title)
                        .foregroundColor(.green)

                    }
                }
                
            }
            .padding(.vertical, 10)
            .padding(.bottom, 10)
            .onDisappear {
                viewModel.send(newMessageToSend: "0", messageType: "0")
            }
        }
        
    }
}

struct User: Codable {
    let userName: String
    let message: String
}
