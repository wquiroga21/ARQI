//
//  CardViewModel.swift
//  SeniorProject
//
//  Created by William Quiroga on 1/16/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Network
import SwiftUI
import Combine

class CardViewModel: ObservableObject {
    @Published var contents: [Content] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var allContentIds: [String] = []  // Keep track of all content IDs
    private var cachedContents: [String: Content] = [:] // Cache for contents
    private let windowSize = 20 // Number of cards to keep in memory
    private var lastDocument: DocumentSnapshot?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load content when initialized
        if Constants.enableDebugMode {
            // Use mock data in debug mode
            self.contents = Content.mockContent()
        } else {
            loadInitialContent()
        }
    }
    
    // Load initial batch of content
    func loadInitialContent() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let contentRef = db.collection("contents")
            .order(by: "timestamp", descending: true)
            .limit(to: windowSize)
        
        contentRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load content: \(error.localizedDescription)"
                    return
                }
                
                guard let snapshot = snapshot else {
                    self.errorMessage = "No data available"
                    return
                }
                
                // Clear existing content
                self.contents.removeAll()
                self.allContentIds.removeAll()
                self.cachedContents.removeAll()
                
                // Process documents
                let documents = snapshot.documents
                
                // Store the last document for pagination
                self.lastDocument = documents.last
                
                // Convert documents to Content objects
                for document in documents {
                    do {
                        let content = try document.data(as: Content.self)
                        self.contents.append(content)
                        
                        if let id = content.id {
                            self.allContentIds.append(id)
                            self.cachedContents[id] = content
                        }
                    } catch {
                        print("Error decoding content: \(error)")
                    }
                }
                
                // Reset index
                self.currentIndex = 0
            }
        }
    }
    
    // Load more content when needed
    func loadMoreContent() {
        // Only load more if we have a last document and we're not already loading
        guard let lastDocument = lastDocument, !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let contentRef = db.collection("contents")
            .order(by: "timestamp", descending: true)
            .limit(to: windowSize)
            .start(afterDocument: lastDocument)
        
        contentRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load more content: \(error.localizedDescription)"
                    return
                }
                
                guard let snapshot = snapshot, !snapshot.documents.isEmpty else {
                    // No more content to load
                    return
                }
                
                // Process documents
                let documents = snapshot.documents
                
                // Store the last document for pagination
                self.lastDocument = documents.last
                
                // Convert documents to Content objects and add to cache
                for document in documents {
                    do {
                        let content = try document.data(as: Content.self)
                        
                        if let id = content.id, !self.allContentIds.contains(id) {
                            self.allContentIds.append(id)
                            self.cachedContents[id] = content
                            
                            // Only add to visible contents if we're near the end
                            if self.currentIndex >= self.contents.count - 5 {
                                self.contents.append(content)
                            }
                        }
                    } catch {
                        print("Error decoding content: \(error)")
                    }
                }
            }
        }
    }
    
    // Move to the next card
    func nextCard() {
        if currentIndex < contents.count - 1 {
            currentIndex += 1
            
            // If we're getting close to the end, load more content
            if currentIndex >= contents.count - 5 {
                loadMoreContent()
            }
        }
    }
    
    // Move to the previous card
    func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    // Get the current content
    var currentContent: Content? {
        guard !contents.isEmpty, currentIndex < contents.count else { return nil }
        return contents[currentIndex]
    }
}

enum InteractionType {
    case view
    case longView
}
