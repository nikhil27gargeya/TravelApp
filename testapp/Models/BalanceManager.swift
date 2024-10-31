import SwiftUI
import Combine

class BalanceManager: ObservableObject {
    @Published var balances: [String: Double] = [:]
    @Published var owedStatements: [(debtor: String, creditor: String, amount: Double)] = []

    // Update balances based on new expenses for a specific payer
    func updateBalances(with expenses: [String: Double], payer: String) {
        for (friend, amount) in expenses {
            if friend != payer {
                balances[friend, default: 0.0] += amount
                balances[payer, default: 0.0] -= amount
                
                // Check for existing owed statement
                if let index = owedStatements.firstIndex(where: { $0.debtor == friend && $0.creditor == payer }) {
                    owedStatements[index].amount += amount // Update existing statement
                } else {
                    owedStatements.append((debtor: friend, creditor: payer, amount: amount)) // Add new statement
                }
            }
        }
        print("Balances updated: \(balances)")
        print("Owed statements updated: \(owedStatements)")
    }

    // Reset balances and owed statements (useful for initial setup or when all data is cleared)
    func resetBalances() {
        balances.removeAll()
        owedStatements.removeAll()
        print("Balances and owed statements reset.")
    }

    // Recalculate balances based on current transactions
    func recalculateBalances(from transactions: [UserExpense]) {
        resetBalances() // Start fresh
        
        for transaction in transactions {
            let splitAmount = transaction.amount / Double(transaction.participants.count)
            updateBalances(with: [transaction.payer: splitAmount], payer: transaction.payer)
        }
        
        print("Balances recalculated: \(balances)")
        print("Owed statements recalculated: \(owedStatements)")
    }
}
