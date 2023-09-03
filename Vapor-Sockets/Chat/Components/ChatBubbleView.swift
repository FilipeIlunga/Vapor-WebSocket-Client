//
//  ChatBubbleView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import SwiftUI

struct ChatBubbleView: View {
    @Binding var message: WSMessage
    var body: some View {
        VStack(alignment: message.isSendByUser ? .trailing : .leading, spacing: 10) {
            Text(message.content)
            
            Text(dateFormatter.string(from: message.timestamp))
                .font(.footnote)
                .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
        }
        .padding(8)
        .background(message.isSendByUser ? Color.green : Color.gray)
        .cornerRadius(8)
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ChatBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        ChatBubbleView(message: .constant(WSMessage(senderID: "312123", timestamp: Date.now, content: "Ola meu grande amigo como vai voce?", isSendByUser: true)))
    }
}
