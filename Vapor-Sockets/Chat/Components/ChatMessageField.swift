//
//  ChatMessageField.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 16/09/23.
//

import SwiftUI
import PhotosUI
import PDFKit

struct ChatMessageField: View {
    
    @State var openFile = false

    @Binding var message: String
    @Binding var data: Data?
    @Binding var imageSelection: PhotosPickerItem?
    let sendMessage: () -> ()
    var onTapping: (Bool) -> ()
    
    @State private var calculatedHeight: CGFloat = 35.0

    var body: some View {
        HStack {
            
            Button {
                openFile.toggle()
            } label: {
                Image(systemName: "doc.fill")
            }

            
            PhotosPicker(selection: $imageSelection ,matching: .images,label: {
               Image(systemName: "square.and.arrow.up")
            })
            
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
            
        }.fileImporter(isPresented: $openFile, allowedContentTypes: [.pdf, .mp3], onCompletion: { result in
            switch result {
            case .success(let dataURL):
                dataURL.startAccessingSecurityScopedResource()
                        if let pDFDocument = PDFDocument(url: dataURL) {
                            // this is nil
                            if let dataRepresentation = pDFDocument.dataRepresentation() {
                                data = dataRepresentation
                            }
                        }
                
            case .failure(let error):
                print("Error on import file: \(error.localizedDescription)")
            }
        })
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

