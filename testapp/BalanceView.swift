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
        return balanceManager.owedStatements
    }
}
