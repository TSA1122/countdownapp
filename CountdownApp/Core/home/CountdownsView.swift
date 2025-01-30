//
//  ContentView.swift
//  CountdownApp
//
//  Created by Taha Samet Aydil on 16.01.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CountdownsView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var viewModel = CountdownViewModel()
    @State private var showMenu = false
    @State private var selectedTab = "main"
    @State private var currentTime = Date()
    @State private var isEditMode = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Divider()
                
                ZStack {
                    if selectedTab == "turkey" {
                        TurkiyeCountdownsView(viewModel: viewModel)
                    } else if selectedTab == "world" {
                        WorldCountdownsView(viewModel: viewModel)
                    } else {
                        if viewModel.userCountdowns.isEmpty {
                            Text("No favorite countdowns yet")
                                .foregroundColor(.gray)
                        } else {
                            List(viewModel.userCountdowns, id: \.id) { countdown in
                                ZStack(alignment: .topTrailing) {
                                    if isEditMode {
                                        Button(action: {
                                            viewModel.removeCountdown(countdownId: countdown.id)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title2)
                                        }
                                        .padding(.top, 8)
                                        .padding(.trailing, 8)
                                    }
                                    
                                    VStack(spacing: 0) {
                                        Spacer()
                                            .frame(height: 16)
                                        ZStack {
                                            Text(countdown.name)
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .padding(.horizontal, 20)
                                        
                                        Spacer()
                                            .frame(height: 24)
                                        
                                        let components = calculateTimeRemaining(until: countdown.date)
                                        HStack(spacing: 20) {
                                            if components.years > 0 {
                                                TimeBoxView(value: components.years, unit: "Years")
                                            }
                                            TimeBoxView(value: components.days, unit: "Days")
                                            TimeBoxView(value: components.hours, unit: "Hours")
                                            TimeBoxView(value: components.minutes, unit: "Minutes")
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.bottom, 16)
                                    }
                                    .frame(height: 160)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
                            }
                            .listRowSpacing(16)
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
            .navigationTitle(selectedTab == "turkey" ? "Türkiye Countdowns" : 
                           selectedTab == "world" ? "World Countdowns" : "My Countdowns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation(.spring()) {
                            showMenu.toggle()
                        }
                    }) {
                        Image(systemName: showMenu ? "xmark" : "line.horizontal.3")
                            .rotationEffect(.degrees(showMenu ? 90 : 0))
                            .animation(.spring(), value: showMenu)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedTab == "main" {
                        Button(action: {
                            isEditMode.toggle()
                        }) {
                            Text(isEditMode ? "Done" : "Edit")
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchUserCountdowns()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onChange(of: selectedTab) { newTab in
            if isEditMode && newTab != "main" {
                isEditMode = false
            }
        }
    }
    
    private func calculateTimeRemaining(until targetDate: Date) -> (years: Int, days: Int, hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .day, .hour, .minute], 
                                              from: currentTime, 
                                              to: targetDate)
        
        // Calculate total years and remaining days
        let years = max(components.year ?? 0, 0)
        let days = max(components.day ?? 0, 0)
        
        return (
            years: years,
            days: days,
            hours: max(components.hour ?? 0, 0),
            minutes: max(components.minute ?? 0, 0)
        )
    }
}

struct MenuView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var selectedTab: String
    @Binding var showMenu: Bool
    @State private var isCountdownsSectionExpanded = true
    @State private var showSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                selectedTab = "main"
                showMenu = false
            }) {
                HStack {
                    Text("My Countdowns")
                    Spacer()
                }
            }
            .foregroundColor(selectedTab == "main" ? .black : .blue)
            
            VStack(alignment: .leading, spacing: 15) {
                Button(action: {
                    withAnimation {
                        isCountdownsSectionExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Countdowns")
                            .font(.headline)
                            .foregroundColor(.blue)  // Changed from .gray to .blue
                        Spacer()
                        Image(systemName: isCountdownsSectionExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.blue)  // Changed from .gray to .blue
                    }
                }
                
                if isCountdownsSectionExpanded {
                    Button(action: {
                        selectedTab = "world"
                        showMenu = false
                    }) {
                        HStack {
                            Text("World")
                            Spacer()
                        }
                    }
                    .foregroundColor(selectedTab == "world" ? .black : .orange)
                    .padding(.leading, 20)

                    Button(action: {
                        selectedTab = "turkey"
                        showMenu = false
                    }) {
                        HStack {
                            Text("Türkiye")
                            Spacer()
                        }
                    }
                    .foregroundColor(selectedTab == "turkey" ? .black : .orange)
                    .padding(.leading, 20)
                }
            }
            
            Button("Settings") {
                showSettings = true
                showMenu = false  // Add this line to close the menu
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
        .background(
            Color.white.opacity(0.2)
                .background(.ultraThinMaterial)
                .blur(radius: 1)
        )
        .edgesIgnoringSafeArea(.vertical)
    }
}

