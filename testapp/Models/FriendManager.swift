import FirebaseFirestore
import Combine

class FriendManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var friends: [Friend] = [] // Observable list of friends
    private var groupId: String

    init(groupId: String) {
        self.groupId = groupId
        fetchFriends() // Load friends on initialization
    }

    // Function to add a friend to a specific group
    func addFriend(_ friend: Friend, to groupId: String) {
        let friendData: [String: Any] = [
            "id": friend.id.uuidString, // Store UUID as a String
            "name": friend.name,
            "share": friend.share,
            "balance": friend.balance
        ]
        
        db.collection("groups").document(groupId).collection("friends").document(friend.id.uuidString).setData(friendData) { error in
            if let error = error {
                print("Error adding friend: \(error)")
            } else {
                print("Friend added successfully!")
                self.fetchFriends() // Reload friends after adding
            }
        }
    }

    // Function to fetch friends for the assigned groupId
    func fetchFriends() {
        db.collection("groups").document(groupId).collection("friends").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching friends: \(error)")
                return
            }

            var loadedFriends: [Friend] = []
            for document in snapshot!.documents {
                if let friend = try? document.data(as: Friend.self) {
                    loadedFriends.append(friend)
                }
            }
            self.friends = loadedFriends // Update the published friends list
        }
    }

    // Function to update a friend's balance
    func updateFriendBalance(friendId: String, newBalance: Double) {
        db.collection("groups").document(groupId).collection("friends").document(friendId).updateData(["balance": newBalance]) { error in
            if let error = error {
                print("Error updating balance: \(error)")
            } else {
                print("Balance updated successfully!")
            }
        }
    }

    // Function to delete a friend
    func deleteFriend(friendId: String) {
        db.collection("groups").document(groupId).collection("friends").document(friendId).delete { error in
            if let error = error {
                print("Error deleting friend: \(error)")
            } else {
                print("Friend deleted successfully!")
                self.fetchFriends() // Reload friends after deletion
            }
        }
    }
}
