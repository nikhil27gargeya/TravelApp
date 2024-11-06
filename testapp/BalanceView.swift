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
                                        NavigationLink(destination: TransactionDetailView(statement: statement, transactions: transactions)) {
                                            Text(statement.description)
                                        }
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                    .navigationTitle("Balances")
                    .toolbar {
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
                try? document.data(as: UserExpense.self)
            }
            isLoading = false
        }
    }

    private func clearAllOweStatements() {
        balanceManager.owedStatements.removeAll()
        transactions.removeAll()
        clearStoredOwedStatements()
    }

    private func clearStoredOwedStatements() {
        UserDefaults.standard.removeObject(forKey: "owedStatements")
    }

    private func getOweStatements() -> [OweStatement] {
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
        var finalStatementsSet: Set<OweStatement> = []

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
                        let oweStatement = OweStatement(debtor: debtor, creditor: creditor, amount: netAmount)
                        finalStatementsSet.insert(oweStatement)
                    } else if netAmount < 0 {
                        // Creditor owes more to Debtor
                        let oweStatement = OweStatement(debtor: creditor, creditor: debtor, amount: abs(netAmount))
                        finalStatementsSet.insert(oweStatement)
                    }
                    
                    // Remove the netted amount for the reverse case to avoid duplicate entries
                        netOwed[creditor]?[debtor] = 0.0
                    } else if amountOwedByDebtor > 0 {
                    // If there's no mutual debt, add the statement directly
                        let oweStatement = OweStatement(debtor: debtor, creditor: creditor, amount: amountOwedByDebtor)
                        finalStatementsSet.insert(oweStatement)
                    }
                }
            }

        // Convert the set to an array and return
        return Array(finalStatementsSet)
    }
}
