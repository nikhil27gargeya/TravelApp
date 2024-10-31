import SwiftUI
import Foundation

struct CalculateReceiptView: View {
    @EnvironmentObject var balanceManager: BalanceManager
    @State private var selectedPayer: String? = nil
    @State private var selectedPeople: [String: [String]] = [:] // Update this to hold multiple selections
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

            ForEach(parsedItems, id: \.0) { item in
                HStack {
                    Text("\(item.0): $\(item.1, specifier: "%.2f")")
                    // List to select multiple people who bought this item
                    VStack {
                        ForEach(friends, id: \.id) { friend in
                            HStack {
                                // Checkbox for selecting the friend
                                Button(action: {
                                    toggleSelection(for: friend.name, itemName: item.0)
                                }) {
                                    HStack {
                                        Image(systemName: selectedPeople[item.0]?.contains(friend.name) ?? false ? "checkmark.square" : "square")
                                            .foregroundColor(selectedPeople[item.0]?.contains(friend.name) ?? false ? .blue : .gray)
                                        Text(friend.name)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle()) // To keep it looking like a regular text button
                            }
                        }
                    }
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
    }

    private func isFormComplete() -> Bool {
        return selectedPayer != nil && selectedPeople.allSatisfy { !$0.value.isEmpty } // Ensure at least one person is selected for each item
    }

    private func toggleSelection(for friendName: String, itemName: String) {
        if selectedPeople[itemName] == nil {
            selectedPeople[itemName] = []
        }

        if let index = selectedPeople[itemName]?.firstIndex(of: friendName) {
            selectedPeople[itemName]?.remove(at: index) // Deselect if already selected
        } else {
            selectedPeople[itemName]?.append(friendName) // Select if not already selected
        }
    }

    func calculateExpenses() {
        var expensesPerPerson: [String: Double] = [:]

        // Calculate each person's total expenses based on selected items
        for item in parsedItems {
            let amount = item.1
            if let people = selectedPeople[item.0] {
                let splitAmount = amount / Double(people.count) // Split among selected people
                for person in people {
                    expensesPerPerson[person, default: 0.0] += splitAmount
                }
            }
        }

        // Update balances excluding the payer's own expenses
        updateBalances(with: expensesPerPerson)
    }

    func updateBalances(with expenses: [String: Double]) {
        print("Expenses to update: \(expenses)")
        if let payer = selectedPayer {
            for (friend, amount) in expenses {
                if friend != payer {
                    // Update how much the non-payer owes the payer
                    balanceManager.updateBalances(with: [friend: amount], payer: payer)
                }
            }
        }
    }
}
