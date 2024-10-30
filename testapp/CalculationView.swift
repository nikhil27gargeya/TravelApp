import SwiftUI

//This is view to see Balances

struct BalanceView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @State private var transactions: [UserExpense] = loadTransactions()

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    
                    // Check if there are any statements to display
                    let oweStatements = getOweStatements() // No argument needed here
                    if oweStatements.isEmpty {
                        Text("No outstanding debts.")
                            .foregroundColor(.gray)
                    } else {
                        List { // Wrap Section in a List
                            Section(header: Text("Who Owes Who")) {
                                ForEach(oweStatements, id: \.self) { statement in
                                    Text(statement)
                                }
                            }
                        }
                        .listStyle(PlainListStyle()) // Use plain list style for a cleaner look
                    }
                }
                .navigationTitle("Balances") // Set the title for the view
            }
        }
    }

    private func getOweStatements() -> [String] {
        var statements: [String] = []
        var totalOwed = [String: [String: Double]]() // Track how much each friend owes to others
        
        // Calculate total owed for each friend
        for transaction in transactions {
            let splitAmount = transaction.amount / Double(transaction.participants.count)
            
            // Exclude the payer from the debt calculation
            for friend in transaction.participants {
                // Skip the payer for this transaction
                if friend != transaction.payer {
                    totalOwed[friend, default: [:]][transaction.payer, default: 0] += splitAmount
                }
            }
        }
        
        // Generate statements
        for (debtor, owedAmounts) in totalOwed {
            for (creditor, amount) in owedAmounts {
                statements.append("\(debtor) owes \(creditor) \(selectedCurrency) \(String(format: "%.2f", amount))")
            }
        }
        
        return statements
    }
}
