import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

public func parseReceiptData(from text: String) -> (items: [(String, Double)], tax: Double, total: Double) {
    var itemCosts: [(String, Double)] = []
    var tax: Double = 0.0
    var total: Double = 0.0
    let lines = text.components(separatedBy: .newlines)
    var capturingItems = false

    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedLine.lowercased().contains("ordered:") {
            capturingItems = true
            continue
        }
        if capturingItems, let priceMatch = trimmedLine.range(of: #"\$(\d+(\.\d{1,2})?)"#, options: .regularExpression) {
            let priceString = String(trimmedLine[priceMatch]).replacingOccurrences(of: "$", with: "")
            if let price = Double(priceString) {
                let itemName = trimmedLine.replacingOccurrences(of: "$\(priceString)", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                itemCosts.append((itemName, price))
            }
        } else if trimmedLine.lowercased().contains("tax") {
            if let taxMatch = trimmedLine.range(of: #"\$(\d+(\.\d{1,2})?)"#, options: .regularExpression) {
                tax = Double(trimmedLine[taxMatch].replacingOccurrences(of: "$", with: "")) ?? 0.0
            }
        } else if trimmedLine.lowercased().contains("total") {
            if let totalMatch = trimmedLine.range(of: #"\$(\d+(\.\d{1,2})?)"#, options: .regularExpression) {
                total = Double(trimmedLine[totalMatch].replacingOccurrences(of: "$", with: "")) ?? 0.0
            }
        }
    }

    return (items: itemCosts, tax: tax, total: total)
}

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

    private func isFormComplete() -> Bool {
        return parsedItems.allSatisfy { selectedPerson[$0.0] != nil } && selectedPayer != nil
    }

    private func personBinding(for itemName: String) -> Binding<String> {
        Binding(
            get: { selectedPerson[itemName] ?? friends.first?.name ?? "Unknown" },
            set: { newValue in selectedPerson[itemName] = newValue }
        )
    }

    private func calculateAndSaveExpenses() {
        var expensesPerPerson: [String: Double] = [:]

        for item in parsedItems {
            let person = selectedPerson[item.0] ?? "Unknown"
            expensesPerPerson[person, default: 0.0] += item.1
        }

        saveTransaction(expensesPerPerson: expensesPerPerson)
    }

    private func saveTransaction(expensesPerPerson: [String: Double]) {
        guard let payer = selectedPayer else { return }
        let totalAmount = parsedItems.reduce(0) { $0 + $1.1 }
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
            let _ = try db.collection("transactions").addDocument(from: newExpense) { error in
                if let error = error {
                    print("Error saving transaction to Firebase: \(error)")
                    isSaving = false
                } else {
                    transactions.append(newExpense)
                    totalExpense += newExpense.amount
                    balanceManager.updateBalances(with: expensesPerPerson, payer: payer)
                    isSaving = false
                }
            }
        } catch {
            print("Error encoding transaction: \(error)")
            isSaving = false
        }
    }

    private func printFriendsList() {
        if friends.isEmpty {
            print("Friends list is empty.")
        } else {
            print("Friends list:")
            friends.forEach { print($0.name) }
        }
    }
}
