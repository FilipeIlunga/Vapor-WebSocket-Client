//
//  Vapor_SocketsApp.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 30/08/23.
//

import SwiftUI

@main
struct Vapor_SocketsApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                Text("Chat")
                Image(systemName: "message.fill")
            }
            RecycleGameView()
                .tabItem {
                Text("Game")
                Image(systemName: "gamecontroller.fill")
            }
        }
    }
}
