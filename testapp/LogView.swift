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
    @State private var totalExpense: Double = 0.0 // Manage totalExpense in LogView
    @State var friends: [Friend] = loadFriends() // Load friends list

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

                    // Check if there are any statements to display
                    let oweStatements = getOweStatements() // No argument needed here
                    if oweStatements.isEmpty {
                        Text("No outstanding debts.")
                            .foregroundColor(.gray)
                    } else {
                        List { // Wrap Section in a List
                            Section(header: Text("Who Owes Who")) {
                                ForEach(oweStatements, id: \.self) { statement in
                                    Text(statement)
                                }
                            }
                        }
                    }
                    
                    // Transactions List
                    List {
                        ForEach(transactions) { transaction in
                            VStack(alignment: .leading) {
                                Text(transaction.description ?? "No Description")
                                Text("Paid by: \(transaction.payer)") // Display the payer
                                Text("Amount: \(String(format: "%.2f", transaction.amount))")
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
                    AddTransactionView(totalExpense: $totalExpense, transactions: $transactions, friends: $friends)
                }
            }
        }
    }
    
    private func getOweStatements() -> [String] {
        var statements: [String] = []
        var totalOwed = [String: [String: Double]]() // Track how much each friend owes to others

        // Calculate total owed for each friend
        for transaction in transactions {
            let splitAmount = transaction.amount / Double(transaction.participants.count)
            
            // Exclude the payer from the debt calculation
            for friend in transaction.participants {
                // Skip the payer for this transaction
                if friend != transaction.payer {
                    totalOwed[friend, default: [:]][transaction.payer, default: 0] += splitAmount
                }
            }
        }

        // Generate statements
        for (debtor, owedAmounts) in totalOwed {
            for (creditor, amount) in owedAmounts {
                statements.append("\(debtor) owes \(creditor) \(selectedCurrency) \(String(format: "%.2f", amount))")
            }
        }

        return statements
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
