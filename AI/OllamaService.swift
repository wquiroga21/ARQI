import Foundation

@MainActor
class OllamaService {
    // Use a configurable URL that can be changed at runtime
    private var baseURL: String = "https://db53-4-43-60-6.ngrok-free.app/api/generate"
    
    // Make this nonisolated so it can be accessed from anywhere
    nonisolated private func getBaseServerURL(from url: String) -> String {
        if url.hasSuffix("/api/generate") {
            return String(url.dropLast("/api/generate".count))
        }
        return url
    }
    
    private var availableModels: [String] = []
    
    // Allow changing the base URL (for testing or configuration)
    func configure(baseURL: String? = nil) async {
        if let url = baseURL, !url.isEmpty {
            self.baseURL = url
            // Refresh models when URL changes
            await refreshAvailableModels()
        }
    }
    
    // Refresh available models
    func refreshAvailableModels() async {
        do {
            self.availableModels = try await fetchAvailableModels()
        } catch {
            print("OllamaService - Failed to refresh models: \(error.localizedDescription)")
        }
    }
    
    // Fetch available models from Ollama
    nonisolated func fetchAvailableModels() async throws -> [String] {
        // Get a local copy of baseURL to use in this nonisolated context
        let currentBaseURL = await baseURL
        let modelsURL = "\(getBaseServerURL(from: currentBaseURL))/api/tags"
        
        guard let url = URL(string: modelsURL) else {
            print("OllamaService - Invalid URL for models: \(modelsURL)")
            throw URLError(.badURL)
        }
        
        print("OllamaService - Fetching models from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        struct ModelsResponse: Codable {
            struct Model: Codable {
                let name: String
            }
            let models: [Model]
        }
        
        let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return modelsResponse.models.map { $0.name }
    }
    
    func generateResponse(prompt: String, model: String = "mistral:latest") async throws -> String {
        // Check if we have fetched available models
        if availableModels.isEmpty {
            await refreshAvailableModels()
        }
        
        // Validate model availability
        if !availableModels.contains(model) {
            print("OllamaService - Model '\(model)' not found. Using default model.")
            // Don't throw an error, just log and continue with the model provided
        }
        
        guard let url = URL(string: baseURL) else {
            print("OllamaService - Invalid URL: \(baseURL)")
            throw URLError(.badURL)
        }
        
        // Adjust parameters based on model
        let isDeepseek = model.lowercased().contains("deepseek")
        let isGemma = model.lowercased().contains("gemma")
        
        print("OllamaService - Using model: \(model), isDeepseek: \(isDeepseek), isGemma: \(isGemma)")
        
        let requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "raw": true,  // Add raw mode for better compatibility
            "context_window": isDeepseek || isGemma ? 8192 : 4096,  // Reduced context window for faster responses
            "num_ctx": isDeepseek || isGemma ? 8192 : 4096,  // Reduced context parameter
            "timeout": isDeepseek || isGemma ? 120 : 60,  // Reduced timeout for faster responses
            "temperature": isGemma ? 0.8 : (isDeepseek ? 0.7 : 0.8),  // Higher temperature for Gemma to make responses more concise
            "num_predict": isGemma ? 300 : (isDeepseek ? 1024 : 512),  // Limit token generation for faster responses
            "top_p": isGemma ? 0.95 : 1.0,  // Add top_p for more focused, concise responses
            "top_k": isGemma ? 40 : 50  // Add top_k for faster, more focused responses
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Increase timeout even more
        request.timeoutInterval = 60  // Increased to 60 seconds
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        print("OllamaService - Sending request to \(url.absoluteString) with model: \(model)")
        print("OllamaService - Request parameters: \(requestBody)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("OllamaService - Invalid response type")
                throw URLError(.badServerResponse)
            }
            
            print("OllamaService - Response status code: \(httpResponse.statusCode)")
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                do {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("OllamaService - Raw response received, length: \(responseString.count)")
                    }
                    
                    struct OllamaResponse: Codable {
                        let response: String
                    }
                    
                    let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
                    return ollamaResponse.response
                } catch {
                    print("OllamaService - Failed to decode response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("OllamaService - Raw response: \(responseString)")
                        // Try to extract response from raw string if JSON parsing fails
                        if let responseContent = responseString.components(separatedBy: "\"response\":").last?
                            .components(separatedBy: "\"").dropFirst().first {
                            return responseContent
                        }
                    }
                    throw error
                }
                
            case 408, 504: // Timeout errors
                print("OllamaService - Request timed out")
                throw URLError(.timedOut)
                
            case 500...599: // Server errors
                print("OllamaService - Server error: \(httpResponse.statusCode)")
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("OllamaService - Error response: \(errorResponse)")
                }
                throw URLError(.badServerResponse)
                
            default:
                if let errorResponse = String(data: data, encoding: .utf8) {
                    print("OllamaService - Unexpected status code \(httpResponse.statusCode): \(errorResponse)")
                    throw NSError(domain: "OllamaError", 
                                code: httpResponse.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: errorResponse])
                } else {
                    print("OllamaService - Unexpected status code \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
            }
        } catch {
            print("OllamaService - Request failed: \(error.localizedDescription)")
            // Convert the error to a more specific one if possible
            switch error {
            case is DecodingError:
                throw NSError(domain: "OllamaError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to decode response: \(error.localizedDescription)"])
            default:
                throw error
            }
        }
    }
} 