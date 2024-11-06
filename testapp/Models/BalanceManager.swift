import SwiftUI
import Combine
import Firebase

class BalanceManager: ObservableObject {
    @Published var balances: [String: Double] = [:]
    @Published var owedStatements: [OweStatement] = []
    private var db = Firestore.firestore()
    public var groupId: String

    init(groupId: String) {
        self.groupId = groupId
        loadBalances() // Load balances and owed statements on initialization
    }

    func updateBalances(with expenses: [String: Double], payer: String) {
        DispatchQueue.main.async {
            for (friend, amount) in expenses {
                guard amount != 0 else { continue }
                
                if friend != payer {
                    // Safely update balances
                    self.balances[friend, default: 0.0] += amount
                    self.balances[payer, default: 0.0] -= amount
                    
                    // Avoid duplicate owed statements
                    if let existingIndex = self.owedStatements.firstIndex(where: {
                        $0.debtor == friend && $0.creditor == payer
                    }) {
                        // Update existing statement amount
                        self.owedStatements[existingIndex].amount += amount
                    } else {
                        // Add new owed statement
                        self.owedStatements.append(OweStatement(debtor: friend, creditor: payer, amount: amount))
                    }
                }
            }

            // Save balances after updating
            self.saveBalances()
            print("Balances updated: \(self.balances)")
            print("Owed statements updated: \(self.owedStatements)")
        }
    }


    func resetBalances() {
        balances.removeAll()
        owedStatements.removeAll()
        saveBalances() // Save reset state
        print("Balances and owed statements reset.")
    }

    // MARK: - Firestore Methods

    private func saveBalances() {
        let balancesData = balances.mapValues { $0 } // Convert to [String: Double] if necessary

        // Save balances to Firestore
        db.collection("balances").document(groupId).setData(["balances": balancesData]) { error in
            if let error = error {
                print("Error saving balances: \(error.localizedDescription)")
            } else {
                print("Balances saved successfully.")
            }
        }

        // Encode and save owed statements
        do {
            let statementsData = try JSONEncoder().encode(owedStatements)
            let owedStatementsArray = try JSONDecoder().decode([OweStatement].self, from: statementsData)

            db.collection("balances").document(groupId).updateData(["owedStatements": owedStatementsArray]) { error in
                if let error = error {
                    print("Error saving owed statements: \(error.localizedDescription)")
                } else {
                    print("Owed statements saved successfully.")
                }
            }
        } catch {
            print("Error encoding owed statements: \(error)")
        }
    }

    private func loadBalances() {
        db.collection("balances").document(groupId).getDocument { (document, error) in
            if let document = document, document.exists {
                if let balancesData = document.data()?["balances"] as? [String: Double] {
                    self.balances = balancesData
                }
                if let owedStatementsData = document.data()?["owedStatements"] as? [[String: Any]] {
                    self.owedStatements = owedStatementsData.compactMap { dict in
                        guard let debtor = dict["debtor"] as? String,
                              let creditor = dict["creditor"] as? String,
                              let amount = dict["amount"] as? Double else { return nil }
                        return OweStatement(debtor: debtor, creditor: creditor, amount: amount)
                    }
                }
            } else {
                print("Document does not exist or error fetching document: \(String(describing: error))")
            }
        }
    }
}
