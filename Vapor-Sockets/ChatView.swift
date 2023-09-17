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
    @State var showHighlight: Bool = false
    
    var body: some View {
        ScrollViewReader { scrollView in
        VStack(spacing: 0) {
            List(viewModel.chatMessage, id: \.self) {  message in
                HStack {
                    if message.isSendByUser {
                        Spacer()
                        ChatBubbleView(message: message, isNextMessageFromUser: viewModel.isNextMessageFromUser(message: message), hiddenReactionMenu: $showHighlight, onAddEmoji: ({_ in}))
                            .anchorPreference(key: BoundsPreference.self, value: .bounds) { anchor in
                                return [message.messageID: anchor]
                            }
                    } else {
                        ChatBubbleView(message: message, isNextMessageFromUser: viewModel.isNextMessageFromUser(message: message), hiddenReactionMenu: $showHighlight, onAddEmoji: ({_ in}))
                            .anchorPreference(key: BoundsPreference.self, value: .bounds) { anchor in
                                hapticFeedback()
                                return [message.messageID: anchor]
                            }
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .listRowSeparator(.hidden)
                .id(message.messageID)
                .listRowInsets(.init(top:  2, leading: 0, bottom: viewModel.isNextMessageFromUser(message: message) ? 2 : 12, trailing: 0))

                .onLongPressGesture {
                    hapticFeedback()

                    withAnimation {
                        withAnimation(.easeInOut) {
                            showHighlight = true
                            selectedMessage = message
                        }
                    }
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
                
                ChatMessageField(message: $viewModel.newMessage) {
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
        }.overlay(content: {
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
                    
                    ChatBubbleView(message: selectedMsg, isNextMessageFromUser: viewModel.isNextMessageFromUser(message: selectedMsg),showReactions: true, hiddenReactionMenu: $showHighlight) { emoji in
                        withAnimation(.easeInOut) {
                            showHighlight = false
                            selectedMessage = nil
                        }
                        viewModel.sendRecation(message: selectedMsg, reaction: emoji)
                    }
                        .id(selectedMsg.messageID)
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.minX, y: rect.minY)
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

