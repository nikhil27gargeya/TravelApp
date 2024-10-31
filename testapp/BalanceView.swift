import SwiftUI
struct BalanceView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @ObservedObject var balanceManager: BalanceManager
    @State private var transactions: [UserExpense] = loadTransactions()
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    let all = getManualOweStatements() + getReceiptOweStatements()
                    if all.isEmpty {
                        Text("No outstanding debts.")
                            .foregroundColor(.gray)
                    } else {
                        List {
                            Section(header: Text("Who Owes Who")) {
                                ForEach(all, id: \.self) { statement in
                                    Text(statement)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationTitle("Balances")
            }
        }
    }

    private func getManualOweStatements() -> [String] {
        var statements: [String] = []
        var totalOwed = [String: [String: Double]]() // Track who owes whom

        for transaction in transactions {
            let splitAmount = transaction.amount / Double(transaction.participants.count)
            
            for friend in transaction.participants {
                if friend != transaction.payer {
                    totalOwed[friend, default: [:]][transaction.payer, default: 0] += splitAmount
                }
            }
        }

        for (debtor, owedAmounts) in totalOwed {
            for (creditor, amount) in owedAmounts {
                statements.append("\(debtor) owes \(creditor) \(selectedCurrency) \(String(format: "%.2f", amount))")
            }
        }

        return statements
    }

    private func getReceiptOweStatements() -> [String] {
        var statements: [String] = []
        for statement in balanceManager.owedStatements {
            statements.append("\(statement.debtor) owes \(statement.creditor) \(selectedCurrency) \(String(format: "%.2f", statement.amount))")
        }
        return statements
    }
}
