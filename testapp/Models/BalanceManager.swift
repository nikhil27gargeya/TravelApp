import SwiftUI
import Combine

struct OweStatement: Codable, Identifiable {
    var id = UUID()
    let debtor: String
    let creditor: String
    var amount: Double
}

class BalanceManager: ObservableObject {
    @Published var balances: [String: Double] = [:]
    @Published var owedStatements: [OweStatement] = []

    init() {
        loadBalances() // Load balances and owed statements on initialization
    }

    func updateBalances(with expenses: [String: Double], payer: String) {
        for (friend, amount) in expenses {
            if friend != payer {
                // Update balances
                balances[friend, default: 0.0] += amount
                balances[payer, default: 0.0] -= amount
                
                // Add owed statement
                owedStatements.append(OweStatement(debtor: friend, creditor: payer, amount: amount))
            }
        }
        saveBalances() // Save after updating
        print("Balances updated: \(balances)")
        print("Owed statements updated: \(owedStatements)")
    }

    func resetBalances() {
        balances.removeAll()
        owedStatements.removeAll()
        saveBalances() // Save reset state
        print("Balances and owed statements reset.")
    }
    
    // MARK: - Persistence Methods
    
    private func saveBalances() {
        // Encode and save balances
        if let balancesData = try? JSONEncoder().encode(balances) {
            UserDefaults.standard.set(balancesData, forKey: "balances")
        }
        
        // Encode and save owed statements
        if let statementsData = try? JSONEncoder().encode(owedStatements) {
            UserDefaults.standard.set(statementsData, forKey: "owedStatements")
        }
    }
    
    private func loadBalances() {
        // Decode balances
        if let balancesData = UserDefaults.standard.data(forKey: "balances"),
           let decodedBalances = try? JSONDecoder().decode([String: Double].self, from: balancesData) {
            balances = decodedBalances
        }
        
        // Decode owed statements using the OweStatement struct
        if let statementsData = UserDefaults.standard.data(forKey: "owedStatements"),
           let decodedStatements = try? JSONDecoder().decode([OweStatement].self, from: statementsData) {
            owedStatements = decodedStatements
        }
    }
}
