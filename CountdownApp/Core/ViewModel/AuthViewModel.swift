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
}
