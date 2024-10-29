import SwiftUI

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct LogView: View {
    @State private var selectedCurrency = "USD"
    @State private var transactions: [UserExpense] = loadTransactions() // Load transactions
    @State private var showAddTransaction = false // State variable for showing the Add Transaction view
    @State private var totalExpense: Double = 0.0 // Manage totalExpense in LogView
    @State private var friends: [Friend] = loadFriends() // Load friends list

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Display Balances at the Top
                    VStack(alignment: .leading) {
                        Text("Balances")
                            .font(.headline)
                    }
                    .padding()
                    
                    // Transactions List
                    List {
                        ForEach(transactions) { transaction in
                            VStack(alignment: .leading) {
                                Text(transaction.description ?? "No Description")
                                Text("Amount: \(transaction.amount, specifier: "%.2f")")
                                Text("Date: \(transaction.date, formatter: DateFormatter.shortDate)")
                            }
                        }
                        .onDelete(perform: deleteTransaction) // Enable swipe to delete
                    }
                    .navigationTitle("Expense Log")
                    
                    // Add Transaction Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
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
                .sheet(isPresented: $showAddTransaction) {
                    AddTransactionView(totalExpense: $totalExpense, transactions: $transactions, friends: $friends, selectedCurrency: $selectedCurrency)
                }
            }
        }
    }
    

    // Delete transaction at specified index
    private func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        saveTransactions(transactions) // Save updated transactions
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
