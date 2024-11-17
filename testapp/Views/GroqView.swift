import SwiftUI
import FirebaseFirestore

struct GroqView: View {
    let groupId: String
    @State private var aiOutput: String = ""
    @State private var isLoading: Bool = false
    @Binding var scannedText: String
    @State private var showReceiptScanner = false
    @State private var parsedItems: [(String, Double)] = []
    @State private var tax: Double? = 0.0
    @State private var total: Double? = 0.0
    @State private var showCalculateReceiptView = false
    @ObservedObject var balanceManager: BalanceManager
    @Binding var totalExpense: Double
    @Binding var transactions: [UserExpense]
    @Binding var friends: [Friend]
    @ObservedObject var friendManager: FriendManager
    
    var body: some View {
        NavigationView {
            VStack {
                // Other content or views, if any, can go here.
                Text("Automatic bill calculation")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                Spacer() // Pushes the "Scan Receipt" button to the bottom

                // Scan Receipt Button
                Button("Scan Receipt") {
                    showReceiptScanner.toggle()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black)
                .cornerRadius(8)
                .padding(.bottom, 20) // Optional: Adds space between button and bottom edge of screen

                // NavigationLink for CalculateReceiptView
                NavigationLink(destination: CalculateReceiptView(
                    groupId: groupId,  // Pass groupId here
                    scannedText: $scannedText,
                    parsedItems: $parsedItems,  // Pass parsedItems as a Binding
                    tipAmount: $total,        // Pass totalAmount as a Binding
                    taxAmount: $tax,            // Pass taxAmount as a Binding
                    balanceManager: balanceManager,  // Pass balanceManager
                    transactions: $transactions,    // Pass transactions
                    totalExpense: $totalExpense,    // Pass totalExpense
                    friends: $friends         // Pass friends from FriendManager
                ), isActive: $showCalculateReceiptView) {
                    EmptyView()
                }
                
            }
            .navigationTitle("Scan Receipt")
            .sheet(isPresented: $showReceiptScanner) {
                ReceiptScannerView(
                    scannedText: $scannedText,
                    itemCosts: $parsedItems,
                    totalAmount: $total,
                    taxAmount: $tax
                )
                .onChange(of: scannedText) { _ in
                    // After scanning, pass the scanned text to Groq for formatting
                    formatReceiptText()
                    showCalculateReceiptView = true // Trigger the transition to CalculateReceiptView
                }
            }
        }
    }

    // Function to format the scanned receipt text
    func formatReceiptText() {
        isLoading = true
        
        // Construct the AI prompt with the scanned text
        let prompt = """
        Analyze the following receipt text and extract the details as a structured list with each item, its price, the subtotal, tax, and total:
        
        \(scannedText)
        
        Please format the output in a structured manner:
        - Name: [name], Price: [price]
        - Subtotal: [subtotal]
        - Tax: [tax]
        - Total: [total]
        """
        
        // Assuming LLMService handles the API call and response (modify as needed)
        LLMService().getChatResponse(prompt: prompt) { response in
            DispatchQueue.main.async {
                if let response = response {
                    aiOutput = response
                    parseReceiptData(from: aiOutput)
                } else {
                    aiOutput = "Failed to generate a response."
                }
                isLoading = false
            }
        }
    }

    func parseReceiptData(from aiOutput: String) {
        var items: [(String, Double)] = []
        
        // Split the input into lines
        let lines = aiOutput.split(separator: "\n")
        print("Lines: \(lines)") // Debug the split lines
        
        // Loop through the lines to extract item data
        for line in lines {
            print("Line: \(line)") // Debug the current line
            
            // Parse item and price (assuming format like "1. BBQ Potato Chips, Price: $7.00")
            if line.contains("Price:") {
                // Split the line at the comma, where the item name is before the comma and the price is after
                let components = line.split(separator: ",")
                print("Components: \(components)") // Debug the split components
                
                if components.count > 1 {
                    let itemName = components[0].trimmingCharacters(in: .whitespaces)  // Item name (before comma)
                    let priceString = components[1].split(separator: ":").last?.trimmingCharacters(in: .whitespaces) // Price (after colon)
                    
                    print("Item Name: \(itemName), Price String: \(priceString)") // Debug item name and price
                    
                    // Remove the "$" sign and convert to Double
                    if let price = priceString?.replacingOccurrences(of: "$", with: ""),
                       let itemPrice = Double(price) {
                        print("Parsed Item: \(itemName), Price: \(itemPrice)") // Debug the final parsed item
                        items.append((itemName, itemPrice))
                    }
                }
            }
        }
        
        // Set parsedItems
        self.parsedItems = items
        
        // Debug output to check parsed data
        print("Parsed Items: \(parsedItems)")
    }
}
