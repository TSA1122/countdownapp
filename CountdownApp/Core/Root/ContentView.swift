//
//  ContentView.swift
//  CountdownApp
//
//  Created by Taha Samet Aydil on 16.01.2025.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.userSession != nil {
                    CountdownsView()
                } else {
                    LoginView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

