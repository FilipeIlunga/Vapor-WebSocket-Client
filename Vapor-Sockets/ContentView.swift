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
    @StateObject var viewModel: WebsocketViewModel = WebsocketViewModel()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
        
            ScrollView(showsIndicators: false) {
                
                ForEach(viewModel.chatMessage, id: \.self) { message in
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
                }.padding(.vertical)
            }
            
            HStack {
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Text("Fechar")
                }
                
            
                PhotosPicker(selection: $viewModel.selectedItems) {
                Image(systemName: "square.and.arrow.up.fill")
                }.onChange(of: viewModel.selectedItems) { newValue in
                    guard let item = viewModel.selectedItems.first else { return }
                
                
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                        
                    case .success(let data):
                        self.viewModel.photoData = UIImage(data: data!)?.jpegData(compressionQuality: 0.1)
                     //   let img = UIImage(data: data!)?.jpegData(compressionQuality: 2)
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
            }

            
        }.onDisappear {
            viewModel.send(newMessageToSend: "0", messageType: "0")
        }
        
        .padding()
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                VStack {
                    HStack {
                        if viewModel.isAnotherUserTapping {
                            TypingAnimationView()
                                .padding(.horizontal)
                        }
                    }
                    
                    HStack {
                        TextEditor(text: $viewModel.newMessage)
                        
                            .frame(width: UIScreen.main.bounds.width * 0.7, height: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal).onChange(of: viewModel.newMessage) { newText in
                                if newText.isEmpty {
                                    viewModel.send(newMessageToSend: "0", messageType: "0")
                                } else {
                                    viewModel.send(newMessageToSend: "1", messageType: "0")
                                }
                            }
                        
                        Button {
                            if viewModel.newMessage.isEmpty {
                                guard let data = viewModel.photoData else {
                                    return
                                }
                                viewModel.send(newMessageToSend: " ", messageType: "2", data: data)

                            } else {
                                viewModel.send(newMessageToSend: viewModel.newMessage, messageType: "1")
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


}

struct User: Codable {
    let userName: String
    let message: String
}
