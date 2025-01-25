import SwiftUI
import FirebaseFirestore

struct Countdown {
    let name: String
    let date: Date
}

struct TimeBoxView: View {
    let value: Int
    let unit: String
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title2)
                .bold()
            Text(unit)
                .font(.caption)
        }
        .frame(width: 70, height: 70)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct TurkiyeCountdownsView: View {
    @State private var turkiyeCountdowns: [Countdown] = []
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if turkiyeCountdowns.isEmpty {
                Text("No Türkiye countdowns available")
                    .foregroundColor(.gray)
            } else {
                List(turkiyeCountdowns, id: \.name) { countdown in
                    HStack {
                        Spacer()
                        VStack(alignment: .center, spacing: 16) {
                            Text(countdown.name)
                                .font(.headline)
                            
                            let components = calculateTimeRemaining(until: countdown.date)
                            HStack(spacing: 20) {
                                TimeBoxView(value: components.days, unit: "Days")
                                TimeBoxView(value: components.hours, unit: "Hours")
                                TimeBoxView(value: components.minutes, unit: "Minutes")
                            }
                        }
                        .padding(.vertical, 24)  // Increased from 16 to 24
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))  // Added spacing between items
                }
                .listRowSpacing(16)
            }
        }
        .onAppear {
            fetchTurkiyeCountdowns()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func calculateTimeRemaining(until targetDate: Date) -> (days: Int, hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], 
                                              from: currentTime, 
                                              to: targetDate)
        return (
            days: max(components.day ?? 0, 0),
            hours: max(components.hour ?? 0, 0),
            minutes: max(components.minute ?? 0, 0)
        )
    }
    
    private func fetchTurkiyeCountdowns() {
        let db = Firestore.firestore()
        db.collection("turkiye_specific_countdowns").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching Türkiye countdowns: \(error)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.turkiyeCountdowns = documents.compactMap { document in
                    guard let name = document.data()["name"] as? String,
                          let timestamp = document.data()["date"] as? Timestamp else {
                        return nil
                    }
                    return Countdown(name: name, date: timestamp.dateValue())
                }
            }
        }
    }
}
