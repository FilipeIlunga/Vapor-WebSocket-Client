//
//  ChatBubbleView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import SwiftUI

enum ReactionMenuPosition {
    case top
    case bottom
}

struct ChatBubbleView: View {
    var message: WSChatMessage
    let isNextMessageFromUser: Bool
    @State private var showDocView: Bool = false
    var showReactions: Bool = false
    @Binding var  hiddenReactionMenu: Bool
    @State private var isImagePresented = false
    var onAddEmoji: (String) -> ()
    var onDeleteMessage: (String) -> ()
    
    var body: some View {
        VStack(alignment: message.isSendByUser ? .trailing : .leading, spacing: 0) {
            
            ZStack(alignment: message.isSendByUser ? .topTrailing : .topLeading) {
                
                VStack(alignment: message.isSendByUser ? .trailing : .leading) {
                    VStack(alignment: message.isSendByUser ? .trailing : .leading, spacing: 10) {
                        Text(message.content)
                        
                        dataView()
                        
                        Text(message.getDisplayDate())
                            .font(.footnote)
                            .foregroundColor(message.isSendByUser ? Color(uiColor: UIColor.secondaryLabel) : .gray)
                    }
                    .padding()
                    .background(message.isSendByUser ? .blue : Color(uiColor: UIColor.darkGray))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                    .listRowSeparator(.hidden)
                    .overlay(alignment: message.isSendByUser ? .bottomTrailing : .bottomLeading) {
                        if isNextMessageFromUser {
                            EmptyView()
                        } else{
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.title)
                                .rotationEffect(.degrees(message.isSendByUser ? -45 : 45))
                                .offset(x: message.isSendByUser ? 10 : -10, y: 10)
                                .foregroundColor(message.isSendByUser ? .blue : Color(uiColor: UIColor.darkGray))
                        }
                    }
                }
                
                if showReactions {
                    ChatReactionMenu(hiddenView: $hiddenReactionMenu) { emoji in
                        onAddEmoji(emoji)
                    }
                    .offset( y: -55)
                }
            }
            if !message.reactions.isEmpty {
                HStack {
                    ForEach(message.isSendByUser ? message.reactions.suffix(5).reversed() : Array(message.reactions.suffix(5)) , id: \.self) { reaction in
                        Text(reaction.emoji)
                            .font(.system(size: 12))
                    }
                }.padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(Color(uiColor: UIColor.darkGray))
                                .mask {
                                    Capsule()
                                        .scaleEffect(1, anchor: .center)
                                }
                            Capsule()
                                .stroke(Color.black, lineWidth: 1)
                        }
                    )
                    .offset( y: -20)
            }
            
            if showReactions && message.isSendByUser {
                Button(role: .destructive, action: {
                    onDeleteMessage(message.messageID)
                }, label: {
                    
                    Label("Delete", systemImage: "trash.fill")
                        . padding(.vertical, 5)
                        .padding(.horizontal, 10)
                })
                .background(
                    Capsule()
                        .fill(Color.white)
                        .mask {
                            Capsule()
                                .scaleEffect(1, anchor: .center)
                        }
                    
                )
            }
        }.fullScreenCover(isPresented: $showDocView) {
            if let data = message.data {
                PDFUIView(showPDF: $showDocView, data: data)
            }
        }
    }
    
    @ViewBuilder
    private func imageView(data: Data) -> some View {
        
        if let uiimage = UIImage(data: data) {
            Image(uiImage: uiimage)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 100, height: 50)
                  .onTapGesture {
                      isImagePresented = true
                  }
                  .fullScreenCover(isPresented: $isImagePresented) {
                      SwiftUIImageViewer(image: Image(uiImage: uiimage))
                          .overlay(alignment: .topTrailing) {
                              closeButton
                          }
                  }
        }

    }
    
    @ViewBuilder
    private func dataView() -> some View {
        if let data = message.data, let dataType = message.dataType {
            switch dataType {
            case .image:
                imageView(data: data)
            case .document:
                Button {
                    showDocView.toggle()
                } label: {
                    Text("PDF")
                }
                .buttonStyle(.borderedProminent)
            }
        } else if let currentSize = message.currentDataSize, let totalSize = message.totalDataSize {
            ProgressView(value: Double(currentSize), total: Double(totalSize))
        }
    }

    
    private var closeButton: some View {
        Button {
            isImagePresented = false
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
        }
        .foregroundColor(.blue)
        .padding()
    }
}

