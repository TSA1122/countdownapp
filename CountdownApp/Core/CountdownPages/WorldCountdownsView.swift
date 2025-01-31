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
        ScrollView {
            if worldCountdowns.isEmpty {
                EmptyStateView(message: "No world countdowns available")
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(worldCountdowns, id: \.id) { countdown in
                        CountdownCard(countdown: countdown,
                                    isFavorited: viewModel.favoritedCountdowns.contains(countdown.id),
                                    onFavorite: { toggleFavorite(countdown) },
                                    timeComponents: calculateTimeRemaining(until: countdown.date))
                            .transition(.scale)
                    }
                }
                .padding()
            }
        }
        .background(Color.gray.opacity(0.05))
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

struct CountdownCard: View {
    let countdown: Countdown
    let isFavorited: Bool
    let onFavorite: () -> Void
    let timeComponents: (years: Int, days: Int, hours: Int, minutes: Int)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(countdown.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                FavoriteButton(isFavorited: isFavorited, action: onFavorite)
            }
            .padding()
            
            // Time components
            HStack(spacing: 12) {
                if timeComponents.years > 0 {
                    TimeBoxView(value: timeComponents.years, unit: "Years")
                }
                TimeBoxView(value: timeComponents.days, unit: "Days")
                TimeBoxView(value: timeComponents.hours, unit: "Hours")
                TimeBoxView(value: timeComponents.minutes, unit: "Minutes")
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

struct FavoriteButton: View {
    let isFavorited: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorited ? "star.fill" : "star")
                .foregroundColor(isFavorited ? .yellow : .gray)
                .font(.title3)
        }
        .scaleEffect(isFavorited ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorited)
    }
}

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
