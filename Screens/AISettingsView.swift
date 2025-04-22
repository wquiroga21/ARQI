import SwiftUI

struct AISettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var aiManager: AIManager
    @EnvironmentObject var aiProfile: UserAIProfile
    
    @State private var serverAddress: String = ""
    @State private var selectedModel: String = "mistral:latest"
    @State private var customPersonality: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isTestingConnection = false
    
    private let personalityPresets = [
        "Default": "You are a friendly AI assistant. Be helpful, concise, and accurate. IMPORTANT: Never generate or insert text prefixed with 'User:' as that makes it seem like you're speaking for the user. Only respond as yourself, the AI assistant.",
        "Academic": "You are an academic AI assistant. Provide detailed, well-researched responses with scholarly references when possible. IMPORTANT: Never generate or insert text prefixed with 'User:' as that makes it seem like you're speaking for the user. Only respond as yourself, the AI assistant.",
        "Creative": "You are a creative AI partner. Think outside the box and offer innovative perspectives and ideas. IMPORTANT: Never generate or insert text prefixed with 'User:' as that makes it seem like you're speaking for the user. Only respond as yourself, the AI assistant.",
        "Professional": "You are a professional AI assistant. Keep responses formal, precise, and business-oriented. IMPORTANT: Never generate or insert text prefixed with 'User:' as that makes it seem like you're speaking for the user. Only respond as yourself, the AI assistant.",
        "Casual": "You are a casual AI friend. Keep things light, conversational, and use simple language. IMPORTANT: Never generate or insert text prefixed with 'User:' as that makes it seem like you're speaking for the user. Only respond as yourself, the AI assistant.",
        "Custom": ""
    ]
    
    @State private var selectedPersonalityPreset = "Default"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration").foregroundColor(Color.primaryText)) {
                    TextField("Server Address", text: $serverAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    Text("Examples: https://db53-4-43-60-6.ngrok-free.app or https://6740-4-43-60-6.ngrok-free.app")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    
                    HStack {
                        Text("Status:")
                            .foregroundColor(Color.primaryText)
                        
                        connectionStatusView
                        
                        Spacer()
                        
                        Button(action: testConnection) {
                            Text("Test")
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.buttonColor)
                                .cornerRadius(8)
                        }
                        .disabled(isTestingConnection)
                    }
                    
                    if aiManager.isLoadingModels {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Fetching available models...")
                                .font(.caption)
                                .foregroundColor(Color.secondaryText)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: refreshModels) {
                            Label("Refresh Models", systemImage: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(Color.primaryAccent)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Model Selection").foregroundColor(Color.primaryText)) {
                    if aiManager.availableModels.isEmpty {
                        Text("No models found. Make sure Ollama is running.")
                            .foregroundColor(Color.red)
                            .font(.caption)
                    } else {
                        Picker("AI Model", selection: $selectedModel) {
                            ForEach(aiManager.availableModels, id: \.self) { model in
                                Text(model)
                                    .foregroundColor(Color.primaryText)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(Color.primaryText)
                    }
                    
                    Text("Select the AI model running on your Ollama server.")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
                
                Section(header: Text("AI Personality").foregroundColor(Color.primaryText)) {
                    Picker("Personality Preset", selection: $selectedPersonalityPreset) {
                        ForEach(Array(personalityPresets.keys).sorted(), id: \.self) { preset in
                            Text(preset)
                                .foregroundColor(Color.primaryText)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(Color.primaryText)
                    .onChange(of: selectedPersonalityPreset) { oldValue, newValue in
                        if newValue == "Custom" {
                            // Don't change customPersonality when selecting Custom
                            // This allows users to keep their custom text
                        } else if let presetPrompt = personalityPresets[newValue] {
                            customPersonality = presetPrompt
                        }
                    }
                    
                    Text("Or create a custom personality:")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                    
                    TextEditor(text: $customPersonality)
                        .frame(minHeight: 100)
                        .foregroundColor(Color.primaryText)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                    
                    Text("Important: Always include instructions to prevent the AI from generating 'User:' messages. Example: 'IMPORTANT: Never generate or insert text prefixed with User:' as that makes it seem like you're speaking for the user.'")
                        .font(.caption)
                        .foregroundColor(Color.accentColor)
                        .padding(.top, 4)
                }
                
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        Text("Save Settings")
                            .bold()
                        Spacer()
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding()
                .background(Color.primaryAccent)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.vertical, 8)
                
                troubleshootingSection
            }
            .navigationBarTitle("AI Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("AI Settings"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadCurrentSettings()
                refreshModels()
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        }
    }
    
    private var connectionStatusView: some View {
        HStack {
            let (color, text) = statusDetails
            
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(text)
                .foregroundColor(Color.primaryText)
                .font(.subheadline)
                .lineLimit(1)
        }
    }
    
    private var statusDetails: (Color, String) {
        switch aiManager.serverConnectionStatus {
        case .connected:
            return (Color.green, "Connected")
        case .disconnected:
            return (Color.red, "Disconnected")
        case .error(let message):
            return (Color.red, "Error: \(message)")
        case .unknown:
            return (Color.orange, "Unknown")
        }
    }
    
    private func loadCurrentSettings() {
        // Extract server address from URL
        let fullAddress = aiManager.serverConnectionStatus.isConnected ?
            aiManager.serverAddress : "https://db53-4-43-60-6.ngrok-free.app"
        
        // Log the address for debugging
        print("AISettingsView - Loading settings with address: \(fullAddress)")
        
        // Remove http:// or https:// for display
        serverAddress = fullAddress.replacingOccurrences(of: "http://", with: "")
                                  .replacingOccurrences(of: "https://", with: "")
        
        // Set the selected model
        selectedModel = aiManager.currentModel
        
        // Set personality
        if let preset = personalityPresets.first(where: { $0.value == aiManager.personalityPrompt })?.key {
            selectedPersonalityPreset = preset
            customPersonality = personalityPresets[preset] ?? ""
        } else {
            selectedPersonalityPreset = "Custom"
            customPersonality = aiManager.personalityPrompt
        }
    }
    
    private func testConnection() {
        guard !serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a valid server address"
            showingAlert = true
            return
        }
        
        isTestingConnection = true
        
        // Format the address with proper protocol
        var formattedAddress = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Smart protocol selection: use HTTP for IP addresses, HTTPS for domain names
        if !formattedAddress.hasPrefix("http://") && !formattedAddress.hasPrefix("https://") {
            // Check if this is an IP address or domain
            if formattedAddress.contains(":") || 
               formattedAddress.matches(pattern: "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}") {
                // IP address or IP:PORT format - use HTTP
                formattedAddress = "http://" + formattedAddress
                print("Using HTTP for IP address: \(formattedAddress)")
            } else {
                // Domain name - use HTTPS
                formattedAddress = "https://" + formattedAddress
                print("Using HTTPS for domain: \(formattedAddress)")
            }
        }
        
        print("Testing connection to: \(formattedAddress)")
        
        // Configure the AI manager with new address for testing
        aiManager.configure(serverAddress: formattedAddress)
        
        // Also refresh models as part of the test
        Task {
            await aiManager.fetchAvailableModels()
        }
        
        // Wait for connection status update
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // Increased timeout to allow for model fetch
            isTestingConnection = false
            
            switch aiManager.serverConnectionStatus {
            case .connected:
                if aiManager.availableModels.isEmpty {
                    alertMessage = "Connected to the server, but no models found. Make sure you have models installed in Ollama."
                } else {
                    alertMessage = "Successfully connected to the AI server. Found \(aiManager.availableModels.count) models: \(aiManager.availableModels.joined(separator: ", "))"
                }
            case .disconnected:
                alertMessage = "Disconnected from the AI server"
            case .error(let message):
                alertMessage = "Error connecting to the server: \(message)\n\nTroubleshooting Tips:\n1. Make sure Ollama is running\n2. Verify the URL is correct (\(formattedAddress))\n3. If using ngrok, make sure the tunnel is active\n4. Try both http:// and https:// protocols if one doesn't work"
            case .unknown:
                alertMessage = "Connection status unknown. Please try again."
            }
            
            showingAlert = true
        }
    }
    
    private func saveSettings() {
        guard !serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a valid server address"
            showingAlert = true
            return
        }
        
        // Format the address with proper protocol
        var formattedAddress = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Smart protocol selection: use HTTP for IP addresses, HTTPS for domain names
        if !formattedAddress.hasPrefix("http://") && !formattedAddress.hasPrefix("https://") {
            // Check if this is an IP address or domain
            if formattedAddress.contains(":") || 
               formattedAddress.matches(pattern: "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}") {
                // IP address or IP:PORT format - use HTTP
                formattedAddress = "http://" + formattedAddress
                print("Using HTTP for IP address: \(formattedAddress)")
            } else {
                // Domain name - use HTTPS
                formattedAddress = "https://" + formattedAddress
                print("Using HTTPS for domain: \(formattedAddress)")
            }
        }
        
        print("AISettingsView - Saving settings with address: \(formattedAddress)")
        
        // Save settings to AIManager
        aiManager.configure(
            serverAddress: formattedAddress,
            model: selectedModel,
            personality: customPersonality
        )
        
        // Update UserAIProfile with relevant settings
        aiProfile.aiTone = selectedPersonalityPreset
        aiProfile.aiServerAddress = formattedAddress
        aiProfile.aiModel = selectedModel
        aiProfile.aiPersonality = customPersonality
        
        // Save settings to UserDefaults with consistent keys
        UserDefaults.standard.set(formattedAddress, forKey: "ai_server_address")
        UserDefaults.standard.set(formattedAddress, forKey: "serverAddress")  // Add this for consistency
        UserDefaults.standard.set(selectedModel, forKey: "ai_model")
        UserDefaults.standard.set(selectedModel, forKey: "currentModel")  // Add this for consistency
        UserDefaults.standard.set(customPersonality, forKey: "ai_personality")
        UserDefaults.standard.set(customPersonality, forKey: "personalityPrompt")  // Add this for consistency
        UserDefaults.standard.set(selectedPersonalityPreset, forKey: "ai_personality_preset")
        
        alertMessage = "Settings saved successfully"
        showingAlert = true
    }
    
    private func refreshModels() {
        Task {
            await aiManager.fetchAvailableModels()
            
            // Update selected model after refresh if needed
            DispatchQueue.main.async {
                if !aiManager.availableModels.isEmpty && 
                   !aiManager.availableModels.contains(selectedModel) {
                    selectedModel = aiManager.availableModels[0]
                }
            }
        }
    }
    
    // Add a troubleshooting section to the view
    private var troubleshootingSection: some View {
        Section(header: Text("Troubleshooting").foregroundColor(Color.primaryText)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Common Issues")
                    .font(.headline)
                    .foregroundColor(Color.primaryText)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Make sure Ollama is running")
                    Text("• For local connections, use your computer's IP with port 11434")
                    Text("• Example local: http://192.168.1.5:11434")
                    Text("• For ngrok, use the full URL provided (https://xxxx-xx-xx-xx-x.ngrok-free.app)")
                    Text("• No need to add /api/generate - the app will add it automatically")
                    Text("• Check firewall settings to ensure port 11434 is open")
                }
                .font(.caption)
                .foregroundColor(Color.secondaryText)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Extensions
extension AIManager.ServerStatus {
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

extension String {
    func matches(pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.count > 0
        } catch {
            return false
        }
    }
}

// MARK: - Preview
struct AISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AISettingsView(aiManager: AIManager(chatType: .mainChat))
            .environmentObject(UserAIProfile())
            .preferredColorScheme(.light)
    }
}
