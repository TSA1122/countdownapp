import Foundation
import FirebaseAuth

class SettingsViewModel: ObservableObject {
    @Published var error: String?
    @Published var isLoading = false
    
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String, completion: @escaping (Bool) -> Void) {
        guard newPassword == confirmPassword else {
            error = "New passwords don't match"
            completion(false)
            return
        }
        
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            error = "User not found"
            completion(false)
            return
        }
        
        isLoading = true
        
        // Reauthenticate user before changing password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                self?.error = "Current password is incorrect"
                self?.isLoading = false
                completion(false)
                return
            }
            
            // Change password
            user.updatePassword(to: newPassword) { [weak self] error in
                self?.isLoading = false
                if let error = error {
                    self?.error = "Failed to update password: \(error.localizedDescription)"
                    completion(false)
                } else {
                    self?.error = nil
                    completion(true)
                }
            }
        }
    }
    
    func deleteAccount(password: String) async -> (Bool, String) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            error = "User not found"
            return (false, "User not found")
        }
        
        isLoading = true
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            do {
                try await user.reauthenticate(with: credential)
            } catch {
                self.error = "Incorrect password. Please try again."
                isLoading = false
                return (false, "Incorrect password. Please try again.")
            }
            
            let authViewModel = AuthViewModel()
            let success = try await authViewModel.deleteAccount()
            
            isLoading = false
            return (success, success ? "Account successfully deleted" : "Failed to delete account")
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return (false, error.localizedDescription)
        }
    }
}
