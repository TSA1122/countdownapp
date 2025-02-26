//
//  LoginView.swift
//  CountdownApp
//
//  Created by Taha Samet Aydil on 16.01.2025.
//


import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Logo and Welcome text
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 4)
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("Please sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // Input fields
                    VStack(spacing: 20) {
                        // Email field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                            TextField("Email", text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
                        
                        // Password field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            SecureField("Password", text: $password)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    // Login button
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.signIn(withEmail: email, password: password)
                            } catch {
                                showError = true
                            }
                        }
                    }) {
                        Text("Sign In")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isFormValid ?
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                             startPoint: .leading,
                                             endPoint: .trailing) :
                                LinearGradient(colors: [.gray, .gray],
                                             startPoint: .leading,
                                             endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(color: isFormValid ? .blue.opacity(0.3) : .clear,
                                    radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .disabled(!isFormValid)
                    
                    // Secondary actions
                    VStack(spacing: 15) {
                        NavigationLink(destination: RegisterView()) {
                            Text("New user? Create an account")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        NavigationLink(destination: ResetPasswordView()) {
                            Text("Forgot Password?")
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
    }
}

