import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var error: String?
    
    init() {
        self.userSession = Auth.auth().currentUser
        
        // Setup auth state listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }
    
    func createUser(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            try await createUserDocument(for: result.user)
            self.userSession = result.user  
        } catch {
            throw error
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
        } catch {
            self.error = handleAuthError(error)
            throw error
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw error
        }
    }
    
    private func createUserDocument(for user: FirebaseAuth.User) async throws {
        let db = Firestore.firestore()
        try await db.collection("user_countdowns").document(user.uid).setData([
            "userId": user.uid,
            "email": user.email ?? "",
            "countdowns": [:],  // Changed from [] to {} in Firestore
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    func deleteAccount() async throws -> Bool {
        guard let user = Auth.auth().currentUser else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]) }
        
        let db = Firestore.firestore()
        do {
            // Delete user document and countdowns
            try await db.collection("user_countdowns").document(user.uid).delete()
            
            // Delete the user account
            try await user.delete()
            self.userSession = nil
            return true
        } catch {
            throw error
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let authError = error as NSError
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address format."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account exists with this email."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered."
        case AuthErrorCode.invalidCredential.rawValue:
            return "Email or password is incorrect."
        default:
            return error.localizedDescription
        }
    }
}
