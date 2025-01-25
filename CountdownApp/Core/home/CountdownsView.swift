//
//  ContentView.swift
//  CountdownApp
//
//  Created by Taha Samet Aydil on 16.01.2025.
//

import SwiftUI
import FirebaseFirestore

struct CountdownsView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showMenu = false
    @State private var selectedTab = "main"
    @State private var userCountdowns: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Divider()
                
                ZStack {
                    if selectedTab == "turkey" {
                        TurkiyeCountdownsView()
                    } else {
                        if userCountdowns.isEmpty {
                            Text("No countdowns yet")
                                .foregroundColor(.gray)
                        } else {
                            List(userCountdowns, id: \.self) { countdown in
                                Text(countdown)
                            }
                        }
                    }
                    
                    GeometryReader { geometry in
                        HStack {
                            MenuView(selectedTab: $selectedTab, showMenu: $showMenu)
                                .frame(width: geometry.size.width * 0.7)
                                .offset(x: showMenu ? 0 : -geometry.size.width * 0.7)
                                .animation(.default, value: showMenu)
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(selectedTab == "turkey" ? "Türkiye Countdowns" : "My Countdowns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showMenu.toggle()
                    }) {
                        Image(systemName: "line.horizontal.3")
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchUserCountdowns()
        }
    }
    
    private func fetchUserCountdowns() {
        let db = Firestore.firestore()
        db.collection("user_countdowns").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user's countdowns: \(error)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.userCountdowns = documents.compactMap { $0.data()["name"] as? String }
            }
        }
    }
}

struct MenuView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var selectedTab: String
    @Binding var showMenu: Bool
    @State private var isCountdownsSectionExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Menu")
                .font(.title)
            
            Button(action: {
                selectedTab = "main"
                showMenu = false
            }) {
                Text("My Countdowns")
            }
            .foregroundColor(selectedTab == "main" ? .black : .blue)
            
            Button(action: {
                withAnimation {
                    isCountdownsSectionExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Countdowns")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: isCountdownsSectionExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
            if isCountdownsSectionExpanded {
                Button(action: {
                    selectedTab = "turkey"
                    showMenu = false
                }) {
                    Text("Türkiye Countdowns")
                }
                .foregroundColor(selectedTab == "turkey" ? .black : .blue)
                .padding(.leading)
            }
            
            Button("Settings") {
                // Add settings action
            }
            
            Spacer()
            
            Button(action: {
                authViewModel.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .foregroundColor(.red)
            }
            .padding(.bottom, 50)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .edgesIgnoringSafeArea(.vertical)
    }
}

