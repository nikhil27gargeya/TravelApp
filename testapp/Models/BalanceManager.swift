import SwiftUI
import Combine

class BalanceManager: ObservableObject {
    @Published var balances: [String: Double] = [:]
    @Published var owedStatements: [(debtor: String, creditor: String, amount: Double)] = []

    func updateBalances(with expenses: [String: Double], payer: String) {
        for (friend, amount) in expenses {
            if friend != payer {
                balances[friend, default: 0.0] += amount
                balances[payer, default: 0.0] -= amount
                owedStatements.append((debtor: friend, creditor: payer, amount: amount))
            }
        }
        print("Balances updated: \(balances)")
        print("Owed statements updated: \(owedStatements)")
    }

    func resetBalances() {
        balances.removeAll()
        owedStatements.removeAll()
        print("Balances and owed statements reset.")
    }
}
