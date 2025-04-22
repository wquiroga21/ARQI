//
//  AIMissionsView.swift
//  SeniorProject
//
//  Created by William Quiroga on 3/5/25.
//

import SwiftUI
import Combine
import Foundation
// Make sure we have access to the Extensions defined in the Utilities folder

// MARK: - AIMissionsView
struct AIMissionsView: View {
    let userId: String
    @ObservedObject var userProfile: UserAIProfile
    @ObservedObject var authService: AuthenticationService
    @EnvironmentObject var missionManager: AIMissionManager
    @State private var missionTopic: String = ""
    @State private var selectedMission: AIMission?
    @State private var showingMissionDetails: Bool = false
    @State private var showSignUpPrompt: Bool = false
    @State private var showingNewMission: Bool = false
    @State private var searchText: String = ""
    @StateObject private var viewModel = ExplorerViewModel() // Added view model for suggested missions
    @State private var activeCardID: UUID? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.edgesIgnoringSafeArea(.all)
                
                // Custom Explorer view instead of reusing ForYouView
                VStack(spacing: 0) {
                    // Header stays in the original position
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Discover")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading)
                            .padding(.top, 8)
                        
                        Text("Explore trending debates")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading)
                            .padding(.bottom, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Full-screen card container
                    ZStack {
                        if viewModel.trendingTopicsViewModel.topics.isEmpty {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Loading trending topics...")
                                    .padding()
                                Spacer()
                            }
                        } else {
                            // SIMPLE SCROLLVIEW IMPLEMENTATION
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.trendingTopicsViewModel.topics) { topic in
                                        ExplorerTopicCard(topic: topic)
                                            .frame(height: UIScreen.main.bounds.height - 120)
                                            .id(topic.id)
                                            .containerRelativeFrame(.vertical)
                                            .scrollTransition(.animated) { content, phase in
                                                content
                                                    .opacity(phase.isIdentity ? 1.0 : 0.0)
                                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.97)
                                            }
                                            .onAppear {
                                                // Load more when this topic appears (near end of list)
                                                let index = viewModel.trendingTopicsViewModel.topics.firstIndex(where: { $0.id == topic.id }) ?? 0
                                                if index >= viewModel.trendingTopicsViewModel.topics.count - 3 &&
                                                   !viewModel.trendingTopicsViewModel.isLoadingMore &&
                                                   viewModel.trendingTopicsViewModel.hasMoreContent {
                                                    viewModel.trendingTopicsViewModel.loadMoreTopics()
                                                }
                                                
                                                // Track which card is active
                                                activeCardID = topic.id
                                            }
                                    }
                                }
                            }
                            .scrollTargetBehavior(.paging)
                            .scrollClipDisabled(false)
                            .scrollPosition(id: $activeCardID)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("Explorer")
        .onAppear {
            // Load missions regardless of user ID
            missionManager.loadMissions(for: "default")
            viewModel.loadData() // Load suggested missions data
            
            // Connect AIManager to the trending topics view model
            viewModel.connectAIManager(missionManager.aiManager)
        }
    }
    
    // MARK: - Explorer Topic Card
    struct ExplorerTopicCard: View {
        let topic: TrendingTopic
        @State private var showDetails = false
        @EnvironmentObject var aiManager: AIManager
        
        var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Background gradient with fixed positioning
                    ZStack(alignment: .bottom) {
                        // Background gradient
                        LinearGradient(
                            gradient: Gradient(colors: [
                                topic.color.opacity(0.7),
                                Color.cardBackground
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .edgesIgnoringSafeArea(.all)
                        
                        // Topic icon (large, at the center)
                        Image(systemName: topic.imageSystemName)
                            .font(.system(size: 100))
                            .foregroundColor(Color.white.opacity(0.3))
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 3)
                        
                        // Content overlay fixed at the bottom
                        VStack(alignment: .leading, spacing: 16) {
                            // Category chip
                            Text(topic.category)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(topic.color.opacity(0.2))
                                .foregroundColor(topic.color)
                                .cornerRadius(16)
                            
                            // Title
                            Text(topic.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.primaryText)
                                .lineLimit(2)
                            
                            // Description
                            Text(topic.description)
                                .font(.body)
                                .foregroundColor(Color.secondaryText)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                            
                            // Stats and buttons
                            HStack {
                                // Participants
                                Label("\(Int.random(in: 150...500)) discussing", systemImage: "person.2.fill")
                                    .font(.callout)
                                    .foregroundColor(Color.secondaryText)
                                
                                Spacer()
                                
                                // Trending indicator
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                    Text("Trending")
                                }
                                .font(.callout)
                                .foregroundColor(topic.color)
                            }
                            .padding(.vertical, 8)
                            
                            // Debate button - fixed at the bottom
                            Button(action: {
                                showDetails = true
                            }) {
                                HStack {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                    Text("Let's Debate")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.buttonColor)
                                .cornerRadius(16)
                                .shadow(color: Color.buttonColor.opacity(0.4), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground.opacity(0.95))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 50)
                        .offset(y: -50)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .sheet(isPresented: $showDetails) {
                    TopicDetailView(topic: topic)
                        .environmentObject(aiManager)
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 15) {
            // First row with two buttons
            HStack(spacing: 20) {
                Button(action: {
                    showingNewMission = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Start New Mission")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.buttonColor)
                    .cornerRadius(15)
                    .shadow(color: Color.buttonColor.opacity(0.4), radius: 5, x: 0, y: 2)
                }
                
                Button(action: {
                    // This is already in the Explorer view, so no action needed
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("My Missions")
                    }
                    .foregroundColor(Color.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryAccent.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Section Header with Button Styling
    private func sectionHeader(title: String, iconName: String) -> some View {
        Button(action: {
            // No navigation needed as we're already in the correct view
        }) {
            HStack {
                Image(systemName: iconName)
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primaryAccent)
            .cornerRadius(15)
            .shadow(color: Color.primaryAccent.opacity(0.4), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Suggested Missions Section
    private var suggestedMissionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader(title: "Suggested Missions", iconName: "lightbulb.fill")
            
            SwiftUI.ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.suggestedMissions) { mission in
                        suggestedMissionCard(mission: mission)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func suggestedMissionCard(mission: SuggestedMission) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: mission.iconName)
                .font(.system(size: 24))
                .foregroundColor(Color.primaryAccent)
            
            Text(mission.title)
                .font(.headline)
                .foregroundColor(Color.primaryText)
                .lineLimit(2)
            
            Text(mission.description)
                .font(.caption)
                .foregroundColor(Color.secondaryText)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                Text("\(mission.participantsCount) participants")
                    .font(.caption)
            }
            .foregroundColor(Color.secondaryText)
        }
        .padding()
        .frame(width: 200)
        .background(Color.cardBackground)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Empty header - keeping structure for consistency
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        // This search bar allows users to search for missions, users, and insights.
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.iconColor)
            
            TextField("Search missions, users, insights...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(Color.primaryText)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                // Search functionality is disabled - will be implemented in future updates
                .onChange(of: searchText) { oldValue, newValue in
                    // Only perform search if text length is reasonable
                    if newValue.count > 2 {
                        performSearch(query: newValue)
                    }
                }
        }
        .padding()
        .background(Color.secondaryCardBackground)
        .cornerRadius(15)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Active Missions Section
    
    private var activeMissionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Missions")
                .font(.headline)
                .foregroundColor(Color.primaryText)
            
            ForEach(missionManager.activeMissions) { mission in
                activeMissionCard(mission: mission)
            }
        }
    }
    
    private func activeMissionCard(mission: AIMission) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("In Progress")
                    .font(.caption)
                    .foregroundColor(Color.primaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondaryCardBackground)
                    .cornerRadius(20)
                
                Spacer()
                
                // Time elapsed
                Text(timeElapsedString(since: mission.startedAt))
                    .font(.caption)
                    .foregroundColor(Color.secondaryText)
            }
            
            // Mission Topic
            Text(mission.topic)
                .font(.headline)
                .foregroundColor(Color.primaryText)
                .lineLimit(2)
            
            // Progress indicator
            HStack {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.primaryAccent))
                    .padding(.vertical, 8)
                
                // Estimated time text
                Text("Gathering insights...")
                    .font(.caption)
                    .foregroundColor(Color.secondaryText)
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
    
    // MARK: - Completed Missions Section
    
    private var completedMissionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Completed Missions")
                .font(.headline)
                .foregroundColor(Color.primaryText)
            
            ForEach(missionManager.completedMissions) { mission in
                completedMissionCard(mission: mission)
                    .onTapGesture {
                        selectedMission = mission
                        showingMissionDetails = true
                    }
            }
        }
    }
    
    private func completedMissionCard(mission: AIMission) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(Color.buttonColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondaryCardBackground)
                    .cornerRadius(20)
                
                Spacer()
                
                // Completed time
                if let completedAt = mission.completedAt {
                    Text(completedAt.getTimeAgo())
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
            }
            
            // Mission Topic
            Text(mission.topic)
                .font(.headline)
                .foregroundColor(Color.primaryText)
                .lineLimit(2)
            
            // Insights summary
            Text("\(mission.insights.count) insights gathered")
                .font(.subheadline)
                .foregroundColor(Color.secondaryText)
            
            // Preview of an insight
            if let insight = mission.insights.first {
                Text(insight.content)
                    .font(.caption)
                    .foregroundColor(Color.secondaryText)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            // View details button
            Button(action: {
                selectedMission = mission
                showingMissionDetails = true
            }) {
                Text("View All Insights")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primaryAccent)
                    .padding(.top, 4)
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
    
    // MARK: - Loading & Empty States
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading missions...")
                .font(.subheadline)
                .foregroundColor(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if userId.isEmpty {
                // User not signed in
                VStack(spacing: 16) {
                    Text("Sign in to start your AI missions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Create an account to send your AI on missions to explore diverse perspectives.")
                        .font(.subheadline)
                        .foregroundColor(Color.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showSignUpPrompt = true
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.buttonColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
            } else {
                // User signed in but no missions
                VStack(spacing: 16) {
                    Text("No AI Missions Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Send your AI on a mission to explore diverse perspectives and bring back insights on topics you care about.")
                        .font(.subheadline)
                        .foregroundColor(Color.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingNewMission = true
                    }) {
                        Text("Start First Mission")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.buttonColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - New Mission View
    
    private var newMissionView: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 20) {
                Text("Send your AI to gather diverse perspectives and insights on a topic of your choice.")
                    .font(.body)
                    .foregroundColor(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Enter a topic or question", text: $missionTopic)
                    .padding()
                    .foregroundColor(Color.primaryText)
                    .background(Color.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                // Example topics
                VStack(alignment: .leading, spacing: 10) {
                    Text("Example topics:")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                    
                    ForEach(["Climate change solutions", "Future of education", "Work-life balance", "Digital privacy", "Urban planning"], id: \.self) { topic in
                        Button(action: {
                            missionTopic = topic
                        }) {
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.secondaryCardBackground)
                                .foregroundColor(Color.primaryAccent)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack {
                    Button(action: {
                        startNewMission()
                    }) {
                        HStack {
                            Text("Start Mission")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if missionManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(missionTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondaryText : Color.buttonColor)
                        .cornerRadius(10)
                        .shadow(color: Color.buttonColor.opacity(0.4), radius: 5, x: 0, y: 2)
                    }
                    .disabled(missionTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || missionManager.isLoading)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("New AI Mission")
            .navigationBarItems(trailing: Button("Cancel") {
                showingNewMission = false
            }
            .foregroundColor(Color.primaryAccent))
        }
    }
    
    // MARK: - Mission Detail View
    
    private func missionDetailView(mission: AIMission) -> some View {
        SwiftUI.NavigationView {
            SwiftUI.ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Mission header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mission.topic)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primaryText)
                        
                        HStack {
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(Color.buttonColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.secondaryCardBackground)
                                .cornerRadius(20)
                            
                            Spacer()
                            
                            if let completedAt = mission.completedAt {
                                Text(completedAt.formatDate(style: .medium))
                                    .font(.caption)
                                    .foregroundColor(Color.secondaryText)
                            }
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
                    
                    // Mission insights
                    VStack(alignment: .leading, spacing: 15) {
                        Text("AI Insights")
                            .font(.headline)
                            .foregroundColor(Color.primaryText)
                        
                        ForEach(mission.insights.indices, id: \.self) { index in
                            insightCard(insight: mission.insights[index], index: index + 1)
                        }
                    }
                    
                    // Use in conversation button
                    Button(action: {
                        // This would navigate to chat with this insight
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Discuss These Insights With AI")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.buttonColor)
                        .cornerRadius(10)
                        .shadow(color: Color.buttonColor.opacity(0.4), radius: 5, x: 0, y: 2)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("Mission Details")
            .navigationBarItems(trailing: Button("Close") {
                showingMissionDetails = false
            }
            .foregroundColor(Color.primaryAccent))
        }
    }
    
    private func insightCard(insight: AIMissionInsight, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Insight number
            HStack {
                Text("Insight #\(index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryAccent)
                
                Spacer()
                
                // Share button
                Button(action: {
                    // This would share the insight
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundColor(Color.iconColor)
                }
            }
            
            // Insight content
            Text(insight.content)
                .font(.body)
                .foregroundColor(Color.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            // Action buttons
            HStack {
                // Save button
                Button(action: {
                    // This would save the insight
                }) {
                    Label("Save", systemImage: "bookmark")
                        .font(.caption)
                        .foregroundColor(Color.primaryAccent)
                }
                
                Spacer()
                
                // Use in chat button
                Button(action: {
                    // This would use the insight in a chat
                }) {
                    Label("Use in Chat", systemImage: "message")
                        .font(.caption)
                        .foregroundColor(Color.primaryAccent)
                }
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
    
    // MARK: - Helper Functions
    
    private func startNewMission() {
        // Simplify the check to avoid ambiguity with trimmed()
        let topic = missionTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !topic.isEmpty else { return }
        
        missionManager.startMission(userId: userId, topic: topic) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    showingNewMission = false
                    missionTopic = ""
                case .failure(let error):
                    print("Failed to start mission: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func timeElapsedString(since date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        
        let minutes = Int(timeInterval / 60)
        if minutes < 60 {
            return "\(minutes) min"
        }
        
        let hours = minutes / 60
        return "\(hours) hr"
    }
    
    // Search function to be implemented in future updates
    private func performSearch(query: String) {
        // This will be implemented in future updates
        print("Search query: \(query) - Search functionality will be implemented in future updates")
    }
}

// MARK: - Preview Provider
struct AIMissionsView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUI.NavigationView {
            AIMissionsView(
                userId: "test-user-id",
                userProfile: UserAIProfile(),
                authService: AuthenticationService()
            )
            .environmentObject(AIMissionManager())
        }
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
    }
}

// MARK: - Supporting View Model
class ExplorerViewModel: ObservableObject {
    @Published var suggestedMissions: [SuggestedMission] = []
    @Published var suggestedTopics: [String] = []
    @Published var trendingTopicsViewModel: TrendingTopicsViewModel = TrendingTopicsViewModel()
    
    func loadData() {
        loadSuggestedMissions()
        loadSuggestedTopics()
    }
    
    // Connect AIManager to the TrendingTopicsViewModel
    func connectAIManager(_ aiManager: AIManager) {
        self.trendingTopicsViewModel.aiManager = aiManager
        
        // Generate topics if needed
        if self.trendingTopicsViewModel.topics.isEmpty {
            self.trendingTopicsViewModel.generateInitialTopics()
        }
    }
    
    private func loadSuggestedMissions() {
        suggestedMissions = [
            SuggestedMission(
                id: "1",
                title: "AI & The Future of Work",
                description: "Explore how AI will transform the workplace in the next decade",
                iconName: "briefcase.fill",
                participantsCount: 128
            ),
            SuggestedMission(
                id: "2",
                title: "Climate Change Solutions",
                description: "Discover innovative approaches to combat climate change",
                iconName: "leaf.fill",
                participantsCount: 256
            ),
            SuggestedMission(
                id: "3",
                title: "Future of Education",
                description: "Analyze trends shaping the future of learning",
                iconName: "book.fill",
                participantsCount: 192
            )
        ]
    }
    
    private func loadSuggestedTopics() {
        suggestedTopics = [
            "AI in Healthcare",
            "Future of Transportation",
            "Sustainable Cities",
            "Digital Privacy",
            "Mental Health & Technology"
        ]
    }
}

// MARK: - Helper Views
struct AIMissionProgressView: View {
    let progress: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.borderColor, lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.primaryAccent, lineWidth: 4)
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .bold()
                .foregroundColor(Color.primaryText)
        }
    }
}

struct ActiveMissionCard: View {
    let mission: AIMission
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AIMissionProgressView(progress: mission.progress)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.topic)
                        .font(.headline)
                        .foregroundColor(Color.primaryText)
                        .lineLimit(1)
                    
                    Text(timeRemaining)
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    // Open chat
                }) {
                    Image(systemName: "message.fill")
                        .foregroundColor(Color.primaryAccent)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.borderColor)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.primaryAccent)
                        .frame(width: geometry.size.width * CGFloat(mission.progress), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var timeRemaining: String {
        let timeInterval = Date().timeIntervalSince(mission.startedAt)
        let minutes = Int(timeInterval / 60)
        
        if minutes < 60 {
            return "\(minutes) min"
        }
        
        let hours = minutes / 60
        return "\(hours) hr"
    }
}
