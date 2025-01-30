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
}
