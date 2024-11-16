import SwiftUI
import Firebase

struct HomeView: View {
    @State private var totalExpense: Double = 0.0
    @State private var selectedCurrency: String = UserDefaults.standard.string(forKey: "currency") ?? "USD"
    
    @StateObject private var friendManager: FriendManager
    var tripName: String

    init(groupId: String, tripName: String) {
           _friendManager = StateObject(wrappedValue: FriendManager(groupId: groupId))
           self.tripName = tripName  // Initialize the trip name
       }

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Text("Members")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.top)
                        .frame(alignment: .leading)
                    ForEach(friendManager.friends) { friend in
                        Text(friend.name)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(tripName)
                .onAppear {
                    friendManager.loadFriends()
                }
            }
        }
    }
}
