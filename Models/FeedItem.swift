//
//  Content.swift
//  SeniorProject
//
//  Created by William Quiroga on 1/21/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct Content: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let category: String
    let timestamp: Timestamp
    let likes: Int
    let views: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, timestamp, likes, views
    }
    
    static func == (lhs: Content, rhs: Content) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Mock content for development/testing
    static func mockContent() -> [Content] {
        let now = Timestamp(date: Date())
        
        return [
            Content(id: "1", title: "The Future of AI", description: "Exploring the possibilities of artificial intelligence in daily life.", category: "Technology", timestamp: now, likes: 42, views: 156),
            Content(id: "2", title: "Mindfulness Practice", description: "Simple techniques to stay present and reduce stress.", category: "Wellness", timestamp: now, likes: 28, views: 97),
            Content(id: "3", title: "Climate Change Solutions", description: "Innovative approaches to addressing environmental challenges.", category: "Environment", timestamp: now, likes: 35, views: 128)
        ]
    }
} 
