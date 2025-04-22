//
//  ProfileView.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var userProfile: UserAIProfile
    @State private var showingAccountSettings = false
    @State private var showingSignOutConfirmation = false
    @State private var saveSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // User profile section
                userProfileSection
                
                // Account settings section
                accountSettingsSection
                
                // App info section
                appInfoSection
                
                // Sign out button
                signOutButton
            }
            .padding()
        }
        .navigationTitle("Profile")
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingAccountSettings) {
            accountSettingsView
        }
        .sheet(isPresented: $showingNotificationsSheet) {
            NotificationsView()
        }
        .sheet(isPresented: $showingPrivacySheet) {
            PrivacyView()
        }
        .sheet(isPresented: $showingHelpSupportSheet) {
            HelpSupportView()
        }
        .alert(isPresented: $showingSignOutConfirmation) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign Out")) {
                    authService.signOut()
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(
            saveSuccess ?
            VStack {
                Spacer()
                Text("Settings Saved")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.primaryAccent)
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                saveSuccess = false
                            }
                        }
                    }
            }
            : nil
        )
        .onAppear {
            setupNotificationObservers()
        }
        .onDisappear {
            removeNotificationObservers()
        }
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowAccountSettings"),
            object: nil,
            queue: .main
        ) { _ in
            showingAccountSettings = true
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - User Profile Section
    
    private var userProfileSection: some View {
        VStack(spacing: 15) {
            // User avatar and info
            HStack(spacing: 15) {
                // User avatar
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 70, height: 70)
                    
                    Text(userInitials)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(userName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryText)
                    
                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundColor(Color.secondaryText)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Account Settings Section
    
    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Account Settings")
                .font(.headline)
                .foregroundColor(Color.primaryText)
            
            VStack(spacing: 4) {
                // Notification preferences
                settingsRow(title: "Notifications", icon: "bell.fill", showDisclosure: true) {
                    showNotifications()
                }
                
                Divider()
                
                // Data & Privacy
                settingsRow(title: "Data & Privacy", icon: "lock.fill", showDisclosure: true) {
                    showPrivacy()
                }
                
                Divider()
                
                // Help & Support
                settingsRow(title: "Help & Support", icon: "questionmark.circle.fill", showDisclosure: true) {
                    showHelpSupport()
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("App Info")
                .font(.headline)
                .foregroundColor(Color.primaryText)
            
            VStack(spacing: 10) {
                HStack {
                    Text(Constants.appName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primaryText)
                    
                    Spacer()
                    
                    Text("Version \(Constants.appVersion) (\(Constants.appBuild))")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
                
                Divider()
                
                HStack {
                    Text("© 2025 Senior Project Team")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Sign Out Button
    
    private var signOutButton: some View {
        Button(action: {
            if authService.isSignedIn {
                showingSignOutConfirmation = true
            } else {
                // Navigate to sign in screen or show sign in sheet
                authService.showSignIn()
            }
        }) {
            HStack {
                Image(systemName: authService.isSignedIn ? "arrow.right.square" : "person.fill.badge.plus")
                Text(authService.isSignedIn ? "Sign Out" : "Sign In")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(authService.isSignedIn ? Color.red : Color.primaryAccent)
            .cornerRadius(10)
            .shadow(color: (authService.isSignedIn ? Color.red : Color.primaryAccent).opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Account Settings View
    
    private var accountSettingsView: some View {
        NavigationView {
            List {
                Section(header: Text("Notifications").foregroundColor(Color.primaryText)) {
                    Toggle("Push Notifications", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("Email Notifications", isOn: .constant(false))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                }
                
                Section(header: Text("Privacy").foregroundColor(Color.primaryText)) {
                    Toggle("Share Usage Data", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("Save Chat History", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                }
                
                Section(header: Text("Security").foregroundColor(Color.primaryText)) {
                    Button("Change Password") {
                        // Change password logic
                    }
                    .foregroundColor(Color.primaryAccent)
                    
                    Button("Two-Factor Authentication") {
                        // 2FA setup logic
                    }
                    .foregroundColor(Color.primaryAccent)
                }
                
                Section(header: Text("Danger Zone").foregroundColor(Color.primaryText)) {
                    Button("Delete Account") {
                        // Account deletion logic
                    }
                    .foregroundColor(.red)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("Account Settings")
            .navigationBarItems(trailing: Button("Done") {
                showingAccountSettings = false
            }
            .foregroundColor(Color.primaryAccent))
        }
    }
    
    // MARK: - Helper Views
    
    private func settingsRow(title: String, icon: String, showDisclosure: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.primaryAccent)
                    .frame(width: 30)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color.primaryText)
                
                Spacer()
                
                if showDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Functions
    
    // MARK: - Computed Properties
    
    private var userName: String {
        authService.user?.displayName ?? "User"
    }
    
    private var userEmail: String {
        authService.user?.email ?? "No email"
    }
    
    private var userInitials: String {
        String(userName.prefix(1)).uppercased()
    }
    
    // MARK: - Feature Sheet Views
    @State private var showingNotificationsSheet = false
    @State private var showingPrivacySheet = false
    @State private var showingHelpSupportSheet = false
    
    private func showNotifications() {
        showingNotificationsSheet = true
    }
    
    private func showPrivacy() {
        showingPrivacySheet = true
    }
    
    private func showHelpSupport() {
        showingHelpSupportSheet = true
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Push Notifications")) {
                    Toggle("New Messages", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("Debate Invites", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("Topic Updates", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("AI Mission Completed", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                }
                
                Section(header: Text("Email Notifications")) {
                    Toggle("Weekly Digest", isOn: .constant(false))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("New Features", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("Account Updates", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                }
                
                Section(header: Text("Sounds")) {
                    Toggle("Message Sounds", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    Toggle("AI Response Sound", isOn: .constant(false))
                        .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Notifications")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Data Collection & Privacy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    privacySection(
                        title: "Data Collection",
                        content: "We collect minimal data necessary to provide you with the best experience. This includes chat history, AI interactions, and user preferences. All data is stored securely and never shared with third parties without your explicit consent."
                    )
                    
                    privacySection(
                        title: "Local Storage",
                        content: "Your conversations with the AI are stored locally on your device by default. You can choose to delete this data at any time through the settings."
                    )
                    
                    privacySection(
                        title: "AI Training",
                        content: "To improve our AI models, we may use anonymized conversation data. This data is stripped of all personal identifiers before being used for training purposes."
                    )
                    
                    privacySection(
                        title: "Your Rights",
                        content: "You have the right to access, correct, or delete your personal data at any time. You can request a copy of all data we hold about you by contacting our support team."
                    )
                    
                    Text("For more information, please see our full Privacy Policy.")
                        .font(.subheadline)
                        .foregroundColor(Color.secondaryText)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Privacy")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.primaryText)
            
            Text(content)
                .font(.body)
                .foregroundColor(Color.secondaryText)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(10)
    }
}

// MARK: - Help & Support View
struct HelpSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Common Questions")) {
                    helpRow(question: "How does the AI chatbot work?", 
                           answer: "Our AI chatbot uses advanced language models to understand and respond to your messages. It learns from interactions while keeping your privacy secure.")
                    
                    helpRow(question: "What are AI Missions?", 
                           answer: "AI Missions are tasks you can send your AI on to gather diverse perspectives and insights on topics you're interested in.")
                    
                    helpRow(question: "How do I start a debate?", 
                           answer: "You can start a debate by selecting a trending topic from the Explorer page and tapping on 'Let's Debate'.")
                }
                
                Section(header: Text("Contact Us")) {
                    Button(action: {
                        // Open email
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color.primaryAccent)
                            Text("Email Support")
                                .foregroundColor(Color.primaryText)
                        }
                    }
                    
                    Button(action: {
                        // Open website
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(Color.primaryAccent)
                            Text("Visit Our Website")
                                .foregroundColor(Color.primaryText)
                        }
                    }
                    
                    Button(action: {
                        // Open feedback form
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color.primaryAccent)
                            Text("Send Feedback")
                                .foregroundColor(Color.primaryText)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    Text("Version \(Constants.appVersion) (\(Constants.appBuild))")
                    Text("© 2025 Senior Project Team")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Help & Support")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func helpRow(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(.headline)
                .foregroundColor(Color.primaryText)
            
            Text(answer)
                .font(.subheadline)
                .foregroundColor(Color.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

// Add an extension for the AuthenticationService to check if user is signed in
extension AuthenticationService {
    var isSignedIn: Bool {
        return isAuthenticated
    }
    
    func showSignIn() {
        // Post a notification to show the login UI
        NotificationCenter.default.post(name: Notification.Name("SignUpRequested"), object: nil)
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView(
                authService: AuthenticationService(),
                userProfile: UserAIProfile()
            )
            .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        }
    }
}
