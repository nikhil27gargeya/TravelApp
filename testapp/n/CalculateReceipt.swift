import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct CalculateReceiptView: View {
    @ObservedObject var balanceManager: BalanceManager
    @Binding var transactions: [UserExpense]
    @Binding var totalExpense: Double
    @State private var selectedPerson: [String: String] = [:]
    @State private var selectedPayer: String? = nil
    @Binding var friends: [Friend]
    var parsedItems: [(String, Double)]
    var tax: Double
    var total: Double
    @State private var isSaving = false

    var body: some View {
        VStack {
            // Payer Picker
            Picker("Who Paid?", selection: $selectedPayer) {
                ForEach(friends, id: \.id) { friend in
                    Text(friend.name).tag(friend.name as String?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 200)
            .padding(.vertical, 8)

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

            // Finish Button
            Button("Finish") {
                calculateAndSaveExpenses()
            }
            .padding()
            .buttonStyle(BorderlessButtonStyle())
            .disabled(!isFormComplete() || isSaving)
        }
        .onAppear {
            printFriendsList()
        }
    }

    // Check if the form is complete
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
        if tax > 0 {
            let taxPerPerson = tax / Double(expensesPerPerson.keys.count)
            for person in expensesPerPerson.keys {
                expensesPerPerson[person, default: 0.0] += taxPerPerson
            }
        }

        // Call function to save the transaction
        saveTransaction(expensesPerPerson: expensesPerPerson, payer: payer)
    }

    // Save transaction to Firestore
    private func saveTransaction(expensesPerPerson: [String: Double], payer: String) {
        let groupId = balanceManager.groupId
        
        // Ensure the groupId is valid
        guard !groupId.isEmpty else {
            print("Error: Group ID is empty.")
            return
        }
        
        let totalAmount = parsedItems.reduce(0) { $0 + $1.1 } + tax
        let newExpense = UserExpense(
            amount: totalAmount,
            date: Date(),
            description: "Receipt Transaction",
            splitDetails: expensesPerPerson,
            participants: Array(expensesPerPerson.keys),
            payer: payer
        )
        
        isSaving = true
        
        let db = Firestore.firestore()
        do {
            let _ = try db.collection("groups").document(groupId).collection("transactions").addDocument(from: newExpense) { error in
                if let error = error {
                    print("Error saving transaction to Firebase: \(error.localizedDescription)")
                    isSaving = false
                } else {
                    transactions.append(newExpense)
                    totalExpense += newExpense.amount
                    balanceManager.updateBalances(with: expensesPerPerson, payer: payer)
                    isSaving = false
                    print("Transaction saved successfully!")
                }
            }
        } catch {
            print("Error encoding transaction: \(error.localizedDescription)")
            isSaving = false
        }
    }


    // Debugging function to check friends list
    private func printFriendsList() {
        if friends.isEmpty {
            print("Friends list is empty.")
        } else {
            print("Friends list:")
            friends.forEach { print($0.name) }
        }
    }
}
