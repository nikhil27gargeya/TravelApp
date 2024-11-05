import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class FriendManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var friends: [Friend] = [] // Published property to update UI when it changes
    private var groupId: String

    init(groupId: String) {
        self.groupId = groupId
        loadFriends()
    }

    // Load friends from user collection based on member IDs from the group document
    func loadFriends() {
        // Get the group document and fetch the members array
        let groupRef = db.collection("groups").document(groupId)
        
        groupRef.getDocument { document, error in
            if let error = error {
                print("Error fetching group document: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists,
                  let data = document.data(),
                  let memberIds = data["members"] as? [String] else {
                print("No members found in the group document")
                return
            }

            self.fetchFriendsDetails(memberIds: memberIds)
        }
    }

    // Fetch user details for each member ID from "users" collection
    private func fetchFriendsDetails(memberIds: [String]) {
        // Clear the friends list before reloading
        self.friends = []

        let usersCollection = db.collection("users")

        let dispatchGroup = DispatchGroup() // To manage multiple asynchronous operations

        for memberId in memberIds {
            dispatchGroup.enter()
            usersCollection.document(memberId).getDocument { document, error in
                defer { dispatchGroup.leave() }

                if let error = error {
                    print("Error fetching user document for memberId \(memberId): \(error.localizedDescription)")
                    return
                }

                guard let document = document, document.exists else {
                    print("No user document found for memberId \(memberId)")
                    return
                }

                // Create a Friend instance from the fetched document
                if let name = document.data()?["name"] as? String {
                    let friend = Friend(id: UUID(uuidString: memberId) ?? UUID(), name: name, share: 0.0, balance: 0.0)
                    DispatchQueue.main.async {
                        self.friends.append(friend)
                    }
                }
            }
        }

        // Notify when all friends have been loaded
        dispatchGroup.notify(queue: .main) {
            if self.friends.isEmpty {
                print("Friends list is empty after fetching all member details.")
            } else {
                print("Successfully loaded friends: \(self.friends)")
            }
        }
    }
}
