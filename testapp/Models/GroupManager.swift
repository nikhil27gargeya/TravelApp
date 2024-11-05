import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class GroupManager: ObservableObject {
    private let db = Firestore.firestore()
    private var userId: String // Assuming user authentication will provide a unique ID
    @Published var groups: [Group] = []

    init(userId: String) {
        self.userId = userId
        loadGroups()
    }

    // Load groups that the user is a part of
    func loadGroups() {
        db.collection("groups")
            .whereField("members", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading groups: \(error)")
                    return
                }
                
                self.groups = snapshot?.documents.compactMap { document in
                    try? document.data(as: Group.self)
                } ?? []
            }
    }

    // Generate a random code for joining a group
    private func generateUniqueCode(completion: @escaping (String) -> Void) {
        let codeLength = 5
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        func createCode() -> String {
            return String((0..<codeLength).compactMap { _ in characters.randomElement() })
        }

        func checkCodeUniqueness(_ code: String) {
            db.collection("groups").whereField("code", isEqualTo: code).getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking code uniqueness: \(error)")
                    completion(createCode()) // Fallback to a new code on error
                    return
                }
                
                if snapshot?.isEmpty == true {
                    completion(code) // Code is unique
                } else {
                    checkCodeUniqueness(createCode()) // Recursively generate a new code
                }
            }
        }

        checkCodeUniqueness(createCode())
    }

    // Create a new group with a unique code
    func createGroup(name: String) {
        generateUniqueCode { uniqueCode in
            let newGroup = Group(name: name, members: [self.userId], createdAt: Date(), code: uniqueCode)
            
            do {
                let _ = try self.db.collection("groups").addDocument(from: newGroup) { error in
                    if let error = error {
                        print("Error creating group: \(error)")
                    } else {
                        print("Group created successfully!")
                    }
                }
            } catch {
                print("Error encoding group: \(error)")
            }
        }
    }

    // Join an existing group using the code
    func joinGroup(withCode code: String) {
        db.collection("groups").whereField("code", isEqualTo: code).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding group by code: \(error)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("Group with code \(code) not found.")
                return
            }
            
            let groupRef = document.reference
            groupRef.updateData([
                "members": FieldValue.arrayUnion([self.userId])
            ]) { error in
                if let error = error {
                    print("Error joining group: \(error)")
                } else {
                    print("Joined group successfully!")
                }
            }
        }
    }
}
