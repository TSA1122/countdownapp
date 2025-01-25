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
        VStack(spacing: 20) {
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                Task {
                    do {
                        try await viewModel.signIn(withEmail: email, password: password)
                    } catch {
                        viewModel.error = error.localizedDescription
                        showError = true
                    }
                }
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!isFormValid)
            
            NavigationLink(destination: RegisterView()) {
                Text("Don't have an account? Register")
                    .foregroundColor(.blue)
            }
            
            NavigationLink(destination: ResetPasswordView()) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
        .padding()
    }
}

