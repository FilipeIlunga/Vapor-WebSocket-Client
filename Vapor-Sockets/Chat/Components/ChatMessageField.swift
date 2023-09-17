//
//  ChatMessageField.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 16/09/23.
//

import SwiftUI

struct ChatMessageField: View {
    
    @Binding var message: String
    let sendMessage: () -> ()
    var onTapping: (Bool) -> ()
    
    @State private var calculatedHeight: CGFloat = 35.0

    var body: some View {
        HStack {

//            Button {
//                if isconnected {
//                    viewModel.sendStatusMessage(type: .Disconnect)
//                } else {
//                    viewModel.sendStatusMessage(type: .Alive)
//                }
//                isconnected.toggle()
//
//            } label: {
//                Image(systemName: "circle.circle.fill")
//                    .foregroundColor(.pink)
//            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .frame(width: UIScreen.main.bounds.width * 0.75, height: calculatedHeight)
                    .foregroundColor(.blue)
                    .allowsHitTesting(false)
                
                TextEditor(text: $message)
                    .frame(width: UIScreen.main.bounds.width * 0.7, height: calculatedHeight)
                    .scrollContentBackground(.hidden)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onChange(of: message) { newText in
                                    if newText.isEmpty {
                                        onTapping(false)
                                    } else {
                                        onTapping(true)
                                    }
                                    withAnimation {
                                        calculateHeight(newText, geometry: geometry)
                                    }
                                }
                        }
                    }

            }
            
            VStack {
                Button {
                    sendMessage()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                }.font(.title)
                    .foregroundColor(.blue)
                
            }
            
        }
    }
    
    private func calculateHeight(_ text: String, geometry: GeometryProxy) {
        let textWidth = text.sizeThatFits()
        print("Log: \(textWidth)")
        if textWidth < 294.5 {
            calculatedHeight = 35
        } else if textWidth >= 294.5 && textWidth < 582 {
            calculatedHeight = 55
        } else if textWidth >= 582 && textWidth < 870 {
            calculatedHeight = 75
        } else if textWidth >= 870 && textWidth < 1158 {
            calculatedHeight = 95
        } else {
            calculatedHeight = 105
        }
    }
    
}

