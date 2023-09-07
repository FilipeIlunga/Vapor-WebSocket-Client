//
//  ContentView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import PhotosUI

struct User: WSCodable {
    let userName: String
}


struct ContentView: View {
    
    @State private var position: Int?
    
    @State var isconnected: Bool = true

    
    @StateObject var viewModel: WebsocketViewModel = WebsocketViewModel()
    @State var numberOFLiner = 0
    @State private var calculatedHeight: CGFloat = 35.0
    @State var selectedMessage: WSChatMessage?
    
    @State var icon: String = "😃"
    
    var body: some View {
        VStack(spacing: 0) {
        ScrollView {
            ForEach($viewModel.chatMessage, id: \.self) { message in
                HStack {
                    if message.isSendByUser.wrappedValue {
                        Spacer()
                        ChatBubbleView(message: message.wrappedValue) { icon in
                            viewModel.sendRecation(message: message.wrappedValue, reaction: icon)
                        }
                    } else {
                        ChatBubbleView(message: message.wrappedValue) { icon in
                            viewModel.sendRecation(message: message.wrappedValue, reaction: icon)
                        }
                        Spacer()
                    }
                }.contextMenu {
                    
                }
                .padding(.horizontal)
                .padding(.bottom)
                .listRowSeparator(.hidden)
                
            }
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
        
        Divider()
        
        VStack {
            
            HStack {
                Button {
                    if isconnected {
                        viewModel.sendStatusMessage(type: .Disconnect)
                    } else {
                        viewModel.sendStatusMessage(type: .Alive)
                    }
                    isconnected.toggle()

                } label: {
                    Image(systemName: "circle.circle.fill")
                        .foregroundColor(.pink)
                }

                Image(systemName: "circle.circle.fill")
                    .foregroundColor(viewModel.isSockedConnected ? .green : .red)
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .frame(width: UIScreen.main.bounds.width * 0.75, height: calculatedHeight)
                        .foregroundColor(.green)
                        .allowsHitTesting(false)
                    
                    TextEditor(text: $viewModel.newMessage)
                        .frame(width: UIScreen.main.bounds.width * 0.7, height: calculatedHeight)
                        .scrollContentBackground(.hidden)
                        .background {
                            GeometryReader { geometry in
                                Color.clear
                                    .onChange(of: viewModel.newMessage) { newText in
                                        print("New size: \(geometry.size.width)")
                                        withAnimation {
                                            calculateHeight(newText, geometry: geometry)
                                        }
                                    }
                            }
                        }
                        .onChange(of: viewModel.newMessage) { newText in
                            if newText.isEmpty {
                                viewModel.sendTypingStatus(isTyping: false)
                            } else {
                                viewModel.sendTypingStatus(isTyping: true)
                            }
                        }
                }
                
                VStack {
                    Button {
                        viewModel.sendButtonDidTapped()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                    } label: {
                        Image(systemName: "arrowshape.turn.up.forward.circle.fill")
                    }.font(.title)
                        .foregroundColor(.green)
                    
                }
                
            }
            .padding(.vertical, 10)
            .padding(.bottom, 10)
            .onDisappear {
                viewModel.sendStatusMessage(type: .Disconnect)
            }
            .onAppear {
                viewModel.sendStatusMessage(type: .Alive)
            }
        }
    }
        }
        
        private func calculateHeight(_ text: String, geometry: GeometryProxy) {
            let textWidth = text.sizeThatFits()
            print("Log: \(textWidth)")
            if textWidth < 294.5 {
                calculatedHeight = 35
            } else if textWidth >= 294.5 && textWidth < 582 {
                calculatedHeight = 55
            } else if textWidth >= 582 && textWidth < 870 {
                calculatedHeight = 75
            } else if textWidth >= 870 && textWidth < 1158 {
                calculatedHeight = 95
            } else {
                calculatedHeight = 105
            }
        }
        
    }
    
    extension String {
        func sizeThatFits() -> CGFloat {
            let fontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular)]
            let size = self.size(withAttributes: fontAttributes)
            return size.width
        }
    }
    
