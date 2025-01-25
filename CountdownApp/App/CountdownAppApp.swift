//
//  CountdownAppApp.swift
//  CountdownApp
//
//  Created by Taha Samet Aydil on 16.01.2025.
//

import SwiftUI
import FirebaseCore

@main
struct CountdownAppApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
