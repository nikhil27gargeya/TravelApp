import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct BalanceView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @ObservedObject var balanceManager: BalanceManager
    @State private var transactions: [UserExpense] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading...")
                } else {
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
                    .toolbar {
                        // Add the trash button in the navigation bar
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: clearAllOweStatements) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .onAppear {
                loadTransactions()
            }
        }
    }

    private func loadTransactions() {
        let db = Firestore.firestore()
        db.collection("transactions").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching transactions: \(error)")
                isLoading = false
                return
            }
            guard let documents = snapshot?.documents else {
                print("No transactions found")
                isLoading = false
                return
            }
            self.transactions = documents.compactMap { document in
                try? document.data(as: UserExpense.self) // Assuming UserExpense conforms to Codable
            }
            isLoading = false
        }
    }

    // Clear all owe statements from balanceManager and reset balances
    private func clearAllOweStatements() {
        balanceManager.owedStatements.removeAll() // Clear all owe statements
        transactions.removeAll() // Clear all transactions (optional, if needed for testing)
        clearStoredOwedStatements()
    }
    
    private func clearStoredOwedStatements() {
        UserDefaults.standard.removeObject(forKey: "owedStatements")
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

struct BalanceView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceView(balanceManager: BalanceManager(groupId: "group123"))
    }
}
