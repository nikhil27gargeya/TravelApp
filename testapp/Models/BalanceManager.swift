import SwiftUI
import Combine

struct OweStatement: Hashable {
    let debtor: String
    let creditor: String
    var amount: Double
}

class BalanceManager: ObservableObject {
    @Published var balances: [String: Double] = [:]
    @Published var manualOwedStatements: [OweStatement] = []
    @Published var receiptOwedStatements: [OweStatement] = []
    
    // Reset balances and owed statements
    func resetBalances() {
        balances.removeAll()
        manualOwedStatements.removeAll()
        receiptOwedStatements.removeAll()
    }
    
    // Recalculate balances based on a list of transactions
    func recalculateBalances(from transactions: [UserExpense]) {
        resetBalances() // Clear current balances and statements
        
        var manualOwed: [OweStatement] = []
        var receiptOwed: [OweStatement] = []
        
        for transaction in transactions {
            let splitAmount = transaction.amount / Double(transaction.participants.count)
            
            // For each participant, update balances and owed statements
            for friend in transaction.participants {
                if friend != transaction.payer {
                    // Update the balance for each participant
                    balances[friend, default: 0.0] += splitAmount
                    balances[transaction.payer, default: 0.0] -= splitAmount
                    
                    // Add or update owed statement
                    if transaction.isManual { // Ensure this property exists in UserExpense
                        updateOweStatements(in: &manualOwed, debtor: friend, creditor: transaction.payer, amount: splitAmount)
                    } else {
                        updateOweStatements(in: &receiptOwed, debtor: friend, creditor: transaction.payer, amount: splitAmount)
                    }
                }
            }
        }
        
        // Update the class-level owed statement arrays
        manualOwedStatements = manualOwed
        receiptOwedStatements = receiptOwed
    }
    
    // Helper function to add or update owed statements
    func updateOweStatements(in statements: inout [OweStatement], debtor: String, creditor: String, amount: Double) {
        if let index = statements.firstIndex(where: { $0.debtor == debtor && $0.creditor == creditor }) {
            statements[index].amount += amount // Update existing statement
        } else {
            statements.append(OweStatement(debtor: debtor, creditor: creditor, amount: amount)) // Add new statement
        }
    }
    
    // Updated method to handle new expenses from a payer
    func updateBalances(with expenses: [String: Double], payer: String) {
        print("Updating balances with expenses: \(expenses) for payer: \(payer)")
        
        for (friend, amount) in expenses {
            // Only update if the friend is not the payer
            if friend != payer {
                // Increase the balance for the payer
                balances[payer, default: 0] += amount
                // Decrease the balance for the friend who owes
                balances[friend, default: 0] -= amount
                
                // Update owed statements for display
                let statement = OweStatement(debtor: friend, creditor: payer, amount: amount)
                updateOweStatements(in: &manualOwedStatements, debtor: friend, creditor: payer, amount: amount) // Ensure this matches your context
            }
        }
        
        // Recalculate owed statements for display
        recalculateOwedStatements()
    }
    
    // This function should reflect the latest owed statements based on updated balances
    private func recalculateOwedStatements() {
        // Placeholder for recalculating owed statements based on current balances
        manualOwedStatements.removeAll()
        receiptOwedStatements.removeAll()

        for (debtor, balance) in balances {
            if balance < 0 {
                // Logic to find the creditor can be added here
                // For example, you might want to have a method to identify the creditor based on your application logic
                let creditor = getCreditor(for: debtor) // You need to implement this logic
                let statement = OweStatement(debtor: debtor, creditor: creditor, amount: -balance)
                // Depending on how you want to categorize these statements, add them to the appropriate array
                if isManualTransaction(for: debtor) { // Example check
                    manualOwedStatements.append(statement)
                } else {
                    receiptOwedStatements.append(statement)
                }
            }
        }
    }
    
    // Method to determine the creditor based on balances (customize as needed)
    private func getCreditor(for debtor: String) -> String {
        // Your logic to find out who is the creditor for the given debtor
        return "Creditor Name" // Placeholder
    }

    // Placeholder to determine if a transaction is manual (customize as needed)
    private func isManualTransaction(for debtor: String) -> Bool {
        // Your logic to determine if the transaction is manual
        return true // Placeholder
    }
}
