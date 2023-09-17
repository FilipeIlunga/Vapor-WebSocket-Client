//
//  ChatBubbleView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import SwiftUI


struct ChatBubbleView: View {
    var message: WSChatMessage
    let isNextMessageFromUser: Bool
    var showReactions: Bool = false
    @Binding var  hiddenReactionMenu: Bool
    var onAddEmoji: (String) -> ()
    
    var body: some View {
        ZStack(alignment: message.isSendByUser ? .bottomTrailing : .bottomLeading) {
           
            ZStack(alignment: message.isSendByUser ? .topTrailing : .topLeading){

            VStack(alignment: message.isSendByUser ? .trailing : .leading) {
                VStack(alignment: message.isSendByUser ? .trailing : .leading, spacing: 10) {
                    Text(message.content)
                    
                    Text(message.getDisplayDate())
                        .font(.footnote)
                        .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
                    
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
                    ForEach(message.isSendByUser ? message.reactions.reversed() : message.reactions , id: \.self) { reaction in
                        Text(reaction)
                    }
                }
            }
        }
    }
}

