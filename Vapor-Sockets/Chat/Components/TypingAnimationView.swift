//
//  TypingAnimationView.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI

struct TypingAnimationView: View {
    @State private var isTyping = false
    
    var body: some View {
        VStack {
            Text("Typing...")
                .opacity(isTyping ? 1 : 0)
                .onAppear {
                    startTypingAnimation()
                }
        }
    }
    
    private func startTypingAnimation() {
        withAnimation {
            isTyping.toggle()
        }
        
        // Simulate a delay and reset the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isTyping.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                startTypingAnimation()
            }
        }
    }
}
