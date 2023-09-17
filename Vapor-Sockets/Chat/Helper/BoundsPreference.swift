//
//  BoundsPreference.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 16/09/23.
//

import SwiftUI

struct BoundsPreference: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    
    static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
        value.merge(nextValue()){$1}
    }
}

