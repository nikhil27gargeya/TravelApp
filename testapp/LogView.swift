
import SwiftUI

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct LogView: View {
    @AppStorage("currency") private var selectedCurrency: String = "USD"
    @State private var transactions: [UserExpense] = loadTransactions() // Load transactions
    @State private var showAddTransaction = false // State variable for showing the Add Transaction view
    @State private var showReceiptScanner = false // State variable for showing the Receipt Scanner view
    @State private var totalExpense: Double = 0.0 // Manage totalExpense in LogView
    @State var friends: [Friend] = loadFriends() // Load friends list
    @ObservedObject var balanceManager: BalanceManager // Add BalanceManager

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List {
                        ForEach(transactions) { transaction in
                            VStack(alignment: .leading) {
                                Text(transaction.description ?? "No Description")
                                Text("Paid by: \(transaction.payer)") // Handle nil payer case
                                Text("Amount: \(String(format: "%.2f", transaction.amount))")
                                Text("Date: \(transaction.date, formatter: DateFormatter.shortDate)")
                            }
                        }
                        .onDelete(perform: deleteTransaction)
                    }
                    .listStyle(PlainListStyle()) // Use plain list style for a cleaner look
                    .frame(maxHeight: .infinity) // Allow the list to extend fully
                }

                // Add Transaction Button
                VStack {
                    Spacer() // Pushes the button to the bottom
                    HStack {
                        Spacer() // Pushes the button to the right
                        Button(action: {
                            showAddTransaction.toggle()
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .padding()
                        }
                        .background(Color.blue)
                        .clipShape(Circle())
                        .padding()
                    }
                }
            }
            .navigationTitle("Expense Log")
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(totalExpense: $totalExpense, transactions: $transactions, friends: $friends)
            }
        }
    }

    // Delete transaction at specified index
    private func deleteTransaction(at offsets: IndexSet) {
        // Get the transaction to delete and determine who the payer was
        if let index = offsets.first {
            let transactionToDelete = transactions[index]
            transactions.remove(atOffsets: offsets)
            saveTransactions(transactions) // Save updated transactions
            
            // Recalculate balances
            balanceManager.resetBalances() // Reset current balances
            for transaction in transactions { // Re-calculate balances based on remaining transactions
                let splitAmount = transaction.amount / Double(transaction.participants.count)
                balanceManager.updateBalances(with: [transaction.payer: splitAmount], payer: transaction.payer)
            }
        }
    }
}

// Load and save transactions functions
func loadTransactions() -> [UserExpense] {
    if let data = UserDefaults.standard.data(forKey: "transactions"),
       let savedTransactions = try? JSONDecoder().decode([UserExpense].self, from: data) {
        return savedTransactions
    }
    return []
}

func saveTransactions(_ transactions: [UserExpense]) {
    if let data = try? JSONEncoder().encode(transactions) {
        UserDefaults.standard.set(data, forKey: "transactions")
    }
}
