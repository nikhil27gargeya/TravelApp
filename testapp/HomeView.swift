import SwiftUI
import Firebase

struct HomeView: View {
    @State private var totalExpense: Double = 0.0
    @State private var selectedCurrency: String = UserDefaults.standard.string(forKey: "currency") ?? "USD"
    @State private var newFriendName: String = ""
    
    @StateObject private var friendManager = FriendManager(groupId: "groupId123") // Initialize with the group ID

    var body: some View {
        NavigationView {
            VStack {
                // Total Expense Display
                Text("Total Expenses: \(selectedCurrency) \(totalExpense, specifier: "%.2f")")
                    .font(.largeTitle)
                    .padding()

                // Friends List
                List {
                    ForEach(friendManager.friends) { friend in
                        Text(friend.name)
                    }
                    .onDelete(perform: deleteFriend)
                }
                .navigationTitle("Friends")

                // Add New Friend
                HStack {
                    TextField("Add Friend", text: $newFriendName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: addFriend) {
                        Image(systemName: "plus")
                            .padding()
                    }
                    .disabled(newFriendName.isEmpty)
                }
                .padding()
            }
        }
    }
    
    private func addFriend() {
        guard !newFriendName.isEmpty else { return } // Check that the name isn't empty
        let newFriend = Friend(name: newFriendName, share: 0) // Provide a share value (default to 0)

        // Add friend to Firestore
        friendManager.addFriend(newFriend, to: "groupId123") // Replace with your actual group ID
        
        newFriendName = "" // Clear input field
    }

    private func deleteFriend(at offsets: IndexSet) {
        for index in offsets {
            let friend = friendManager.friends[index]
            // Remove friend from Firestore
            friendManager.deleteFriend(friendId: friend.id.uuidString) // Replace with your actual group ID
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
