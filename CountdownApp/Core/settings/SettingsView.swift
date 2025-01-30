import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingPasswordChange = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordsMatch: Bool = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Button("Change Password") {
                        showingPasswordChange = true
                    }
                }

                Section("App") {
                    NavigationLink("About") {
                        AboutView()
                    }
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("Terms of Service") {
                        TermsOfServiceView()
                    }
                }

                // Reserved section for future subscription features
                Section("Subscription") {
                    Text("Coming soon")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPasswordChange) {
                NavigationStack {
                    Form {
                        Section {
                            SecureField("Current Password", text: $currentPassword)
                            SecureField("New Password", text: $newPassword)
                                .onChange(of: newPassword) { _ in
                                    passwordsMatch = !newPassword.isEmpty && newPassword == confirmPassword
                                }
                            SecureField("Confirm New Password", text: $confirmPassword)
                                .onChange(of: confirmPassword) { _ in
                                    passwordsMatch = !newPassword.isEmpty && newPassword == confirmPassword
                                }
                            
                            if !newPassword.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords do not match")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                    .navigationTitle("Change Password")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingPasswordChange = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Update") {
                                viewModel.changePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword,
                                    confirmPassword: confirmPassword
                                ) { success in
                                    isSuccess = success
                                    alertTitle = success ? "Success" : "Error"
                                    alertMessage = success ? "Password successfully updated" : (viewModel.error ?? "An error occurred")
                                    showAlert = true
                                    if success {
                                        currentPassword = ""
                                        newPassword = ""
                                        confirmPassword = ""
                                        showingPasswordChange = false
                                    }
                                }
                            }
                            .disabled(!passwordsMatch || currentPassword.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        Text("About the app")
            .navigationTitle("About")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy content")
            .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("Terms of Service content")
            .navigationTitle("Terms of Service")
    }
}
