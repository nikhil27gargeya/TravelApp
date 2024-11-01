import SwiftUI

struct HomeView: View {
    @State private var totalExpense: Double = 0.0
    @State private var selectedCurrency: String = UserDefaults.standard.string(forKey: "currency") ?? "USD"
    @State private var friends: [Friend] = loadFriends()
    @State private var newFriendName: String = ""
    @State private var jokes: String = ""
    @State private var inputText: String = ""

    var body: some View {
        VStack {
            // Total Expense Display
            Text("Total Expenses: \(selectedCurrency) \(totalExpense, specifier: "%.2f")")
                .font(.largeTitle)
                .padding()

            // Friends List
            VStack(alignment: .leading) {
                Text("Friends")
                    .font(.headline)
                
                List {
                    ForEach(friends) { friend in
                        Text(friend.name)
                    }
                    .onDelete(perform: deleteFriend)
                }
                
            
                HStack {
                    TextField("Add Friend", text: $newFriendName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addFriend) {
                        Image(systemName: "plus")
                    }
                    .disabled(newFriendName.isEmpty)
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            selectedCurrency = UserDefaults.standard.string(forKey: "currency") ?? "USD"
        }
    }
    
    private func addFriend() {
        guard !newFriendName.isEmpty else { return } // Check that the name isn't empty
        let newFriend = Friend(name: newFriendName, share: 0) // Provide a share value (default to 0)
        friends.append(newFriend)
        newFriendName = ""
        saveFriends(friends) // Save the updated friends list
    }

    private func deleteFriend(at offsets: IndexSet) {
        friends.remove(atOffsets: offsets)
        saveFriends(friends)  // Save the updated friends list
    }
}

func loadFriends() -> [Friend] {
    if let data = UserDefaults.standard.data(forKey: "friends"),
       let savedFriends = try? JSONDecoder().decode([Friend].self, from: data) {
        return savedFriends
    }
    return []
}

func saveFriends(_ friends: [Friend]) {  // Accept friends as a parameter
    if let data = try? JSONEncoder().encode(friends) {
        UserDefaults.standard.set(data, forKey: "friends")
    }
}
