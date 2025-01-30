import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct WorldCountdownsView: View {
    @ObservedObject var viewModel: CountdownViewModel
    @State private var worldCountdowns: [Countdown] = []
    @State private var currentTime = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if worldCountdowns.isEmpty {
                Text("No world countdowns available")
                    .foregroundColor(.gray)
            } else {
                List(worldCountdowns, id: \.id) { countdown in
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 16)  // Reduced from default Spacer height
                        ZStack {
                            Text(countdown.name)
                                .font(.headline)
                                .frame(maxWidth: .infinity)  // Added to center text
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    toggleFavorite(countdown)
                                }) {
                                    Image(systemName: viewModel.favoritedCountdowns.contains(countdown.id) ? "star.fill" : "star")
                                        .foregroundColor(viewModel.favoritedCountdowns.contains(countdown.id) ? .yellow : .gray)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(height: 24)  // Adjusted middle spacing
                        
                        let components = calculateTimeRemaining(until: countdown.date)
                        HStack(spacing: 20) {
                            if components.years > 0 {
                                TimeBoxView(value: components.years, unit: "Years")
                            }
                            TimeBoxView(value: components.days, unit: "Days")
                            TimeBoxView(value: components.hours, unit: "Hours")
                            TimeBoxView(value: components.minutes, unit: "Minutes")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)  // Added to center HStack
                        .padding(.bottom, 16)  // Reduced bottom padding
                    }
                    .frame(height: 160)  // Reduced overall height
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))  // Reduced top/bottom insets
                }
                .listRowSpacing(16)
            }
        }
        .alert("Premium Feature", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            fetchWorldCountdowns()
            fetchUserFavorites()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func calculateTimeRemaining(until targetDate: Date) -> (years: Int, days: Int, hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .day, .hour, .minute], 
                                              from: currentTime, 
                                              to: targetDate)
        
        // Calculate total years and remaining days
        let years = max(components.year ?? 0, 0)
        let days = max(components.day ?? 0, 0)
        
        return (
            years: years,
            days: days,
            hours: max(components.hour ?? 0, 0),
            minutes: max(components.minute ?? 0, 0)
        )
    }
    
    private func fetchWorldCountdowns() {
        let db = Firestore.firestore()
        db.collection("world_countdowns").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching world countdowns: \(error)")
                return
            }
            
            if let documents = snapshot?.documents {
                // Filter and handle expired countdowns
                let now = Date()
                var expiredIds: [String] = []
                
                self.worldCountdowns = documents.compactMap { document in
                    guard let name = document.data()["name"] as? String,
                          let timestamp = document.data()["date"] as? Timestamp else {
                        return nil
                    }
                    
                    let date = timestamp.dateValue()
                    if date <= now {
                        expiredIds.append(document.documentID)
                        return nil
                    }
                    return Countdown(id: document.documentID, name: name, date: date)
                }
                
                // Delete expired countdowns
                if !expiredIds.isEmpty {
                    for id in expiredIds {
                        db.collection("world_countdowns").document(id).delete { error in
                            if let error = error {
                                print("Error deleting expired countdown: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchUserFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("user_countdowns").document(userId).getDocument { snapshot, error in
            if let document = snapshot,
               let countdowns = document.data()?["countdowns"] as? [String: [String: Any]] {
                self.viewModel.favoritedCountdowns = Set(countdowns.keys)
            }
        }
    }
    
    private func toggleFavorite(_ countdown: Countdown) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if !viewModel.favoritedCountdowns.contains(countdown.id) && viewModel.favoritedCountdowns.count >= 5 {
            errorMessage = "You can only add up to 5 countdowns to favorites. Upgrade to premium for unlimited favorites!"
            showError = true
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("user_countdowns").document(userId)
        
        if viewModel.favoritedCountdowns.contains(countdown.id) {
            viewModel.favoritedCountdowns.remove(countdown.id)
            userRef.updateData([
                "countdowns.\(countdown.id)": FieldValue.delete()
            ]) { error in
                if let error = error {
                    print("Error removing favorite: \(error)")
                }
                viewModel.fetchUserCountdowns()
            }
        } else {
            viewModel.favoritedCountdowns.insert(countdown.id)
            let reference: [String: Any] = [
                "collection": "world_countdowns",
                "addedAt": FieldValue.serverTimestamp()
            ]
            userRef.updateData([
                "countdowns.\(countdown.id)": reference
            ]) { error in
                if let error = error {
                    print("Error adding favorite: \(error)")
                }
                viewModel.fetchUserCountdowns()
            }
        }
    }
}
