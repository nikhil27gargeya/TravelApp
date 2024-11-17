import SwiftUI
import FirebaseFirestore

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct LogView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @State private var showAddTransaction = false
    @State private var totalExpense: Double = 0.0
    @ObservedObject var balanceManager: BalanceManager
    @ObservedObject var friendManager: FriendManager
    @Binding var transactions: [UserExpense]
    
    var body: some View {
        NavigationView {
                    ZStack {
                        VStack {
                            // Show "No transactions logged yet" if there are no transactions
                            if transactions.isEmpty {
                                Text("Logged transactions will appear here!")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                transactionList
                            }
                        }
                    }
                    .navigationTitle("Log")
                    .onAppear {
                        loadTransactions()
                    }
                }
    }

    // MARK: - Views
    
    private var transactionList: some View {
        List {
            ForEach(transactions) { transaction in
                VStack(alignment: .leading) {
                    Text(transaction.description ?? "No Description")
                    Text("Paid by: \(transaction.payer)")
                    Text("Amount: \(String(format: "%.2f", transaction.amount))")
                    Text("Date: \(transaction.date, formatter: DateFormatter.shortDate)")
                }
            }
            .onDelete(perform: deleteTransaction)
        }
        .listStyle(PlainListStyle())
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Firestore Integration
    //update balances after log view transaction deletion
    private func updateBalancesAfterDeletion(transaction: UserExpense) {
        let db = Firestore.firestore()

        // Get the payer and split details
        let payer = transaction.payer
        let splitDetails = transaction.splitDetails

        // Update the balance for the payer
        for (friend, amount) in splitDetails {
            if friend != payer {
                // Subtract the amount from the payer's balance (they paid for others)
                balanceManager.balances[payer, default: 0.0] -= amount
                // Add the amount to the friend's balance (they owe the payer)
                balanceManager.balances[friend, default: 0.0] += amount

                // Update the owed statements using balanceManager
                balanceManager.updateOwedStatements(debtor: friend, creditor: payer, amount: -amount)
            }
        }

        // Save the updated balances and owed statements
        balanceManager.saveBalances()
        print("Balances and owed statements updated after transaction deletion.")
    }
    
    private func loadTransactions() {
        let db = Firestore.firestore()
        db.collection("groups").document(balanceManager.groupId).collection("transactions").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching transactions: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No transactions found")
                return
            }
            self.transactions = documents.compactMap { document in
                try? document.data(as: UserExpense.self)
            }
        }
    }

    private func deleteTransaction(at offsets: IndexSet) {
        guard let index = offsets.first else { return }

        let transactionToDelete = transactions[index]

        // Print the transaction ID for debugging purposes
        print("Attempting to delete transaction with ID: \(transactionToDelete.id)")

        // Remove the transaction from the local list first
        transactions.remove(atOffsets: offsets)

        // Update the balances after deleting the transaction
        updateBalancesAfterDeletion(transaction: transactionToDelete)

        let db = Firestore.firestore()
        let groupId = balanceManager.groupId

        // Query Firestore to find the document with the matching transaction ID
        db.collection("groups").document(groupId).collection("transactions")
            .whereField("id", isEqualTo: transactionToDelete.id.uuidString)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding transaction: \(error)")
                    return
                }

                guard let documents = snapshot?.documents, let document = documents.first else {
                    print("Transaction not found for deletion.")
                    return
                }

                // Now delete the document that was found
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting transaction: \(error)")
                    } else {
                        print("Transaction deleted successfully!")
                    }
                }
            }
    }
}
