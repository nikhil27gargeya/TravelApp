import Foundation
import SwiftUI

struct CalculateReceiptView: View {
    @State private var parsedItems: [(String, Double)] = [] // [(itemName, price)]
    @State private var selectedPerson: [String: String] = [:] // Stores who bought each item
    @Binding var friends: [Friend]

    var body: some View {
        VStack {
            ForEach(parsedItems, id: \.0) { item in
                HStack {
                    Text("\(item.0): $\(item.1, specifier: "%.2f")")
                    Picker("Who Bought?", selection: personBinding(for: item.0)) {
                        ForEach(friends, id: \.id) { friend in
                            Text(friend.name).tag(friend.name) // Use friend's name for tagging
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150) // Set a fixed width for the picker for better layout
                }
                .padding(.vertical, 4) // Add vertical padding for better spacing
            }

            Button("Finish") {
                calculateExpenses()
            }
            .padding()
            .buttonStyle(BorderlessButtonStyle())
            .disabled(!isFormComplete()) // Disable if form is incomplete
        }
        .onAppear {
            loadParsedItems()
        }
    }

    // Function to get a binding for each person selection in the dictionary
    private func personBinding(for itemName: String) -> Binding<String> {
        Binding(
            get: { selectedPerson[itemName] ?? friends.first?.name ?? "Unknown" },
            set: { selectedPerson[itemName] = $0 }
        )
    }

    // Check if all items have a selected friend
    private func isFormComplete() -> Bool {
        return parsedItems.allSatisfy { selectedPerson[$0.0] != nil }
    }

    // Calculate expenses based on selectedPerson dictionary
    func calculateExpenses() {
        var expensesPerPerson: [String: Double] = [:]
        for item in parsedItems {
            let person = selectedPerson[item.0] ?? "Unknown"
            expensesPerPerson[person, default: 0.0] += item.1
        }
        
        // Logic to update the balances based on expensesPerPerson
        updateBalances(with: expensesPerPerson)
    }

    // Load parsed items (for demonstration)
    func loadParsedItems() {
        parsedItems = [("Coffee", 4.50), ("Sandwich", 7.25), ("Salad", 6.00)] // Placeholder data
    }
    
    // Function to update balances
    func updateBalances(with expenses: [String: Double]) {
        // Your balance update logic here
        print("Updated balances: \(expenses)")
    }
}

struct CalculateReceiptView_Previews: PreviewProvider {
    static var previews: some View {
        return CalculateReceiptView(friends: .constant(loadFriends()))
    }
}
