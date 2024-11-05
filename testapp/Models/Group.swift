import Foundation
import FirebaseFirestoreSwift

struct Group: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID
    var name: String
    var members: [String] // Array of user IDs (or emails) for group members
    var createdAt: Date
    var code: String
    
}
