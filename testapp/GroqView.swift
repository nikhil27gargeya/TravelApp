import SwiftUI

struct GroqView: View {
    @State private var aiOutput: String = "Scanned text will appear here."
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
                // Display the scanned and formatted receipt text
                Text(aiOutput)
                    .padding()
                
                // Scan Receipt Button
                Button("Scan Receipt") {
                    showReceiptScanner.toggle()
                }
                .foregroundColor(.green)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                // Transition to CalculateReceiptView after scanning
                NavigationLink(destination: CalculateReceiptView(
                                    scannedText: $scannedText,
                                    parsedItems: $parsedItems,  // Pass parsedItems as a Binding
                                    totalAmount: $total,
                                    taxAmount: $tax,
                                    balanceManager: balanceManager,  // Pass balanceManager
                                    transactions: $transactions,    // Pass transactions
                                    totalExpense: $totalExpense,    // Pass totalExpense
                                    friends: $friendManager.friends // Pass friends from FriendManager
                                ), isActive: $showCalculateReceiptView) {
                    EmptyView()
                }

                Spacer()
            }
            .navigationTitle("Receipt Scanner")
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
        - Item: [name], Price: [price]
        - Subtotal: [subtotal]
        - Tax: [tax]
        - Total: [total]
        """
        
        // Assuming LLMService handles the API call and response (modify as needed)
        LLMService().getChatResponse(prompt: prompt) { response in
            DispatchQueue.main.async {
                if let response = response {
                    aiOutput = response
                } else {
                    aiOutput = "Failed to generate a response."
                }
                isLoading = false
            }
        }
    }
}

