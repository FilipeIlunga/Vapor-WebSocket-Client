//
//  SendableImage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 20/09/23.
//

import PhotosUI
import SwiftUI

struct SendableImage: Transferable {
    let image: Image
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(uiImage: uiImage)
            return SendableImage(image: image)
        }
    }
}

enum ImageState {
    case empty
    case loading(Progress)
    case success(Image)
    case failure(Error)
}

enum TransferError: Error {
    case importFailed
}
