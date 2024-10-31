import SwiftUI
import Combine

struct OweStatement: Hashable {
    let debtor: String
    let creditor: String
    var amount: Double
}

//shared data
class BalanceManager: ObservableObject {
    @Published var balances: [String: Double] = [:]
    @Published var owedStatements: [OweStatement] = []

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
                    owedStatements.append(OweStatement(debtor: friend, creditor: payer, amount: amount)) // Add new statement
                }
            }
        }
    }

    // Recalculate balances based on current transactions
    func recalculateBalances(from transactions: [UserExpense]) {
        resetBalances() // Clear existing balances before recalculating
        
        for transaction in transactions {
            let splitAmount = transaction.amount / Double(transaction.participants.count)
            // Update balances for each participant in the transaction
            for friend in transaction.participants {
                if friend != transaction.payer {
                    updateBalances(with: [friend: splitAmount], payer: transaction.payer)
                }
            }
        }
    }
    
    // Reset balances and owed statements
    private func resetBalances() {
        balances.removeAll()
        owedStatements.removeAll()
    }
}
