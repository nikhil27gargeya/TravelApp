import SwiftUI

struct GroqView: View {
    @State private var aiOutput: String = "Press the button to generate AI output."
    
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
        let prompt = "Hello, AI! Generate a fun fact about programming."
        
        // Replace LLMService() with the actual service you have integrated (e.g., Groq)
        LLMService().getChatResponse(prompt: prompt) { response in
            DispatchQueue.main.async {
                if let response = response {
                    aiOutput = response
                } else {
                    aiOutput = "Failed to generate a response."
                }
            }
        }
    }
}

struct GroqView_Previews: PreviewProvider {
    static var previews: some View {
        GroqView()
    }
}
