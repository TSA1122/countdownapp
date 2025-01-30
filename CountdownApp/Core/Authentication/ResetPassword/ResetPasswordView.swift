import SwiftUI

struct ResetPasswordView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var showError = false
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    private var isFormValid: Bool {
        !email.isEmpty
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
                    // Header and description
                    VStack(spacing: 15) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 4)
                        
                        Text("Reset Password")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Email input field
                    VStack(spacing: 20) {
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
                    }
                    .padding(.horizontal)
                    
                    // Reset button
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.resetPassword(email: email)
                                showSuccess = true
                            } catch {
                                viewModel.error = error.localizedDescription
                                showError = true
                            }
                        }
                    }) {
                        Text("Send Reset Link")
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
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Password reset link has been sent to your email.")
        }
    }
}
