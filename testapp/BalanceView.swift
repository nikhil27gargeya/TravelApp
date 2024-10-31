import SwiftUI
struct BalanceView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @EnvironmentObject var balanceManager: BalanceManager
    @State private var transactions: [UserExpense] = loadTransactions()
    
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if balanceManager.manualOwedStatements.isEmpty && balanceManager.receiptOwedStatements.isEmpty {
                        Text("No outstanding debts.")
                            .foregroundColor(.gray)
                    } else {
                        List {
                            if !balanceManager.manualOwedStatements.isEmpty {
                                Section(header: Text("Manual Transactions")) {
                                    ForEach(balanceManager.manualOwedStatements, id: \.self) { statement in
                                        Text("\(statement.debtor) owes \(statement.creditor) \(selectedCurrency) \(String(format: "%.2f", statement.amount))")
                                    }
                                }
                            }
                            
                            if !balanceManager.receiptOwedStatements.isEmpty {
                                Section(header: Text("Receipt Transactions")) {
                                    ForEach(balanceManager.receiptOwedStatements, id: \.self) { statement in
                                        Text("\(statement.debtor) owes \(statement.creditor) \(selectedCurrency) \(String(format: "%.2f", statement.amount))")
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationTitle("Balances")
                .onAppear {
                    // Reset and recalculate balances if necessary
                    balanceManager.resetBalances()
                    // Call update methods here as needed based on current transactions
                }
            }
            .navigationTitle("Balances")
        }
    }

}
