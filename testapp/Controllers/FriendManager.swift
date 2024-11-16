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
        
        groupRef.getDocument { [weak self] document, error in
            guard let self = self else { return } // Prevent memory leak

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
        let usersCollection = db.collection("users")

        // Use DispatchGroup to handle multiple async calls
        let dispatchGroup = DispatchGroup()

        // Temporary array to store fetched friends
        var fetchedFriends: [Friend] = []

        for memberId in memberIds {
            dispatchGroup.enter()

            usersCollection.document(memberId).getDocument { document, error in
                defer { dispatchGroup.leave() }

                if let error = error {
                    print("Error fetching user document for memberId \(memberId): \(error.localizedDescription)")
                    return
                }

                guard let document = document, document.exists,
                      let data = document.data(),
                      let name = data["name"] as? String else {
                    print("No user document found or data missing for memberId \(memberId)")
                    return
                }

                // Create a Friend instance from the fetched document
                let friend = Friend(id: UUID(), name: name, share: 0.0, balance: 0.0)
                fetchedFriends.append(friend)
            }
        }

        // Once all data is fetched, update the main `friends` list on the main queue
        dispatchGroup.notify(queue: .main) {
            self.friends.removeAll() // Clear the friends list before reloading
            self.friends = fetchedFriends

    //        if self.friends.isEmpty {
    //            print("Friends list is empty after fetching all member details.")
    //        } else {
    //            print("Successfully loaded friends: \(self.friends)")
    //        }
        
        }
    }
}
