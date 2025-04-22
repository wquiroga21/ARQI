//
//  AIMission.swift
//  SeniorProject
//
//  Created by William Quiroga on 3/5/25.
//

import Foundation
import SwiftUI

public struct AIMissionInsight: Identifiable {
    public let id: String
    public let content: String
    public let timestamp: Date
}

public struct AIMission: Identifiable {
    public enum Status: String {
        case inProgress = "inProgress"
        case completed = "completed"
        case failed = "failed"
    }
    
    public let id: String
    public let topic: String
    public let description: String
    public var status: Status
    public var insights: [AIMissionInsight]
    public let startedAt: Date
    public var completedAt: Date?
    public var progress: CGFloat
    
    public init(id: String, topic: String, description: String, status: Status, insights: [AIMissionInsight], startedAt: Date, completedAt: Date? = nil, progress: CGFloat = 0.0) {
        self.id = id
        self.topic = topic
        self.description = description
        self.status = status
        self.insights = insights
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.progress = progress
    }
    
    public var isActive: Bool {
        return status == .inProgress
    }
    
    public var isCompleted: Bool {
        return status == .completed
    }
} 
