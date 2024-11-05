import FirebaseFirestore
import FirebaseFirestoreSwift

class ExpenseManager {
    private let db = Firestore.firestore()

    func saveUserExpense(userExpense: UserExpense) {
        do {
            try db.collection("userExpenses").document(userExpense.id.uuidString).setData(from: userExpense)
            print("User expense saved successfully.")
        } catch {
            print("Error adding user expense: \(error)")
        }
    }

    func fetchUserExpense(id: UUID, completion: @escaping (Result<UserExpense, Error>) -> Void) {
        db.collection("userExpenses").document(id.uuidString).getDocument(as: UserExpense.self) { result in
            switch result {
            case .success(let userExpense):
                completion(.success(userExpense))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
