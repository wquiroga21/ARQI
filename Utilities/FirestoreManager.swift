//
//  FirestoreManager.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - User Management
    
    func createUserProfile(userId: String, name: String, email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !userId.isEmpty else {
            completion(.failure(NSError(domain: "FirestoreError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])))
            return
        }
        
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getUserProfile(userId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard !userId.isEmpty else {
            completion(.failure(NSError(domain: "FirestoreError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])))
            return
        }
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                completion(.failure(NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            completion(.success(data))
        }
    }
    
    func updateUserProfile(userId: String, data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - AI Profile Management
    
    func saveAIProfile(userId: String, aiProfile: UserAIProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        let aiData: [String: Any] = [
            "aiName": aiProfile.aiName,
            "aiTone": aiProfile.aiTone,
            "selectedTraits": aiProfile.selectedTraits,
            "perspectiveType": aiProfile.perspectiveType,
            "prioritizesNewIdeas": aiProfile.prioritizesNewIdeas,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).collection("aiProfiles").document("primary")
            .setData(aiData, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    func loadAIProfile(userId: String, completion: @escaping (Result<UserAIProfile, Error>) -> Void) {
        db.collection("users").document(userId).collection("aiProfiles").document("primary")
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                    // Return a default profile if none exists
                    let defaultProfile = UserAIProfile()
                    completion(.success(defaultProfile))
                    return
                }
                
                let profile = UserAIProfile()
                
                // Populate the profile from Firestore data
                profile.aiName = data["aiName"] as? String ?? ""
                profile.aiTone = data["aiTone"] as? String ?? "Balanced"
                profile.selectedTraits = data["selectedTraits"] as? [String] ?? []
                profile.perspectiveType = data["perspectiveType"] as? String ?? "Balanced"
                profile.prioritizesNewIdeas = data["prioritizesNewIdeas"] as? Bool ?? false
                
                completion(.success(profile))
            }
    }
    
    // MARK: - Conversation Management
    
    func saveConversation(userId: String, messages: [AIMessage], completion: @escaping (Result<String, Error>) -> Void) {
        // Create a new conversation document with auto-generated ID
        let conversationRef = db.collection("users").document(userId).collection("conversations").document()
        
        // Convert messages to storable format
        let messagesData = messages.map { message -> [String: Any] in
            return [
                "id": message.id.uuidString,
                "content": message.content,
                "isFromUser": message.isFromUser,
                "timestamp": message.timestamp
            ]
        }
        
        let conversationData: [String: Any] = [
            "messages": messagesData,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        conversationRef.setData(conversationData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(conversationRef.documentID))
            }
        }
    }
    
    func loadConversations(userId: String, limit: Int = 10, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("users").document(userId).collection("conversations")
            .order(by: "updatedAt", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let conversations = documents.compactMap { $0.data() }
                completion(.success(conversations))
            }
    }
    
    func getConversation(userId: String, conversationId: String, completion: @escaping (Result<[AIMessage], Error>) -> Void) {
        db.collection("users").document(userId).collection("conversations").document(conversationId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot,
                      snapshot.exists,
                      let data = snapshot.data(),
                      let messagesData = data["messages"] as? [[String: Any]] else {
                    completion(.failure(NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Conversation not found"])))
                    return
                }
                
                // Convert stored data back to AIMessage objects
                let messages = messagesData.compactMap { messageData -> AIMessage? in
                    guard let idString = messageData["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let content = messageData["content"] as? String,
                          let isFromUser = messageData["isFromUser"] as? Bool,
                          let timestamp = messageData["timestamp"] as? Date else {
                        return nil
                    }
                    
                    return AIMessage(id: id, content: content, isFromUser: isFromUser, timestamp: timestamp)
                }
                
                completion(.success(messages))
            }
    }
    
    // MARK: - AI Mission Management
    
    func getAIMissions(userId: String, completion: @escaping (Result<[AIMission], Error>) -> Void) {
        guard !userId.isEmpty else {
            completion(.failure(NSError(domain: "FirestoreError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])))
            return
        }
        
        db.collection("users").document(userId).collection("aiMissions")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let missions = documents.compactMap { document -> AIMission? in
                    let documentData = document.data()
                    guard let topic = documentData["topic"] as? String,
                          let statusRawValue = documentData["status"] as? String,
                          let status = AIMission.Status(rawValue: statusRawValue),
                          let startedAt = documentData["startedAt"] as? Date else {
                        return nil
                    }
                    
                    let completedAt = documentData["completedAt"] as? Date
                    // Use progress from document if available, otherwise calculate based on status
                    let progress: CGFloat
                    if let docProgress = documentData["progress"] as? CGFloat {
                        progress = docProgress
                    } else {
                        progress = status == .completed ? 1.0 : 0.0
                    }
                    
                    // Convert string insights to AIMissionInsight objects
                    let insightStrings = documentData["insights"] as? [String] ?? []
                    let insights = insightStrings.map { content in
                        AIMissionInsight(
                            id: UUID().uuidString,
                            content: content,
                            timestamp: Date()
                        )
                    }
                    
                    return AIMission(
                        id: document.documentID,
                        topic: topic,
                        description: documentData["description"] as? String ?? "Explore and analyze perspectives on \(topic)",
                        status: status,
                        insights: insights,
                        startedAt: startedAt,
                        completedAt: completedAt,
                        progress: progress
                    )
                }
                
                completion(.success(missions))
            }
    }
    
    func saveMission(_ mission: AIMission, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let missionData: [String: Any] = [
            "topic": mission.topic,
            "description": mission.description,
            "status": mission.status.rawValue,
            "insights": mission.insights.map { $0.content },
            "startedAt": mission.startedAt,
            "progress": mission.progress as NSNumber,
            "completedAt": mission.completedAt as Any
        ]
        
        // Save to Firestore
        db.collection("users").document(userId).collection("aiMissions")
            .document(mission.id).setData(missionData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
}
