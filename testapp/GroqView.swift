import SwiftUI

struct GroqView: View {
    @State private var aiOutput: String = "Press the button to generate AI output."
    @State private var isLoading: Bool = false
    @Binding var scannedText: String
    
    var body: some View {
        NavigationView {
            VStack {
                Text(aiOutput)
                    .padding()
                
                Button(action: {
                    generateAIOutput()
                }) {
                    Text("Generate AI Output")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Test AI Output")
        }
    }
    
    func generateAIOutput() {
        isLoading = true
                
                // This is the example receipt text for testing purposes
                let receiptText = """
                
                LITTLE ITALY
                92 RUE MONTORGUEIL 75002 PARIS FRANCE
                SIRET 39032103200026 NAF:5610A TUA:FR Tel: 01.42.36.36.25
                TABLE
                27
                5 COUVERT
                ARTHUR
                2 LINGUINE PESTO 15.00
                30.00 C
                1 RIGATONI AMATRICIANA
                16.00 C
                1 PENNE ARRABBIATA
                13.00 C
                1 LASAGNE CARNE
                16.00 C
                1 PERONI NASTRO AZZURRO
                6.00 B
                2 VERRE PROSECCO
                6.00
                12.00 B
                1 MIMOSA
                7.00 B
                TOTAL
                100.00
                """
                
                let prompt = """
                Analyze the following receipt text and extract the details as a structured list with each item, its price, the subtotal, tax, and total:
                
                \(receiptText)
                
                Please format the output in a structured manner:
                - Item: [name], Price: [price]
                ...
                - Subtotal: [subtotal]
                - Tax: [tax]
                - Total: [total]
                """
                
                // Call LLMService to get the response
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

struct GroqView_Previews: PreviewProvider {
    @State static var scannedText = "Sample scanned receipt text."
    static var previews: some View {
        GroqView(scannedText: $scannedText)
    }
}
