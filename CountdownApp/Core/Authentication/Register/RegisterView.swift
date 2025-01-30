//
//  RegisterView.swift
//  CountdownApp
//
//  Created by Taha Samet Aydil on 16.01.2025.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
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
                    // Header and welcome text
                    VStack(spacing: 15) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 4)
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("Please fill in your details")
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
                        
                        // Confirm Password field
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.gray)
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    // Register button
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.createUser(withEmail: email, password: password)
                                dismiss()
                            } catch {
                                viewModel.error = error.localizedDescription
                                showError = true
                            }
                        }
                    }) {
                        Text("Create Account")
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
                    
                    // Back to login
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Back to Login")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
    }
}

