//
//  ChatBubbleView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import SwiftUI

struct ChatBubbleView: View {
    @Binding var message: WSChatMessage
    @State var showView: Bool = false
    var onTap: (String) -> ()
    var body: some View {
    ZStack(alignment: message.isSendByUser ? .bottomTrailing : .bottomLeading) {
                        
            VStack(alignment: message.isSendByUser ? .trailing : .leading, spacing: 10) {
                Text(message.content)
                
                Text(dateFormatter.string(from: message.timestamp))
                    .font(.footnote)
                    .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
                

            }
            .padding(8)
            .background(message.isSendByUser ? Color.green : Color.gray)
            .cornerRadius(8)
        if showView {
            ChatReactionMenu(showView: $showView) { icon in
                onTap(icon)
            }
        }
          
        
        if !message.reactions.isEmpty {
            HStack {
                ForEach(message.isSendByUser ? message.reactions.reversed() : message.reactions , id: \.self) { reaction in
                    Text(reaction)
                }
            }
        }
    }.onLongPressGesture {
        showView.toggle()
    }

    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

