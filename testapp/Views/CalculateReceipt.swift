import SwiftUI
import FirebaseFirestore

struct CalculateReceiptView: View {
    let groupId: String
    @Binding var scannedText: String
    @Binding var parsedItems: [(String, Double)]  // Pass parsedItems as a Binding
    @Binding var tipAmount: Double?
    @Binding var taxAmount: Double?
    @ObservedObject var balanceManager: BalanceManager
    @Binding var transactions: [UserExpense]
    @Binding var totalExpense: Double
    @Binding var friends: [Friend]
    
    @State private var selectedPayer: String? = nil
    @State private var selectedPerson: [String: [String]] = [:] // To track who paid for each item (multiple persons)
    @State private var isSaving = false
    @State private var isEditing = false
    @State private var newItemName: String = ""
    @State private var newItemPrice: Double = 0.0
    @State private var newItemPerson: [String] = [] // To allow multiple selections
    @State private var isLoading: Bool = false
    
    var body: some View {
        ScrollView { // Make the entire view scrollable
            VStack {
                Text("Divide Bill")
                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.top)
                                
                                Text("Select who paid for the expense and select which items were purchased by whom.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 10)
                                
                                // Payer Picker (who paid the bill) with a title
                HStack {
                    Text("Who Paid?")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Picker("Who Paid?", selection: $selectedPayer) {
                        ForEach(friends, id: \.id) { friend in
                            Text(friend.name).tag(friend.name as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                    .padding(.vertical, 8)
                }

                // Show the items, prices, tax, and tip
                if parsedItems.isEmpty {
                    Text("Loading Items...")
                        .padding()
                } else {
                    // Items Picker for each parsed item
                    ForEach(parsedItems, id: \.0) { item in
                        HStack {
                            if isEditing {
                                // Editable item name
                                TextField("Item Name", text: Binding(
                                    get: { item.0 },
                                    set: { parsedItems[parsedItems.firstIndex(where: { $0.0 == item.0 })!].0 = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 150)

                                // Editable price
                                TextField("Price", value: Binding(
                                    get: { item.1 },
                                    set: { parsedItems[parsedItems.firstIndex(where: { $0.0 == item.0 })!].1 = $0 }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            } else {
                                // Display the item name and price if not in edit mode
                                Text("\(item.0): $\(item.1, specifier: "%.2f")")
                            }

                            // Multi-Select Picker (Who Ordered this item?)
                            if !isEditing {
                                MultiSelectPicker(selectedItems: bindingForItem(item.0), friends: friends)
                                    .frame(width: 150)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Editable Tax field
                if isEditing {
                    HStack {
                        Text("Tax:")
                        TextField("Tax", value: $taxAmount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    .padding()

                    // Editable Tip field (formerly "Total")
                    HStack {
                        Text("Tip:")
                        TextField("Tip", value: $tipAmount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    .padding()
                } else {
                    // Display Tax and Tip if not in edit mode
                    Text("Tax: $\(taxAmount ?? 0.0, specifier: "%.2f")")
                        .padding()

                    Text("Tip: $\(tipAmount ?? 0.0, specifier: "%.2f")")
                        .padding()
                }

                // Add Item Button (only visible when editing)
                if isEditing {
                    VStack {
                        HStack {
                            TextField("Item Name", text: $newItemName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 150)
                            TextField("Price", value: $newItemPrice, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                        }
                        .padding(.vertical)

                        MultiSelectPicker(selectedItems: $newItemPerson, friends: friends)
                            .frame(width: 150)

                        Button("Add Item") {
                            addItem()
                        }
                        .padding(.top)
                    }
                }

                // Buttons for editing and finishing
                HStack {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing.toggle()
                        }
                    }
                    .padding()

                    Button("Finish") {
                        calculateAndSaveExpenses()
                    }
                    .padding()
                    .disabled(!isFormComplete() || isSaving)
                }
            }
            .onAppear {
                print("Parsed Items in CalculateReceiptView: \(parsedItems)")
            }
        }
    }

    // Check if the form is complete (all items have been assigned to someone)
    private func isFormComplete() -> Bool {
        return parsedItems.allSatisfy { selectedPerson[$0.0] != nil } && selectedPayer != nil
    }

    // Add new item to parsedItems
    private func addItem() {
        guard !newItemName.isEmpty, newItemPrice > 0 else {
            return // Ensure item has a name and a positive price
        }
        
        let newItem = (newItemName, newItemPrice)
        parsedItems.append(newItem)
        newItemName = ""
        newItemPrice = 0.0
        newItemPerson = []
    }

    // Save changes to item details
    private func saveChanges() {
        // Here you can apply logic to save the changes and update the parsedItems
        // If you want to update all the fields, you can loop through `parsedItems` and apply necessary changes.
        isEditing.toggle() // Toggle off the editing mode
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
            let persons = selectedPerson[item.0] ?? []
            let amountPerPerson = item.1 / Double(persons.count)
            for person in persons {
                expensesPerPerson[person, default: 0.0] += amountPerPerson
            }
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
        guard let tipAmount = tipAmount else {
            print("Error: No total amount selected.")
            return
        }

        // Create a new transaction object
        let newExpense = UserExpense(
            amount: 0,  // Ensure the totalAmount is passed correctly
            date: Date(),
            description: nil,
            splitDetails: expensesPerPerson,
            participants: Array(expensesPerPerson.keys),  // Participants who have split the expense
            payer: payer  // The person who paid
        )

        isLoading = true // Start loading

        // Save the new expense to Firestore within the specific group
        let db = Firestore.firestore()
        do {
            let documentId = newExpense.id.uuidString // Set document ID to UUID
            try db.collection("groups")
                .document(groupId)
                .collection("transactions")
                .document(documentId)
                .setData(from: newExpense) { error in
                    if let error = error {
                        print("Error saving transaction: \(error)")
                    } else {
                        print("Transaction saved successfully!")
                        // Update UI after saving the transaction
                        DispatchQueue.main.async {
                            transactions.append(newExpense)  // Add the transaction to the local list
                            totalExpense += newExpense.amount  // Update the total expense
                            balanceManager.updateBalances(with: expensesPerPerson, payer: payer)  // Update balances
                        }
                    }
                    isLoading = false  // End loading
                }
        } catch {
            print("Error encoding transaction: \(error)")
            isLoading = false
        }
    }




    // Helper function to create a binding for each item
    private func bindingForItem(_ itemName: String) -> Binding<[String]> {
        Binding(
            get: { selectedPerson[itemName] ?? [] },
            set: { selectedPerson[itemName] = $0 }
        )
    }
}




// Multi-Select Picker for selecting multiple friends for an item

struct MultiSelectPicker: View {
    @Binding var selectedItems: [String]
    var friends: [Friend]
    
    @State private var isSelecting = false // Flag to trigger the visibility of the list
    
    var body: some View {
        VStack {
            // Show selected friends in a button
            Button(action: {
                isSelecting.toggle() // Toggle the visibility of the friend list
            }) {
                HStack {
                    Text(selectedItems.isEmpty ? "Select Friends" : selectedItems.joined(separator: ", "))
                        .foregroundColor(.blue)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.down.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // If isSelecting is true, show the list of friends
            if isSelecting {
                List(friends, id: \.id) { friend in
                    HStack {
                        Text(friend.name)
                        Spacer()
                        Image(systemName: selectedItems.contains(friend.name) ? "checkmark.circle.fill" : "circle")
                            .onTapGesture {
                                toggleSelection(for: friend.name)
                            }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 200) // Limit the height for the list
            }
        }
        .padding()
    }
    
    private func toggleSelection(for friendName: String) {
        if selectedItems.contains(friendName) {
            selectedItems.removeAll { $0 == friendName }
        } else {
            selectedItems.append(friendName)
        }
    }
}
