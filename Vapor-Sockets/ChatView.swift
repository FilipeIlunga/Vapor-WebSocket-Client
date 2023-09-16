//
//  ContentView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI

struct ChatView: View {
    
    @StateObject var viewModel: WebsocketViewModel = WebsocketViewModel()
    @State var selectedMessage: WSChatMessage?
    
    @State private var position: Int?
    @State var isconnected: Bool = true
        
    var body: some View {
        ScrollViewReader { scrollView in
        VStack(spacing: 0) {
            List(viewModel.chatMessage, id: \.self) {  message in
                HStack {
                    if message.isSendByUser {
                        Spacer()
                        ChatBubbleView(message: message, isNextMessageFromUser: viewModel.isNextMessageFromUser(message: message))
                    } else {
                        ChatBubbleView(message: message, isNextMessageFromUser: viewModel.isNextMessageFromUser(message: message))
                        Spacer()
                    }
                }.listRowInsets(.init(top:  2,
                                      leading: 0,
                                      bottom: viewModel.isNextMessageFromUser(message: message) ? 2 : 12,
                                      trailing: 0))
                .padding(.horizontal)
                .listRowSeparator(.hidden)
                .id(message.messageID)
            }
            .lineSpacing(0.0)
            .listStyle(.plain)
            .onTapGesture {
                self.hiddenKeyboard()
            }
            .onChange(of: viewModel.chatMessage) { newValue in
                scrollView.scrollTo(newValue.last?.messageID, anchor: .bottom)
            }
            
            HStack {
                
                if viewModel.isAnotherUserTapping {
                    TypingAnimationView()
                        .padding(.horizontal)
                }
                Spacer()
            }.padding(.leading, 10)
            
            VStack {
                Divider()
                
                ChatMessageField(message: $viewModel.newMessage) {
                    viewModel.sendButtonDidTapped()
                } onTapping: { isTapping in
                    viewModel.sendTypingStatus(isTyping: isTapping)
                }.padding()
            }
        }
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

