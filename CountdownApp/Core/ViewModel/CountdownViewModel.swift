import Foundation
import FirebaseAuth
import FirebaseFirestore

class CountdownViewModel: ObservableObject {
    @Published var userCountdowns: [Countdown] = []
    @Published var favoritedCountdowns: Set<String> = []
    
    func fetchUserCountdowns() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("user_countdowns").document(userId).getDocument { [weak self] snapshot, error in
            guard let document = snapshot,
                  let countdownRefs = document.data()?["countdowns"] as? [String: [String: Any]] else { return }
            
            let group = DispatchGroup()
            var fetchedCountdowns: [Countdown] = []
            
            for (id, data) in countdownRefs {
                guard let collectionPath = data["collection"] as? String else { continue }
                
                group.enter()
                db.collection(collectionPath).document(id).getDocument { snapshot, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error fetching countdown reference: \(error)")
                        return
                    }
                    
                    if let doc = snapshot,
                       let name = doc.data()?["name"] as? String,
                       let timestamp = doc.data()?["date"] as? Timestamp {
                        let countdown = Countdown(id: id, name: name, date: timestamp.dateValue())
                        fetchedCountdowns.append(countdown)
                    }
                }
            }
            
            group.notify(queue: .main) {
                self?.userCountdowns = fetchedCountdowns
                self?.favoritedCountdowns = Set(countdownRefs.keys)
            }
        }
    }
    
    func removeCountdown(countdownId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("user_countdowns").document(userId).updateData([
            "countdowns.\(countdownId)": FieldValue.delete()
        ]) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.userCountdowns.removeAll { $0.id == countdownId }
                    self?.favoritedCountdowns.remove(countdownId)
                }
            }
        }
    }
}
