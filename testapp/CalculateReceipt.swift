import SwiftUI
import Foundation

struct CalculateReceiptView: View {
    @ObservedObject var balanceManager: BalanceManager
    @State private var selectedPerson: [String: String] = [:] // Stores who bought each item
    @State private var selectedPayer: String? = nil // Stores the person who paid for the receipt
    @State var friends: [Friend] = loadFriends() // Load friends directly here
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
                calculateExpenses()
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

    func calculateExpenses() {
        var expensesPerPerson: [String: Double] = [:]

        // Calculate each person's total expenses based on selected items
        for item in parsedItems {
            let person = selectedPerson[item.0] ?? "Unknown"
            expensesPerPerson[person, default: 0.0] += item.1
        }

        // Update balances excluding the payer's own expenses
        updateBalances(with: expensesPerPerson)
    }

    func updateBalances(with expenses: [String: Double]) {
        print("Expenses to update: \(expenses)")
        if let payer = selectedPayer {
            for (friend, amount) in expenses {
                if friend != payer { // Only consider friends who are not the payer
                    // Update how much the non-payer owes the payer
                    balanceManager.updateBalances(with: [friend: amount], payer: payer)
                }
            }
        }
    }

    private func printFriendsList() {
        if friends.isEmpty {
            print("Friends list is empty.")
        } else {
            print("Friends list:")
            for friend in friends {
                print("\(friend.name) - ID: \(friend.id)")
            }
        }
    }
}

struct CalculateReceiptView_Previews: PreviewProvider {
    static var previews: some View {
        CalculateReceiptView(
            balanceManager: BalanceManager(),
            friends: loadFriends(),
            parsedItems: [("Coffee", 4.50), ("Sandwich", 7.25), ("Salad", 6.00)],
            tax: 1.0,
            total: 20.0
        )
    }
}
