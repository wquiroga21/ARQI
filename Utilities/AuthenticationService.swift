//
//  AuthenticationService.swift
//  SeniorProject
//
//  Created by Claude AI on 4/10/25.
//

import Foundation
import FirebaseAuth
import Combine

// Custom User struct to avoid Firebase conflicts
struct AppUser {
    let id: String
    let email: String?
    let displayName: String?
    let createdAt: Date
    
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.createdAt = firebaseUser.metadata.creationDate ?? Date()
    }
}

class AuthenticationService: ObservableObject {
    @Published var user: AppUser?
    @Published var isAuthenticated = false
    @Published var authError: String?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let firestoreManager = FirestoreManager()
    
    init() {
        // Set up auth state listener
        let _ = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                self.user = AppUser(from: firebaseUser)
                self.isAuthenticated = true
            } else {
                self.user = nil
                self.isAuthenticated = false
            }
        }
        
        // Listen for sign-up requests from other views
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignUpRequest),
            name: Notification.Name("SignUpRequested"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleSignUpRequest() {
        // This would ideally navigate to a proper sign-up flow
        // For now, just use anonymous sign-in
        signInAnonymously()
    }
    
    // Method to explicitly check current auth state without auto-authentication
    func checkAuthState() {
        if let firebaseUser = Auth.auth().currentUser {
            // Update authenticated state
            self.user = AppUser(from: firebaseUser)
            self.isAuthenticated = true
        } else {
            // Clear authenticated state
            self.user = nil
            self.isAuthenticated = false
            
            // Don't auto-authenticate, let individual screens handle this
            // DispatchQueue.main.async {
            //    self.signInAnonymously()
            // }
        }
    }
    
    // MARK: - Sign In Methods
    
    // Sign in anonymously for testing or guest access
    func signInAnonymously() {
        self.isLoading = true
        
        // Define completion handler
        let completion: (AuthDataResult?, Error?) -> Void = { authResult, error in
            // Always update UI on main thread
            if Thread.isMainThread {
                self.handleAuthResult(authResult: authResult, error: error)
            } else {
                let mainThreadWork = DispatchWorkItem(block: {
                    self.handleAuthResult(authResult: authResult, error: error)
                })
                DispatchQueue.main.async(execute: mainThreadWork)
            }
        }
        
        // Call Firebase auth with explicit completion handler
        Auth.auth().signInAnonymously(completion: completion)
    }
    
    // Helper method to handle auth result
    private func handleAuthResult(authResult: AuthDataResult?, error: Error?) {
        self.isLoading = false
        
        if let error = error {
            self.authError = "Authentication failed: \(error.localizedDescription)"
            return
        }
        
        if let firebaseUser = authResult?.user {
            self.user = AppUser(from: firebaseUser)
            self.isAuthenticated = true
            
            // Create user profile in Firestore for anonymous users too
            // Use the correct method from FirestoreManager
            self.firestoreManager.createUserProfile(
                userId: firebaseUser.uid,
                name: firebaseUser.displayName ?? "Guest User",
                email: firebaseUser.email ?? "",
                completion: { result in
                    switch result {
                    case .success(_):
                        print("Anonymous user profile created in Firestore")
                    case .failure(let error):
                        print("Failed to create anonymous user profile: \(error.localizedDescription)")
                    }
                }
            )
        }
    }
    
    func signInWithEmail(email: String, password: String) {
        isLoading = true
        authError = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.authError = error.localizedDescription
                return
            }
            
            // Successfully signed in
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Registration
    
    func registerWithEmail(email: String, password: String, name: String) {
        isLoading = true
        authError = nil
        
        // Validate inputs
        guard email.isValidEmail else {
            authError = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Create user in Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.authError = error.localizedDescription
                return
            }
            
            // Successfully created user
            guard let user = result?.user else {
                self.isLoading = false
                self.authError = "Failed to create user account"
                return
            }
            
            // Update display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            
            changeRequest.commitChanges { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to update display name: \(error.localizedDescription)")
                }
                
                // Create user profile in Firestore
                self.firestoreManager.createUserProfile(userId: user.uid, name: name, email: email) { result in
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        self.isAuthenticated = true
                    case .failure(let error):
                        self.authError = "Account created but failed to save profile: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            authError = nil
        } catch {
            authError = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Social Authentication
    
    func signInWithApple() {
        // Implementation would require Apple Sign In configuration
        authError = "Apple Sign In not yet implemented"
    }
    
    func signInWithGoogle() {
        // Implementation would require Google Sign In configuration
        authError = "Google Sign In not yet implemented"
    }
}

// MARK: - User Model
extension AuthenticationService {
    struct User {
        let id: String
        let email: String
        let displayName: String?
        
        init(from firebaseUser: FirebaseAuth.User) {
            self.id = firebaseUser.uid
            self.email = firebaseUser.email ?? ""
            self.displayName = firebaseUser.displayName
        }
    }
}
