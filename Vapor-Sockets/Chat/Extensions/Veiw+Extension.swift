//
//  Veiw+Extension.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 16/09/23.
//

import SwiftUI

extension View {
    func hiddenKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
