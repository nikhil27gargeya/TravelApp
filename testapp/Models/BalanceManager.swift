import SwiftUI
import Combine

class BalanceManager: ObservableObject {
    @Published var balances: [String: Double] = [:]
    @Published var owedStatements: [(debtor: String, creditor: String, amount: Double)] = [] // New property to track who owes whom

    func updateBalances(with expenses: [String: Double], payer: String) {
        for (friend, amount) in expenses {
            if friend != payer { // Only update for non-payers
                balances[friend, default: 0.0] += amount
                balances[payer, default: 0.0] -= amount // Deduct from payer’s balance
                owedStatements.append((debtor: friend, creditor: payer, amount: amount))
            }
        }
        print("Balances updated: \(balances)")
        print("Owed statements updated: \(owedStatements)")
    }
}
