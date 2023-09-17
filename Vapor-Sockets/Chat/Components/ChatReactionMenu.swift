//
//  ChatReactionMenu.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 04/09/23.
//

import SwiftUI

struct ChatReactionMenu: View {
    @Binding var hiddenView: Bool 
    var onTap: (String) -> ()
    @State var animateEmoji: [Bool] = Array(repeating: false, count: ChatReaction.allCases.count)
    @State var animateView: Bool = false
    
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ChatReaction.allCases.indices, id: \.self) { index in
                Text(ChatReaction.allCases[index].rawValue)
                    .font(.system(size: 25))
                    .scaleEffect(animateEmoji[index] ? 1 : 0.1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                animateEmoji[index] = true
                            }
                        }
                    }
                    .onTapGesture {
                        onTap(ChatReaction.allCases[index].rawValue)
                      
                    }
            }
        }.padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
             Capsule()
                .fill(.white)
                .mask {
                    Capsule()
                        .scaleEffect(animateView ? 1 : 0, anchor: .leading)
                }
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animateView = true
                }
            }
            .onChange(of: hiddenView) { newValue in
                if !newValue {
                    withAnimation(.easeInOut) {
                        animateView = true
                    }
                    
                    for index in ChatReaction.allCases.indices {
                        withAnimation(.easeOut) {
                            animateView = true
                            animateEmoji[index] = false
                        }
                    }
                }
            }
    }
}

