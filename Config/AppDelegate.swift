//
//  AppDelegate.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import UIKit
import Firebase
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Use our centralized Firebase manager to handle initialization
        FirebaseManager.shared.configure()
        
        // Add ATS debug code
        if #available(iOS 14.0, *) {
            print("ATS Debug: \(Bundle.main.infoDictionary?["NSAppTransportSecurity"] ?? "Not found")")
        }
        
        // Set up other services if needed
        setupLogging()
        
        // Post notification to dismiss splash screen after initialization is complete
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("AppDidFinishLaunching"), object: nil)
        }
        
        return true
    }
    
    private func setupLogging() {
        // Configure debug logging based on environment
        if Constants.enableDebugMode {
            print("Debug mode enabled - verbose logging active")
        }
    }
}

// NOTE: App entry point moved to SeniorProjectApp.swift
