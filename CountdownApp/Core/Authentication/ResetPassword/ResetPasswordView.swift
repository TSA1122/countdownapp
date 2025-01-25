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
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter your email address and we'll send you a link to reset your password.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!isFormValid)
            
            Button(action: {
                dismiss()
            }) {
                Text("Back to Login")
                    .foregroundColor(.blue)
            }
        }
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
        .padding()
    }
}
