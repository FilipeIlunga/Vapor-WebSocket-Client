//
//  ChatBubbleView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import SwiftUI


struct ChatBubbleView: View {
    var message: WSChatMessage
    
    var body: some View {
    ZStack(alignment: message.isSendByUser ? .bottomTrailing : .bottomLeading) {
        
        VStack(alignment: message.isSendByUser ? .trailing : .leading, spacing: 10) {
            Text(message.content)
            
            Text(dateFormatter.string(from: message.timestamp))
                .font(.footnote)
                .foregroundColor(Color(uiColor: UIColor.secondaryLabel))

        }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
            .listRowSeparator(.hidden)
            .overlay(alignment: message.isSendByUser ? .bottomTrailing : .bottomLeading) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.title)
                    .rotationEffect(.degrees(message.isSendByUser ? -45 : 45))
                    .offset(x: message.isSendByUser ? 10 : -10, y: 10)
                    .foregroundColor(.blue)
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
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

