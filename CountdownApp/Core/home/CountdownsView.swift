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
                    .background(Color.blue.opacity(0.3))
                ZStack {
                    // Background gradient
                    LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    if selectedTab == "turkey" {
                        TurkiyeCountdownsView(viewModel: viewModel)
                            .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                  removal: .move(edge: .leading)))
                    } else if selectedTab == "world" {
                        WorldCountdownsView(viewModel: viewModel)
                            .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                  removal: .move(edge: .leading)))
                    } else {
                        if viewModel.userCountdowns.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue.opacity(0.5))
                                Text("No favorite countdowns yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            List {
                                // Add spacing view as first item
                                Color.clear
                                    .frame(height: 0)  // Decreased from 2
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets())
                                
                                // Sort countdowns by date and display them
                                ForEach(viewModel.userCountdowns.sorted(by: { $0.date < $1.date }), id: \.id) { countdown in
                                    ZStack(alignment: .topTrailing) {
                                        // Updated card background with new gradient
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.blue.opacity(0.15),
                                                    Color.blue.opacity(0.08)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing))
                                            .shadow(color: Color.blue.opacity(0.1), radius: 5, x: 0, y: 2)
                                        
                                        // Delete button in edit mode
                                        if isEditMode {
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.removeCountdown(countdownId: countdown.id)
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.title2)
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .offset(x: 10, y: -10)
                                            .transition(.scale)
                                        }
                                        
                                        // Countdown content
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
                                        .padding()
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .padding(.vertical, 6)  // Added vertical padding
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                    
                    // Menu overlay
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            MenuView(selectedTab: $selectedTab, showMenu: $showMenu)
                                .frame(width: geometry.size.width * 0.7, height: UIScreen.main.bounds.height)
                                .offset(x: showMenu ? 0 : -geometry.size.width * 0.7)
                                .animation(.default, value: showMenu)
                            
                            Spacer()
                        }
                    }
                    .ignoresSafeArea()
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

// Update MenuView with modern design
struct MenuView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var selectedTab: String
    @Binding var showMenu: Bool
    @State private var isCountdownsSectionExpanded = true
    @State private var showSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Menu items section
            MenuItemView(title: "My Countdowns", 
                       isSelected: selectedTab == "main",
                       action: {
                           selectedTab = "main"
                           showMenu = false
                       })
            
            // Countdowns Section with submenu and arrow
            VStack(alignment: .leading, spacing: 12) {
                MenuItemView(title: "Countdowns", 
                           isSelected: false,
                           action: {
                               withAnimation {
                                   isCountdownsSectionExpanded.toggle()
                               }
                           },
                           showArrow: true,
                           isExpanded: isCountdownsSectionExpanded)
                
                if isCountdownsSectionExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        MenuItemView(title: "    World", 
                                   isSelected: selectedTab == "world",
                                   action: {
                                       selectedTab = "world"
                                       showMenu = false
                                   })
                        MenuItemView(title: "    Türkiye", 
                                   isSelected: selectedTab == "turkey",
                                   action: {
                                       selectedTab = "turkey"
                                       showMenu = false
                                   })
                    }
                    .transition(.opacity)
                }
            }
            
            MenuItemView(title: "Settings", 
                       isSelected: showSettings,
                       action: {
                           showSettings = true
                           showMenu = false
                       })
            
            // Logout button moved here
            Button(action: { authViewModel.signOut() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.8))
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color.white.opacity(0.2)
                BackgroundBlurView()
            }
        )
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct MenuItemView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var showArrow: Bool = false
    var isExpanded: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .fontWeight(isSelected ? .bold : .regular)
                Spacer()
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(), value: isExpanded)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .foregroundColor(isSelected ? .blue : .primary)
    }
}

struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

