//
//  FirebaseManager.swift
//  SeniorProject
//
//  Created by William Quiroga on 01/14/25.
//

import Foundation
import FirebaseCore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private var isConfigured = false
    
    private init() {}
    
    func configure() {
        // Only configure once to avoid duplicate initialization
        guard !isConfigured else {
            print("Firebase already configured, skipping initialization")
            return
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        isConfigured = true
        print("Firebase successfully configured by FirebaseManager")
    }
} 
