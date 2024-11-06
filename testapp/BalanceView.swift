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
                        let all = getOweStatements()
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
        db.collection("groups").document(balanceManager.groupId).collection("transactions").getDocuments { snapshot, error in
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

    // Calculate owe statements using splitDetails from transactions
    private func getOweStatements() -> [String] {
        var netOwed: [String: [String: Double]] = [:]

        // Calculate the owed amounts using splitDetails from each transaction
        for transaction in transactions {
            for (debtor, amount) in transaction.splitDetails {
                if debtor != transaction.payer {
                    // Add the debt to netOwed
                    netOwed[debtor, default: [:]][transaction.payer, default: 0.0] += amount
                }
            }
        }

        // Add owed statements from the balance manager (if any)
        for statement in balanceManager.owedStatements {
            netOwed[statement.debtor, default: [:]][statement.creditor, default: 0.0] += statement.amount
        }

        // Calculate net debts between participants
        var finalStatements: [String] = []

        // Iterate over all debtors in netOwed
        for (debtor, creditors) in netOwed {
            for (creditor, amountOwedByDebtor) in creditors {
                // Check if the creditor owes anything to the debtor
                let amountOwedByCreditor = netOwed[creditor]?[debtor] ?? 0.0

                if amountOwedByCreditor > 0 {
                    // If there is mutual debt, net it out
                    let netAmount = amountOwedByDebtor - amountOwedByCreditor

                    if netAmount > 0 {
                        // Debtor owes more to Creditor
                        finalStatements.append("\(debtor) owes \(creditor) \(selectedCurrency) \(String(format: "%.2f", netAmount))")
                    } else if netAmount < 0 {
                        // Creditor owes more to Debtor
                        finalStatements.append("\(creditor) owes \(debtor) \(selectedCurrency) \(String(format: "%.2f", abs(netAmount)))")
                    }

                    // Remove the netted amount for the reverse case to avoid duplicate entries
                    netOwed[creditor]?[debtor] = 0.0
                } else {
                    // If there's no mutual debt, add the statement directly
                    finalStatements.append("\(debtor) owes \(creditor) \(selectedCurrency) \(String(format: "%.2f", amountOwedByDebtor))")
                }
            }
        }

        return finalStatements
    }

}

struct BalanceView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceView(balanceManager: BalanceManager(groupId: "group123"))
    }
}
