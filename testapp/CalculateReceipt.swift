import SwiftUI

struct CalculateReceiptView: View {
    @Binding var scannedText: String
    @Binding var parsedItems: [(String, Double)]  // Pass parsedItems as a Binding
    @Binding var totalAmount: Double?
    @Binding var taxAmount: Double?
    @ObservedObject var balanceManager: BalanceManager
    @Binding var transactions: [UserExpense]
    @Binding var totalExpense: Double
    @Binding var friends: [Friend]
    
    @State private var selectedPayer: String? = nil
    @State private var selectedPerson: [String: String] = [:] // To track who paid for each item
    @State private var isSaving = false

    var body: some View {
        VStack {
            // Payer Picker (who paid the bill)
            Picker("Who Paid?", selection: $selectedPayer) {
                ForEach(friends, id: \.id) { friend in
                    Text(friend.name).tag(friend.name as String?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 200)
            .padding(.vertical, 8)

            // Show the items, prices, tax, and total
            if parsedItems.isEmpty {
                Text("No items available.")
                    .padding()
            } else {
                // Items Picker for each parsed item
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
            }

            // Tax display
            Text("Tax: $\(taxAmount ?? 0.0, specifier: "%.2f")")
                .padding()

            // Total display
            Text("Total: $\(totalAmount ?? 0.0, specifier: "%.2f")")
                .padding()

            // Finish Button
            Button("Finish") {
                calculateAndSaveExpenses()
            }
            .padding()
            .buttonStyle(BorderlessButtonStyle())
            .disabled(!isFormComplete() || isSaving)
        }
        .onAppear {
            print("Parsed Items in CalculateReceiptView: \(parsedItems)")

        }
    }

    // Check if the form is complete (all items have been assigned to someone)
    private func isFormComplete() -> Bool {
        return parsedItems.allSatisfy { selectedPerson[$0.0] != nil } && selectedPayer != nil
    }

    // Binding to set/get the selected person for each item
    private func personBinding(for itemName: String) -> Binding<String> {
        Binding(
            get: { selectedPerson[itemName] ?? friends.first?.name ?? "Unknown" },
            set: { newValue in selectedPerson[itemName] = newValue }
        )
    }

    // Calculate and save expenses
    private func calculateAndSaveExpenses() {
        guard let payer = selectedPayer else {
            print("Error: No payer selected.")
            return
        }

        var expensesPerPerson: [String: Double] = [:]

        // Calculate individual expenses
        for item in parsedItems {
            let person = selectedPerson[item.0] ?? "Unknown"
            expensesPerPerson[person, default: 0.0] += item.1
        }

        // Add tax proportionally to all participants
        if let tax = taxAmount, tax > 0 {
            let taxPerPerson = tax / Double(expensesPerPerson.keys.count)
            for person in expensesPerPerson.keys {
                expensesPerPerson[person, default: 0.0] += taxPerPerson
            }
        }

        // Save the transaction
        saveTransaction(expensesPerPerson: expensesPerPerson, payer: payer)
    }

    // Save transaction to Firestore
    private func saveTransaction(expensesPerPerson: [String: Double], payer: String) {
        // Implement Firestore saving logic here
        print("Saving transaction: \(expensesPerPerson), payer: \(payer)")
        // After saving, update the UI accordingly (e.g., updating transactions, expenses, etc.)
    }
}
