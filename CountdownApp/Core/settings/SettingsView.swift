import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
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
    @State private var showingDeleteAccount = false
    @State private var deleteAccountPassword = ""
    @State private var showingDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var showSuccessAlert = false
    @State private var successMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Button("Change Password") {
                        showingPasswordChange = true
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete Account")
                    }
                }

                Section("Remainder App") {
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
            .sheet(isPresented: $showingDeleteAccount) {
                NavigationStack {
                    Form {
                        Section {
                            SecureField("Enter Password to Confirm", text: $deleteAccountPassword)
                        } header: {
                            Text("This action cannot be undone. All your data will be permanently deleted.")
                        }
                    }
                    .navigationTitle("Delete Account")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingDeleteAccount = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    let (success, message) = await viewModel.deleteAccount(password: deleteAccountPassword)
                                    if success {
                                        successMessage = message
                                        showSuccessAlert = true
                                    } else {
                                        deleteErrorMessage = message
                                        showDeleteError = true
                                    }
                                }
                            }
                            .disabled(deleteAccountPassword.isEmpty)
                        }
                    }
                    .alert("Error", isPresented: $showDeleteError) {
                        Button("OK") { }
                    } message: {
                        Text(deleteErrorMessage)
                    }
                    .alert("Success", isPresented: $showSuccessAlert) {
                        Button("OK") {
                            showingDeleteAccount = false
                            dismiss()  // Dismiss settings view
                        }
                    } message: {
                        Text(successMessage)
                    }
                }
                .presentationDetents([.medium])
            }
            .confirmationDialog(
                "Are you sure you want to delete your account?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    showingDeleteAccount = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone")
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
    @State private var aboutContent: String = ""
    
    var body: some View {
        ScrollView {
            if let attributedString = try? AttributedString(
                markdown: aboutContent,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            ) {
                Text(attributedString)
                    .padding()
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Failed to load content")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("About")
        .onAppear {
            loadAboutContent()
        }
    }
    
    private func loadAboutContent() {
        guard let path = Bundle.main.path(forResource: "about", ofType: "md"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            aboutContent = "Error loading content"
            return
        }
        aboutContent = content
    }
}

struct PrivacyPolicyView: View {
    @State private var privacyContent: String = ""
    
    var body: some View {
        ScrollView {
            if let attributedString = try? AttributedString(
                markdown: privacyContent,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            ) {
                Text(attributedString)
                    .padding()
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Failed to load content")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Privacy Policy")
        .onAppear {
            loadPrivacyContent()
        }
    }
    
    private func loadPrivacyContent() {
        guard let path = Bundle.main.path(forResource: "privacy_policy", ofType: "md"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            privacyContent = "Error loading privacy policy content"
            return
        }
        privacyContent = content
    }
}

struct TermsOfServiceView: View {
    @State private var termsContent: String = ""
    
    var body: some View {
        ScrollView {
            if let attributedString = try? AttributedString(
                markdown: termsContent,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            ) {
                Text(attributedString)
                    .padding()
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Failed to load content")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Terms of Service")
        .onAppear {
            loadTermsContent()
        }
    }
    
    private func loadTermsContent() {
        guard let path = Bundle.main.path(forResource: "terms_of_use", ofType: "md"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            termsContent = "Error loading terms of service content"
            return
        }
        termsContent = content
    }
}
