import SwiftUI
import Firebase

struct HomeView: View {
    @State private var totalExpense: Double = 0.0
    @State private var selectedCurrency: String = UserDefaults.standard.string(forKey: "currency") ?? "USD"
    
    @StateObject private var friendManager: FriendManager

    init(groupId: String) {
        _friendManager = StateObject(wrappedValue: FriendManager(groupId: groupId))
    }

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(friendManager.friends) { friend in
                        Text(friend.name)
                    }
                }
                .navigationTitle("Friends in Group")
                .onAppear {
                    friendManager.loadFriends()
                }
            }
        }
    }
}
