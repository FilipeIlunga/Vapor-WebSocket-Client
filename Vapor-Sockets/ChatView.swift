//
//  ContentView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI
import PhotosUI

struct ChatView: View {
    
    @StateObject var viewModel: WebsocketViewModel = WebsocketViewModel()
    @State var selectedMessage: WSChatMessage?
    
    @State private var position: Int?
    @State var isconnected: Bool = true
    @State var showHighlight: Bool = false
    
    var body: some View {
        ScrollViewReader { scrollView in
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.chatMessage, id: \.self) {  message in
                        HStack {
                            if message.isSendByUser {
                                Spacer()
                            }
                            ChatBubbleView(message: message, isNextMessageFromUser: viewModel.isNextMessageFromUser(message: message), hiddenReactionMenu: $showHighlight, onAddEmoji: ({_ in}), onDeleteMessage: ({_ in}))
                                .onTapGesture {}
                                .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 30) {
                                    hapticFeedback()
                                    
                                    
                                    withAnimation {
                                        withAnimation(.easeInOut) {
                                            showHighlight = true
                                            selectedMessage = message
                                        }
                                    }
                                }
                            
                            if !message.isSendByUser {
                                Spacer()
                            }
                            
                        }
                        .anchorPreference(key: BoundsPreference.self, value: .bounds) { anchor in
                            return [message.messageID: anchor]
                        }
                        .padding(.horizontal)
                        .listRowSeparator(.hidden)
                        .id(message.messageID)
                        .listRowInsets(.init(top:  2, leading: 0, bottom: viewModel.isNextMessageFromUser(message: message) ? 2 : 12, trailing: 0))
                    }
                }
                .lineSpacing(0.0)
                .listStyle(.plain)
                .onTapGesture {
                    self.hiddenKeyboard()
                }
                .onChange(of: viewModel.chatMessage.count) { newValue in
                    withAnimation {
                        scrollView.scrollTo(viewModel.chatMessage.last?.messageID, anchor: .top)
                    }
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
                    
                    ChatMessageField(message: $viewModel.newMessage, data: $viewModel.dataPicker, imageSelection: $viewModel.imageSelection) {
                        viewModel.sendButtonDidTapped()
                    } onTapping: { isTapping in
                        viewModel.sendTypingStatus(isTyping: isTapping)
                    }.padding(.top)
                    
                    
                }
            }.onAppear {
                withAnimation(.spring()) {
                    scrollView.scrollTo(viewModel.chatMessage.last?.messageID, anchor: .top)
                }
            }
            .onDisappear {
                viewModel.disconnectSocket()
            }
        }
        .overlay(content: {
            if showHighlight {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showHighlight = false
                            selectedMessage = nil
                        }
                    }
            }
        })
        .overlayPreferenceValue(BoundsPreference.self) { values in
            if let selectedMsg = selectedMessage, let preference = values.first(where: { item in
                item.key == selectedMsg.messageID
            }) {
                GeometryReader { proxy in
                    let rect = proxy[preference.value]
                    let rectMinY = rect.minY < 0 ?  rect.minY + 100 : rect.minY
                    
                    HStack {
                        if selectedMsg.isSendByUser {
                            Spacer()
                        }
                        ChatBubbleView(message: selectedMsg, isNextMessageFromUser: viewModel.isNextMessageFromUser(message: selectedMsg),showReactions: true, hiddenReactionMenu: $showHighlight) { emoji in
                            withAnimation(.easeInOut) {
                                showHighlight = false
                                selectedMessage = nil
                            }
                            let newReation = WSReaction(count: 1, emoji: emoji)
                            viewModel.sendRecation(messageID: selectedMsg.messageID, reaction: newReation)
                        } onDeleteMessage: { messageID in
                            viewModel.sendDeleteMessage(messageID: messageID)
                            withAnimation(.easeInOut) {
                                showHighlight = false
                                selectedMessage = nil
                            }
                        }
                        .id(selectedMsg.messageID)
                        .offset(y: rectMinY)
                        
                        if !selectedMsg.isSendByUser {
                            Spacer()
                        }
                    }.padding(.horizontal)
                    
                }
                .transition(.asymmetric(insertion: .identity, removal: .offset(x: 1)))
            }
        }
        
    }
    
    private func hapticFeedback() {
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        impactHeavy.impactOccurred()
    }
    
}

extension String {
    func sizeThatFits() -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .regular)]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}

