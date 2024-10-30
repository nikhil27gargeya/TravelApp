import SwiftUI

struct BalanceView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @ObservedObject var balanceManager: BalanceManager

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    let oweStatements = getOweStatements() // Ensure it includes both manual and receipt entries
                    if oweStatements.isEmpty {
                        Text("No outstanding debts.")
                            .foregroundColor(.gray)
                    } else {
                        List {
                            Section(header: Text("Who Owes Who")) {
                                ForEach(oweStatements, id: \.self) { statement in
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

    private func getOweStatements() -> [String] {
        var statements: [String] = []
        for statement in balanceManager.owedStatements {
            statements.append("\(statement.debtor) owes \(statement.creditor) \(selectedCurrency) \(String(format: "%.2f", statement.amount))")
        }
        return statements
    }

}



 import SwiftUI
 
 struct BalanceView: View {
 @AppStorage("currency") private var selectedCurrency: String = "USD"
 @ObservedObject var balanceManager: BalanceManager
 @State private var transactions: [UserExpense] = loadTransactions()
 @State private var receiptTransactions: [UserExpense] = []  Add parsed receipt transactions here
 
 var body: some View {
 NavigationView {
 ZStack {
 VStack {
 let oweStatements = getOweStatements()
 if oweStatements.isEmpty {
 Text("No outstanding debts.")
 .foregroundColor(.gray)
 } else {
 List {
 Section(header: Text("Who Owes Who")) {
 ForEach(oweStatements, id: \.self) { statement in
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
 
 private func getOweStatements() -> [String] {
 var statements: [String] = []
 var totalOwed = [String: [String: Double]]()
 
  Combine both manually entered and receipt-based transactions
 let allTransactions = transactions + receiptTransactions
 
 for transaction in allTransactions {
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
 }
 
