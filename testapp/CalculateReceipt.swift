import SwiftUI
import Foundation

struct CalculateReceiptView: View {
    @ObservedObject var balanceManager: BalanceManager
    @Binding var transactions: [UserExpense] // Binding to transactions in LogView
    @Binding var totalExpense: Double // Update total expense
    @State private var selectedPerson: [String: String] = [:]
    @State private var selectedPayer: String? = nil
    @State var friends: [Friend] = loadFriends()
    var parsedItems: [(String, Double)]
    var tax: Double
    var total: Double
    

    var body: some View {
        VStack {
            // Picker to select who paid for the receipt
            Picker("Who Paid?", selection: $selectedPayer) {
                ForEach(friends, id: \.id) { friend in
                    Text(friend.name).tag(friend.name as String?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 200)
            .padding(.vertical, 8)

            // Each item with its "Who Bought?" picker
            ForEach(parsedItems, id: \.0) { item in
                HStack {
                    Text("\(item.0): $\(item.1, specifier: "%.2f")")
                    Picker("Who Bought?", selection: personBinding(for: item.0)) {
                        ForEach(friends, id: \.id) { friend in
                            Text(friend.name).tag(friend.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                }
                .padding(.vertical, 4)
            }

            Button("Finish") {
                calculateAndSaveExpenses()
            }
            .padding()
            .buttonStyle(BorderlessButtonStyle())
            .disabled(!isFormComplete())
        }
        .onAppear {
            printFriendsList()
        }
    }

    private func isFormComplete() -> Bool {
        return parsedItems.allSatisfy { selectedPerson[$0.0] != nil } && selectedPayer != nil
    }

    private func personBinding(for itemName: String) -> Binding<String> {
        Binding(
            get: {
                selectedPerson[itemName] ?? (friends.first?.name ?? "Unknown")
            },
            set: { newValue in
                selectedPerson[itemName] = newValue
            }
        )
    }

    private func calculateAndSaveExpenses() {
        var expensesPerPerson: [String: Double] = [:]

        // Calculate each person's total expenses based on selected items
        for item in parsedItems {
            let person = selectedPerson[item.0] ?? "Unknown"
            expensesPerPerson[person, default: 0.0] += item.1
        }

        // Save the transaction
        saveTransaction(expensesPerPerson: expensesPerPerson)
    }

    private func saveTransaction(expensesPerPerson: [String: Double]) {
        guard let payer = selectedPayer else { return }

        // Calculate total amount from receipt items
        let totalAmount = parsedItems.reduce(0) { $0 + $1.1 }
        
        let newExpense = UserExpense(
            amount: totalAmount,
            date: Date(),
            description: "Receipt Transaction",
            splitDetails: expensesPerPerson,
            participants: Array(expensesPerPerson.keys),
            payer: payer
        )
        
        transactions.append(newExpense)
        saveTransactions(transactions) // Save updated transactions
        totalExpense += newExpense.amount
        
        // Update balances in balance manager
        for (friend, amount) in expensesPerPerson {
            if friend != payer {
                balanceManager.updateBalances(with: [friend: amount], payer: payer)
            }
        }
    }

    private func printFriendsList() {
        if friends.isEmpty {
            print("Friends list is empty.")
        } else {
            print("Friends list:")
            for friend in friends {
                print("\(friend.name)")
            }
        }
    }
}
