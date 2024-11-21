import Foundation

class LLMService {
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
    private let apiUrl = "https://api.groq.com/openai/v1/chat/completions"

    func getChatResponse(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: apiUrl) else {
            print("Invalid URL")
            completion(nil)
            return
        }

        // Prepare URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare JSON request body
        let parameters: [String: Any] = [
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "model": "llama3-8b-8192", // Replace with the appropriate model you are using
            "temperature": 1,
            "max_tokens": 1024,
            "top_p": 1,
            "stream": false
        ]

        // Convert parameters to JSON data
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters) else {
            print("Failed to serialize parameters")
            completion(nil)
            return
        }

        request.httpBody = httpBody

        // Perform request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle error
            if let error = error {
                print("Error during API request: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Print HTTP response status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status Code: \(httpResponse.statusCode)")
            }

            // Handle response and parse JSON
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Response JSON: \(json)")
                        if let choices = json["choices"] as? [[String: Any]],
                           let content = choices.first?["message"] as? [String: Any],
                           let responseText = content["content"] as? String {
                            completion(responseText)
                        } else {
                            print("Unexpected response format")
                            completion(nil)
                        }
                    }
                } catch {
                    print("Error parsing response data: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }

        task.resume() // Start the network request
    }
}
