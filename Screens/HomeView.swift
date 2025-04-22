//
//  HomeView.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import SwiftUI
import Combine
import CoreGraphics
import Foundation

struct HomeView: View {
    @ObservedObject var userProfile: UserAIProfile
    @EnvironmentObject private var missionManager: AIMissionManager
    @EnvironmentObject private var aiManager: AIManager
    @StateObject private var trendingViewModel = TrendingTopicsViewModel()
    @State private var selectedTab = 0 // 0 = For You, 1 = Chat
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with logo, greetings and AI button
            HeaderView()
                .environmentObject(userProfile)
                .environmentObject(missionManager)
            
            // Tab selector
            HStack(spacing: 0) {
                ForEach(0..<2) { index in
                    Button(action: {
                        withAnimation {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(index == 0 ? "Chat" : "For You")
                                .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundColor(selectedTab == index ? Color.primaryText : Color.secondaryText)
                            
                            // Indicator
                            Rectangle()
                                .fill(selectedTab == index ? Color.primaryAccent : Color.clear)
                                .frame(height: 3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8)
            
            // Swipeable content
            TabView(selection: $selectedTab) {
                // Chat with AI page
                ChatWrapperView()
                    .environmentObject(aiManager)
                    .tag(0)
                
                // "For You" page
                ForYouView(viewModel: trendingViewModel)
                    .environmentObject(aiManager)
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedTab)
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            .onChange(of: selectedTab) { _, newIndex in
                // This onChange handler should only respond to tab changes, not affect topics
            }
        }
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .onAppear {
            trendingViewModel.aiManager = aiManager
        }
    }
    
    // MARK: - Chat Wrapper View
    struct ChatWrapperView: View {
        @EnvironmentObject var aiManager: AIManager
        
        var body: some View {
            AIInteractionView()
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, iconName: String) -> some View {
        Button(action: {}) {
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
    
    private func dummyActiveMissionCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CircularProgressView(progress: 0.7)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI and Society")
                        .font(.headline)
                        .foregroundColor(Color.primaryText)
                        .lineLimit(1)
                    
                    Text("10 min")
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
                
                Spacer()
                
                Button(action: {}) {
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
                        .frame(width: geometry.size.width * 0.7, height: 4)
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
    
    private func dummySuggestedMissionCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.primaryAccent)
            
            Text("AI & The Future of Work")
                .font(.headline)
                .foregroundColor(Color.primaryText)
                .lineLimit(2)
            
            Text("Explore how AI will transform the workplace in the next decade")
                .font(.caption)
                .foregroundColor(Color.secondaryText)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                Text("128 participants")
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
    
    private func dummyCompletedMissionCard() -> some View {
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
                
                Text("2h ago")
                    .font(.caption)
                    .foregroundColor(Color.secondaryText)
            }
            
            Text("Climate Change Solutions")
                .font(.headline)
                .foregroundColor(Color.primaryText)
                .lineLimit(2)
            
            Text("3 insights gathered")
                .font(.subheadline)
                .foregroundColor(Color.secondaryText)
            
            Text("Renewable energy sources will be crucial for sustainable development.")
                .font(.caption)
                .foregroundColor(Color.secondaryText)
                .lineLimit(2)
                .padding(.top, 4)
            
            Button(action: {}) {
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
}

// MARK: - ForYouView
struct ForYouView: View {
    @ObservedObject var viewModel: TrendingTopicsViewModel
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                // Full-screen vertical scrolling cards with paging
                VStack {
                    // Simple header without refresh button
                    VStack(alignment: .leading, spacing: 4) {
                        Text("For You")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        Text("Discover trending topics")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                    
                    // *** TikTok-style vertical card scrolling with paging ***
                    if viewModel.topics.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading trending topics...")
                                .padding()
                            Spacer()
                        }
                    } else {
                        ZStack {
                            // Distinct layout for ForYou vs Explorer
                            TabView(selection: $currentIndex) {
                                ForEach(Array(viewModel.topics.enumerated()), id: \.element.id) { index, topic in
                                    FullScreenTopicCard(topic: topic)
                                        .tag(index)
                                        .containerRelativeFrame(.vertical)
                                        .onChange(of: currentIndex) { oldValue, newValue in
                                            // When user gets close to the end of available topics, load more
                                            // Improved to load when within 5 cards of the end
                                            if newValue >= viewModel.topics.count - 5 && !viewModel.isLoadingMore && viewModel.hasMoreContent {
                                                viewModel.loadMoreTopics()
                                            }
                                        }
                                        .scrollTransition { content, phase in
                                            content
                                                .opacity(phase.isIdentity ? 1.0 : 0.8)
                                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                                        }
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .scrollTargetBehavior(.paging)
                            .scrollIndicators(.hidden)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.02))
                            
                            // Loading indicator overlay at the bottom when loading more
                            if viewModel.isLoadingMore {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 10) {
                                            ProgressView()
                                                .scaleEffect(1.2)
                                            Text("Loading more topics...")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.cardBackground.opacity(0.8))
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                                        Spacer()
                                    }
                                    .padding(.bottom, 30)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    // Load initial topics if none exist
                    if viewModel.topics.isEmpty {
                        viewModel.generateInitialTopics()
                    }
                }
            }
        }
    }
}

struct FullScreenTopicCard: View {
    let topic: TrendingTopic
    @EnvironmentObject var aiManager: AIManager
    @State private var showDetails = false
    
    var body: some View {
        GeometryReader { geometry in 
            // Card with distinct "For You" style - uses rounded corners
            VStack {
                ZStack(alignment: .bottomLeading) {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            topic.color.opacity(0.7),
                            Color.cardBackground
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                    
                    // Topic icon (large, at the center)
                    Image(systemName: topic.imageSystemName)
                        .font(.system(size: 80))
                        .foregroundColor(Color.white.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: -40)
                    
                    // Content overlay at the bottom
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
                        
                        // Debate button
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
                    .padding(.bottom, 16)
                }
                .frame(width: geometry.size.width - 32, height: geometry.size.height - 100)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .sheet(isPresented: $showDetails) {
                TopicDetailView(topic: topic)
                    .environmentObject(aiManager)
            }
        }
    }
}

// MARK: - HeaderView
struct HeaderView: View {
    @EnvironmentObject private var userProfile: UserAIProfile
    @EnvironmentObject private var missionManager: AIMissionManager
    @State private var showAISettings = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Logo
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 48)
            
            // Animated messages
            VStack(alignment: .leading, spacing: 2) {
                Text(userProfile.aiName.isEmpty ? "Hello there!" : "Hello, \(userProfile.aiName)!")
                    .font(.headline)
                    .foregroundColor(Color.primaryText)
                
                Text("How can I help you today?")
                    .font(.subheadline)
                    .foregroundColor(Color.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // AI Button
            Button(action: {
                showAISettings = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showAISettings) {
                NavigationView {
                    AIPersonalityEditorView(userProfile: userProfile)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }
}

// Original AI Personality Editor from ProfileView
struct AIPersonalityEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userProfile: UserAIProfile
    @State private var showingResetConfirmation = false
    @State private var showingClearChatConfirmation = false
    @State private var selectedPersonality = "Balanced"
    @State private var prioritizeNewIdeas = false
    @State private var aiName = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // AI Assistant Header from Chat
                HStack {
                    Text("AI Assistant")
                        .font(.headline)
                        .foregroundColor(Color.primaryText)
                    
                    Spacer()
                    
                    // Connected status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(Color.secondaryText)
                    }
                    
                    Button(action: {
                        showingClearChatConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.primaryText)
                            .font(.system(size: 18))
                    }
                    .padding(.horizontal, 8)
                    
                    Button(action: {
                        // Open AI Settings
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: Notification.Name("OpenAISettings"), object: nil)
                        }
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(Color.primaryText)
                            .font(.system(size: 18))
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // AI name
                VStack(alignment: .leading, spacing: 10) {
                    Text("AI Name")
                        .font(.headline)
                        .foregroundColor(Color.primaryText)
                    
                    TextField("Enter a name for your AI", text: $aiName)
                        .padding()
                        .foregroundColor(Color.primaryText)
                        .background(Color.cardBackground)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                }
                
                // AI Perspective Type
                VStack(alignment: .leading, spacing: 10) {
                    Text("AI Personality Type")
                        .font(.headline)
                        .foregroundColor(Color.primaryText)
                    
                    VStack(spacing: 10) {
                        personalityTypeButton("Balanced", description: "Presents multiple perspectives in a balanced way", isSelected: selectedPersonality == "Balanced") {
                            selectedPersonality = "Balanced"
                        }
                        
                        personalityTypeButton("Challenger", description: "Challenges assumptions and plays devil's advocate", isSelected: selectedPersonality == "Challenger") {
                            selectedPersonality = "Challenger"
                        }
                        
                        personalityTypeButton("Supportive", description: "Builds upon your ideas in an affirming way", isSelected: selectedPersonality == "Supportive") {
                            selectedPersonality = "Supportive"
                        }
                    }
                }
                
                // AI Traits (maximum 3)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("AI Traits")
                            .font(.headline)
                            .foregroundColor(Color.primaryText)
                        
                        Spacer()
                        
                        Text("Select up to 3")
                            .font(.caption)
                            .foregroundColor(Color.secondaryText)
                    }
                    
                    // Selected traits
                    if !userProfile.selectedTraits.isEmpty {
                        HStack {
                            ForEach(userProfile.selectedTraits, id: \.self) { trait in
                                Button(action: {
                                    userProfile.removeTrait(trait)
                                }) {
                                    HStack {
                                        Text(trait)
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.secondaryCardBackground)
                                    .foregroundColor(Color.primaryAccent)
                                    .cornerRadius(20)
                                }
                            }
                        }
                    }
                    
                    // Available traits
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(userProfile.availableTraits, id: \.self) { trait in
                            if !userProfile.selectedTraits.contains(trait) {
                                Button(action: {
                                    userProfile.addTrait(trait)
                                }) {
                                    Text(trait)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.secondaryCardBackground)
                                        .foregroundColor(Color.primaryText)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.borderColor, lineWidth: 1)
                                        )
                                }
                                .disabled(userProfile.selectedTraits.count >= 3)
                            }
                        }
                    }
                }
                
                // Ideas preference toggle
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ideas Preference")
                        .font(.headline)
                        .foregroundColor(Color.primaryText)
                    
                    Toggle(isOn: $prioritizeNewIdeas) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Prioritize new ideas")
                                .font(.subheadline)
                                .foregroundColor(Color.primaryText)
                            
                            Text("AI will focus on generating novel concepts rather than refining existing ones")
                                .font(.caption)
                                .foregroundColor(Color.secondaryText)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.primaryAccent))
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                
                // Add Reset AI Personality button here
                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset AI Personality")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.top, 15)
            }
            .padding()
        }
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("Edit AI Personality")
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            }
            .foregroundColor(Color.primaryAccent),
            trailing: Button("Save") {
                saveAIPersonality()
            }
            .foregroundColor(Color.buttonColor)
        )
        .onAppear {
            loadUserPreferences()
        }
        .alert(isPresented: $showingResetConfirmation) {
            Alert(
                title: Text("Reset AI Personality"),
                message: Text("This will reset your AI's personality to default settings. Are you sure?"),
                primaryButton: .destructive(Text("Reset")) {
                    userProfile.resetProfile()
                    loadUserPreferences()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Clear Chat History?", isPresented: $showingClearChatConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                NotificationCenter.default.post(name: Notification.Name("AIChatHistoryCleared"), object: nil)
            }
        } message: {
            Text("This will delete all chat messages and start a new conversation. This action cannot be undone.")
        }
    }
    
    private func loadUserPreferences() {
        aiName = userProfile.aiName
        selectedPersonality = userProfile.perspectiveType
        prioritizeNewIdeas = userProfile.prioritizesNewIdeas
    }
    
    private func saveAIPersonality() {
        // Save AI name and tone
        userProfile.saveAIPersonality(name: aiName, tone: selectedPersonality)
        
        // Save preferences
        userProfile.perspectiveType = selectedPersonality
        userProfile.prioritizesNewIdeas = prioritizeNewIdeas
        userProfile.savePreferences()
        
        // If this is the first setup, mark it as completed
        if !userProfile.hasCompletedInitialSetup {
            userProfile.hasCompletedInitialSetup = true
        }
        
        dismiss()
    }
    
    private func personalityTypeButton(_ type: String, description: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(Color.primaryText)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.primaryAccent)
                }
            }
            .padding()
            .background(isSelected ? Color.primaryAccent.opacity(0.1) : Color.secondaryCardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.primaryAccent.opacity(0.3) : Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views
struct StoryPreviewView: View {
    let story: Story
    @State private var progress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle with border
                Circle()
                    .stroke(Color.borderColor, lineWidth: 2)
                    .frame(width: 62, height: 62)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.primaryAccent, lineWidth: 2)
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(-90))
                
                // Background circle for all icons
                Circle()
                    .fill(Color.secondaryCardBackground)
                    .frame(width: 56, height: 56)
                
                // Icon with consistent styling - all icons use gray color
                story.image
                    .resizable()
                    .aspectRatio(contentMode: .fit) // Use .fit instead of .fill to ensure proper scaling
                    .foregroundColor(Color.storyIconColor) // Using our fixed story icon color for all icons
                    .frame(width: 30, height: 30) // Fixed size for all icons
            }
            
            Text(story.title)
                .font(.caption)
                .foregroundColor(Color.primaryText)
                .lineLimit(1)
        }
        .padding(.vertical, 5) // Add vertical padding to ensure circles aren't cut off
        .onAppear {
            withAnimation(.linear(duration: 1)) {
                progress = 1
            }
        }
    }
}

// MARK: - View Model
class HomeViewModel: ObservableObject {
    @Published var stories: [Story] = []
    
    func loadData() {
        loadStories()
    }
    
    private func loadStories() {
        stories = [
            Story(id: UUID().uuidString,
                  title: "Your Story",
                  image: Image(systemName: "person.fill"),
                  type: .user,
                  timestamp: Date()),
            
            Story(id: UUID().uuidString,
                  title: "AI Ethics",
                  image: Image(systemName: "brain.head.profile"),
                  type: .ai,
                  timestamp: Date().addingTimeInterval(-3600))
        ]
    }
}

// MARK: - Supporting Models
struct Story: Identifiable {
    let id: String
    let title: String
    let image: Image
    let type: StoryType
    let timestamp: Date
    
    enum StoryType {
        case user
        case ai
    }
}

// Model for trending topic cards
struct TrendingTopic: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let category: String
    let imageSystemName: String // System image name
    let color: Color
    
    static func == (lhs: TrendingTopic, rhs: TrendingTopic) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Sample topics for demonstration
    static var sampleTopics: [TrendingTopic] = [
        TrendingTopic(
            id: UUID(),
            title: "AI in Healthcare",
            description: "How will artificial intelligence transform medical diagnostics and patient care in the next decade?",
            category: "Technology",
            imageSystemName: "heart.text.square.fill",
            color: Color.red
        ),
        TrendingTopic(
            id: UUID(),
            title: "Climate Change Solutions",
            description: "What innovative approaches could realistically reverse climate change within our lifetime?",
            category: "Environment",
            imageSystemName: "leaf.fill",
            color: Color.green
        ),
        TrendingTopic(
            id: UUID(),
            title: "Future of Work",
            description: "As automation increases, how will careers evolve and what new types of jobs might emerge?",
            category: "Society",
            imageSystemName: "briefcase.fill",
            color: Color.blue
        ),
        TrendingTopic(
            id: UUID(),
            title: "Space Exploration",
            description: "What are the ethical considerations of colonizing Mars and other planets?",
            category: "Science",
            imageSystemName: "star.fill",
            color: Color.purple
        ),
        TrendingTopic(
            id: UUID(),
            title: "Digital Privacy",
            description: "In an increasingly connected world, how can we balance convenience with personal privacy?",
            category: "Technology",
            imageSystemName: "lock.shield.fill",
            color: Color.orange
        )
    ]
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUI.NavigationView {
            HomeView(userProfile: UserAIProfile())
                .environmentObject(AIMissionManager())
                .environmentObject(AIManager(chatType: .mainChat))
                .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        }
    }
}

// MARK: - New Mission View
struct NewMissionView: View {
    @Binding var showingNewMission: Bool
    @ObservedObject var missionManager: AIMissionManager
    @State private var missionTopic = ""
    
    var body: some View {
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
    
    private func startNewMission() {
        let topic = missionTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !topic.isEmpty else { return }
        
        missionManager.startMission(userId: "default", topic: topic) { result in
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
}

// MARK: - Mission Detail View
struct MissionDetailView: View {
    let mission: AIMission
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Mission header
                VStack(alignment: .leading, spacing: 8) {
                    Text(mission.topic)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryText)
                    
                    HStack {
                        Text(mission.status.rawValue)
                            .font(.caption)
                            .foregroundColor(Color.buttonColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondaryCardBackground)
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        if let completedAt = mission.completedAt {
                            Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(Color.secondaryText)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                
                // Mission insights
                if !mission.insights.isEmpty {
                    Text("Insights")
                        .font(.headline)
                        .foregroundColor(Color.primaryText)
                        .padding(.horizontal)
                    
                    ForEach(mission.insights) { insight in
                        insightCard(insight)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("Mission Details")
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
    
    private func insightCard(_ insight: AIMissionInsight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(insight.content)
                .font(.body)
                .foregroundColor(Color.primaryText)
            
            Text(insight.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(Color.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Helper Views
struct CircularProgressView: View {
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

// MARK: - TrendingTopicsViewModel
class TrendingTopicsViewModel: ObservableObject {
    @Published var topics: [TrendingTopic] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreContent = true
    var aiManager: AIManager?
    
    // Default to using deepseek model for content generation
    let contentGenerationModel = "mistral:latest"
    
    // Required properties that were missing
    private let categories = ["Technology", "Environment", "Society", "Science", "Health", "Economy", "Education", "Culture", "Politics", "Ethics"]
    
    private let iconMapping: [String: (name: String, color: Color)] = [
        "Technology": ("cpu.fill", .blue),
        "Environment": ("leaf.fill", .green),
        "Society": ("person.3.fill", .indigo),
        "Science": ("atom", .purple),
        "Health": ("heart.fill", .red),
        "Economy": ("dollarsign.circle.fill", .green),
        "Education": ("book.fill", .orange),
        "Culture": ("globe.americas.fill", .cyan),
        "Politics": ("building.columns.fill", .gray),
        "Ethics": ("scale.3d", .brown)
    ]
    
    init() {
        // Start with sample topics as fallback
        self.topics = TrendingTopic.sampleTopics
    }
    
    // For backward compatibility (renamed method)
    func generateNewTopics() {
        generateInitialTopics(clearExisting: true)
    }
    
    // New method that doesn't clear existing topics by default
    func generateInitialTopics(clearExisting: Bool = false) {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Only clear existing topics if explicitly requested
        if clearExisting {
            self.topics = []
        }
        
        // If AI manager is available, use it
        if let aiManager = aiManager {
            // Using generateContentWithoutChatHistory instead of generateResponse
            let prompt = """
            Generate 15 engaging, diverse trending debate topics that would interest college students. Format as a JSON array where each topic has:
            - title: A catchy, short title
            - category: One of [Technology, Politics, Education, Entertainment, Health, Environment, Business, Ethics, Science, Sports, Culture, Social Media]
            - description: A 1-2 sentence explanation of why this is trending and what people are debating about it

            Example:
            [
              {
                "title": "AI in College Admissions",
                "category": "Education",
                "description": "Universities are beginning to use AI to screen applications. Students are debating whether this creates more objectivity or reinforces biases."
              }
            ]
            
            Only return the JSON array, nothing else.
            """
            
            // Use the content generation model with the correct API
            aiManager.generateContentWithoutChatHistory(prompt: prompt, model: contentGenerationModel) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.parseAIResponseAndAddToTopics(response)
                    case .failure(_):
                        // Fall back to local generation if AI fails
                        self.generateTopicsLocally()
                    }
                    self.isLoading = false
                }
            }
        } else {
            self.generateTopicsLocally()
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func loadMoreTopics() {
        // Don't load more if already loading or no more content expected
        guard !isLoadingMore && hasMoreContent else { return }
        
        isLoadingMore = true
        
        // If AI manager is available, use it
        if let aiManager = aiManager {
            generateMoreTopicsWithAI(aiManager: aiManager)
        } else {
            self.generateMoreTopicsLocally()
            DispatchQueue.main.async {
                self.isLoadingMore = false
            }
        }
    }
    
    private func generateMoreTopicsWithAI(aiManager: AIManager) {
        let prompt = """
        Generate 10 more trending debate topics that would be interesting for users to discuss.
        Make these different from typical topics like AI Ethics or Climate Change.
        Each topic should include:
        1. A title (max 4-5 words)
        2. A category (Technology, Environment, Society, Science, Health, Economy, Education, Culture, Politics, or Ethics)
        3. A thought-provoking question that could spark debate (1-2 sentences)
        
        Format as JSON like this:
        [{"title": "Genetic Privacy Rights", "category": "Ethics", "description": "As genetic testing becomes commonplace, who should own and control access to our genetic data?"}]
        """
        
        aiManager.generateContentWithoutChatHistory(prompt: prompt, model: contentGenerationModel) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.parseAIResponseAndAddToTopics(response)
                case .failure(_):
                    // Fall back to local generation if AI fails
                    self.generateMoreTopicsLocally()
                }
                self.isLoadingMore = false
            }
        }
    }
    
    private func parseAIResponseAndAddToTopics(_ response: String) {
        // Extract JSON if it's within the response
        if let jsonStart = response.range(of: "["),
           let jsonEnd = response.range(of: "]", options: .backwards) {
            
            let startIndex = jsonStart.lowerBound
            let endIndex = jsonEnd.upperBound
            let jsonString = String(response[startIndex..<endIndex])
            
            // Try to parse JSON
            do {
                struct AITopic: Codable {
                    let title: String
                    let category: String
                    let description: String
                }
                
                let decoder = JSONDecoder()
                let aiTopics = try decoder.decode([AITopic].self, from: jsonString.data(using: .utf8)!)
                
                // Convert to TrendingTopic objects
                var newTopics: [TrendingTopic] = []
                
                // Create a set of existing titles (case insensitive) for faster duplicate checking
                let existingTitles = Set(self.topics.map { $0.title.lowercased() })
                
                for aiTopic in aiTopics {
                    var category = aiTopic.category
                    // Ensure category is in our known list
                    if !categories.contains(category) {
                        category = categories.randomElement() ?? "Technology"
                    }
                    
                    // Get icon and color for this category
                    let iconInfo = iconMapping[category] ?? ("questionmark.circle.fill", .gray)
                    
                    // Check if this title is already used (case insensitive)
                    let lowercasedTitle = aiTopic.title.lowercased()
                    if !existingTitles.contains(lowercasedTitle) {
                        let topic = TrendingTopic(
                            id: UUID(),
                            title: aiTopic.title,
                            description: aiTopic.description,
                            category: category,
                            imageSystemName: iconInfo.name,
                            color: iconInfo.color
                        )
                        
                        newTopics.append(topic)
                    }
                }
                
                if !newTopics.isEmpty {
                    // Add new topics to existing topics
                    DispatchQueue.main.async {
                        self.topics.append(contentsOf: newTopics)
                        // Always set hasMoreContent to true after successfully adding topics
                        self.hasMoreContent = true
                    }
                    return
                } else if aiTopics.count > 0 {
                    // We got topics from AI but they were all duplicates
                    // Generate a few local topics to ensure we always have new content
                    generateMoreTopicsLocally()
                    return
                }
            } catch {
                print("Error parsing AI response: \(error)")
            }
        }
        
        // If we get here, parsing failed, fall back to local generation
        generateMoreTopicsLocally()
    }
    
    private func generateMoreTopicsLocally() {
        // Add more topics from the extended topic lists
        let newTopics = generateLocalTopics(count: 10)
        
        // Add new topics to existing topics
        self.topics.append(contentsOf: newTopics)
        self.isLoadingMore = false
        
        // Always ensure hasMoreContent is true so infinite scrolling continues
        self.hasMoreContent = true
    }
    
    private func generateTopicsLocally() {
        // Create randomly generated topics as a fallback
        self.topics = generateLocalTopics(count: 15)
        self.isLoading = false
    }
    
    private func generateLocalTopics(count: Int) -> [TrendingTopic] {
        var newTopics: [TrendingTopic] = []
        
        // Extended topic lists for more variety
        let allTopicsByCategory: [String: [(title: String, description: String)]] = [
            "Technology": [
                ("AI Ethics", "As AI systems become more advanced, should they be granted any form of legal rights or protections?"),
                ("Digital Privacy", "In an increasingly connected world, how do we balance convenience with protecting personal data?"),
                ("Quantum Computing", "How might quantum computing change encryption and cybersecurity as we know it?"),
                ("Human Augmentation", "What ethical considerations should guide human enhancement technologies?"),
                ("Space Internet", "Should internet access be considered a basic human right, including in space?"),
                ("Brain Interfaces", "Should we allow direct computer interfaces with the human brain, and who should regulate them?"),
                ("Robot Rights", "At what point should robots or AI systems be granted rights or protections?"),
                ("Virtual Reality Life", "Could living primarily in virtual reality ever be considered a healthy lifestyle?"),
                ("Digital Immortality", "Should we pursue technology that preserves human consciousness after death?"),
                ("Genetic Editing", "Who should control access to CRISPR and other genetic editing technologies?")
            ],
            "Environment": [
                ("Carbon Capture", "Are carbon capture technologies a viable solution to climate change or a distraction from reducing emissions?"),
                ("Nuclear Energy", "Is nuclear energy the most practical clean energy solution for addressing climate change?"),
                ("Lab-Grown Meat", "Could synthetic meat production solve environmental issues while meeting global protein needs?"),
                ("Ocean Cleanup", "What approaches should be prioritized to address plastic pollution in our oceans?"),
                ("Urban Greening", "How can urban planning incorporate more green spaces while addressing housing shortages?"),
                ("Rewilding Cities", "Should parts of urban areas be returned to nature through deliberate rewilding?"),
                ("Water Rights", "Who should control water resources as they become increasingly scarce?"),
                ("Geoengineering", "Should we actively manipulate the climate through geoengineering to counter climate change?"),
                ("Zero-Waste Economy", "Is a truly zero-waste economy achievable, and what would that mean for consumers?"),
                ("Wildlife Corridors", "Should we create protected wildlife migration corridors across national boundaries?")
            ],
            "Society": [
                ("Universal Basic Income", "Would implementing universal basic income strengthen or weaken society's productivity?"),
                ("Social Media Limits", "Should there be legal limits on social media use to protect mental health?"),
                ("Community Currencies", "Could local currencies strengthen communities while operating alongside national currencies?"),
                ("Four-Day Workweek", "Is a four-day workweek a sustainable model for modern economies?"),
                ("Age of Adulthood", "Is 18 the right age for determining adult status, or should it be based on other factors?"),
                ("Digital Democracy", "Could direct digital voting on issues replace representative democracy?"),
                ("Public Transportation", "Should cities make public transportation entirely free for residents?"),
                ("Religious Education", "What role should religious education play in public schools, if any?"),
                ("New Forms of Family", "How should society recognize non-traditional family structures legally?"),
                ("News Media Funding", "Should quality journalism be publicly funded to ensure independence?")
            ],
            "Education": [
                ("College Alternatives", "Are traditional universities still the best path to career success?"),
                ("Teaching Critical Thinking", "How can schools better teach critical thinking rather than memorization?"),
                ("AI Teachers", "Could AI tutors eventually replace human teachers for certain subjects?"),
                ("Universal Languages", "Should schools focus more on teaching universal languages or preserving local ones?"),
                ("Play-Based Learning", "Should education for younger children be primarily play-based rather than academic?"),
                ("Testing Systems", "Do standardized tests measure true intelligence and potential?"),
                ("Arts Education", "Is arts education as important as STEM for developing young minds?"),
                ("Home Education", "Will homeschooling become mainstream as digital resources improve?"),
                ("Historical Revisions", "How should schools teach historical events that are subject to modern reinterpretation?"),
                ("Physical Education", "Should daily physical education be mandated in all schools to combat obesity?")
            ]
        ]
        
        // Start with existing topics to avoid duplicates
        let existingTitles = Set(topics.map { $0.title.lowercased() })
        
        // Generate specified number of topics
        while newTopics.count < count {
            // Randomly select a category
            let category = categories.randomElement() ?? "Technology"
            
            // Get topics for this category
            let categoryTopics = allTopicsByCategory[category] ?? allTopicsByCategory["Technology"]!
            
            // Try to get a topic that hasn't been used yet
            var attempts = 0
            var foundNewTopic = false
            
            while !foundNewTopic && attempts < 5 {
                if let randomTopic = categoryTopics.randomElement() {
                    // Check if this title is already used
                    if !existingTitles.contains(randomTopic.title.lowercased()) {
                        // Get icon and color for this category
                        let iconInfo = iconMapping[category] ?? ("questionmark.circle.fill", .gray)
                        
                        let topic = TrendingTopic(
                            id: UUID(),
                            title: randomTopic.title,
                            description: randomTopic.description,
                            category: category,
                            imageSystemName: iconInfo.name,
                            color: iconInfo.color
                        )
                        
                        newTopics.append(topic)
                        foundNewTopic = true
                    }
                }
                attempts += 1
            }
            
            // If we can't find an unused topic after several attempts, move on
            if !foundNewTopic {
                // Generate a generic topic with a random number to make it unique
                let randomNumber = Int.random(in: 1...1000)
                let title = "Future of \(category) \(randomNumber)"
                let description = "What are the most promising developments in \(category.lowercased()) that could transform society in the next decade?"
                
                // Get icon and color for this category
                let iconInfo = iconMapping[category] ?? ("questionmark.circle.fill", .gray)
                
                let topic = TrendingTopic(
                    id: UUID(),
                    title: title,
                    description: description,
                    category: category,
                    imageSystemName: iconInfo.name,
                    color: iconInfo.color
                )
                
                newTopics.append(topic)
            }
        }
        
        return newTopics
    }
}

// MARK: - TrendingTopicCard
struct TrendingTopicCard: View {
    let topic: TrendingTopic
    @EnvironmentObject var aiManager: AIManager
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Card content
            Button(action: {
                showDetails = true
            }) {
                VStack(alignment: .leading, spacing: 16) {
                    // Topic header with icon
                    HStack {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(topic.color.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: topic.imageSystemName)
                                .font(.system(size: 24))
                                .foregroundColor(topic.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Category chip
                            Text(topic.category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(topic.color.opacity(0.2))
                                .foregroundColor(topic.color)
                                .cornerRadius(12)
                            
                            // Title
                            Text(topic.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.primaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Trending icon
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(Color.primaryAccent)
                            .font(.system(size: 16))
                    }
                    
                    // Description preview - show only 2 lines
                    Text(topic.description)
                        .font(.subheadline)
                        .foregroundColor(Color.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Bottom row with stats
                    HStack {
                        // User count
                        Label("324 discussing", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(Color.secondaryText)
                        
                        Spacer()
                        
                        // Time
                        Text("Trending now")
                            .font(.caption)
                            .foregroundColor(Color.secondaryText)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showDetails) {
            TopicDetailView(topic: topic)
                .environmentObject(aiManager)
        }
    }
}

// MARK: - TopicDetailView
struct TopicDetailView: View {
    let topic: TrendingTopic
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var aiManager: AIManager
    @StateObject private var debateAIManager = AIManager(chatType: .debate) // Dedicated AIManager just for debates with debate chat type
    @State private var showingChat = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Topic header
                    HStack(spacing: 15) {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(topic.color.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: topic.imageSystemName)
                                .font(.system(size: 30))
                                .foregroundColor(topic.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Category chip
                            Text(topic.category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(topic.color.opacity(0.2))
                                .foregroundColor(topic.color)
                                .cornerRadius(12)
                            
                            // Title
                            Text(topic.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.primaryText)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Full description
                    Text(topic.description)
                        .font(.body)
                        .foregroundColor(Color.primaryText)
                        .padding(.horizontal)
                    
                    // Stats section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("324 discussing", systemImage: "person.2.fill")
                                .font(.subheadline)
                                .foregroundColor(Color.secondaryText)
                            
                            Spacer()
                            
                            Label("Trending now", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.subheadline)
                                .foregroundColor(Color.primaryAccent)
                        }
                        
                        Text("Join the conversation on this trending topic")
                            .font(.headline)
                            .foregroundColor(Color.primaryText)
                    }
                    .padding()
                    .background(Color.secondaryCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // Debate button
                    Button(action: {
                        startDebate()
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
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("Topic Details", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .fullScreenCover(isPresented: $showingChat) {
                DebateView(topic: topic)
                    .environmentObject(debateAIManager) // Use debate-specific AI manager
            }
            .onAppear {
                // Configure debate AI manager with same settings as main AI manager
                configureDebateAIManager()
            }
        }
    }
    
    private func configureDebateAIManager() {
        // Configure with the working URL and main model
        debateAIManager.configure(
            serverAddress: "https://db53-4-43-60-6.ngrok-free.app/api/generate",
            model: "gemma3:latest",
            personality: "You are a thoughtful debate partner discussing '\(topic.title)'. Provide balanced, informed perspectives on this topic while engaging directly with the user's points. Present substantive arguments backed by evidence when possible. Ask thought-provoking questions that advance the conversation."
        )
        
        // Make sure the debate manager has a clean history
        debateAIManager.clearHistory()
    }
    
    private func startDebate() {
        // Reset chat history and prepare for debate (using debate-specific manager)
        debateAIManager.clearHistory()
        
        // Show the chat interface
        showingChat = true
    }
}

// MARK: - Preview for TrendingTopicCard and ForYouView
struct TrendingTopicCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview of a single card
            TrendingTopicCard(topic: TrendingTopic.sampleTopics[0])
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Trending Topic Card")
                .environmentObject(AIManager(chatType: .mainChat))
            
            // Preview of the ForYou view
            NavigationView {
                ZStack {
                    Color.appBackground.edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Trending Topics")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.primaryText)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Color.primaryAccent)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        
                        // TikTok-style scrolling feed
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(TrendingTopic.sampleTopics) { topic in
                                    TrendingTopicCard(topic: topic)
                                        .environmentObject(AIManager(chatType: .mainChat))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .previewDisplayName("For You View")
            .environmentObject(AIManager(chatType: .mainChat))
            
            // Preview of the detail view
            TopicDetailView(topic: TrendingTopic.sampleTopics[0])
                .environmentObject(AIManager(chatType: .mainChat))
                .previewDisplayName("Topic Detail View")
        }
    }
}

// MARK: - DebateView
struct DebateView: View {
    let topic: TrendingTopic
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var aiManager: AIManager // This is now the debate-specific AIManager from TopicDetailView
    @State private var hasStartedDebate = false
    @State private var userInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isProcessing = false
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.primaryText)
                }
                
                Spacer()
                
                Text("Debate: \(topic.title)")
                    .font(.headline)
                    .foregroundColor(Color.primaryText)
                
                Spacer()
                
                // Empty view for balance
                Image(systemName: "chevron.left")
                    .font(.system(size: 16))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            
            // Custom debate chat interface - with more space at top
            debateChat
                .layoutPriority(1)
                .padding(.top, 12) // Add more top padding to give content more space
            
            // Message input field - positioned higher
            debateInputField
                .background(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -1)
                .padding(.bottom, keyboardHeight > 0 ? 0 : 25) // Add more padding when keyboard is hidden
        }
        .background(Color.appBackground)
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            if !hasStartedDebate {
                startDebate()
            }
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        // Add swipe back gesture
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && value.startLocation.x < 50 {
                        // User swiped from left edge to right - dismiss
                        dismiss()
                    }
                }
        )
    }
    
    // Custom debate chat view
    private var debateChat: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                    
                    if isProcessing {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                    }
                    
                    // Empty view at the bottom for scrolling
                    Color.clear
                        .frame(height: 24)
                        .id("bottomID")
                }
                .padding(.horizontal, 8)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .background(Color.appBackground)
            .onTapGesture {
                // Dismiss keyboard when tapping the chat area
                dismissKeyboard()
            }
            .onAppear {
                // Store proxy for use elsewhere
                scrollProxy = scrollViewProxy
                scrollToLastMessage()
            }
            .onChange(of: messages.count) { _, _ in
                // Scroll to bottom when new messages are added
                scrollToLastMessage()
            }
        }
    }
    
    // Input field for debate
    private var debateInputField: some View {
        HStack(spacing: 12) {
            // Text input field
            TextField("Type your message...", text: $userInput, axis: .vertical)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.secondaryCardBackground)
                .cornerRadius(24)
                .submitLabel(.send)
                .lineLimit(5)
                .disabled(isProcessing)
                .focused($isInputFocused)
                .font(.system(size: 16))
                .onSubmit {
                    sendDebateMessage()
                }
                .keyboardType(.default)
                .autocorrectionDisabled()
                .autocapitalization(.sentences)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            
            // Send button
            Button(action: sendDebateMessage) {
                Circle()
                    .fill(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing 
                          ? Color.secondaryText.opacity(0.3) 
                          : Color.primaryAccent)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16) // Increased padding to move input higher
    }
    
    private func sendDebateMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isProcessing else { return }
        
        let messageText = userInput
        userInput = ""
        
        // Dismiss keyboard immediately when sending
        dismissKeyboard()
        
        // Add user message to UI and history
        let userMessage = ChatMessage(id: UUID(), content: messageText, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        // Generate AI response specifically for this debate
        isProcessing = true
        
        // Create a debate-specific prompt that includes the topic context
        let debatePrompt = """
        \(messageText)
        """
        
        // Add timeout handling to prevent infinite loading
        let timeoutWorkItem = DispatchWorkItem {
            if self.isProcessing {
                print("Debate message request timed out after 30 seconds")
                DispatchQueue.main.async {
                    self.isProcessing = false
                    let errorMessage = ChatMessage(
                        id: UUID(),
                        content: "⚠️ CONNECTION TIMEOUT: The AI server took too long to respond. Please try again.",
                        isUser: false,
                        timestamp: Date()
                    )
                    self.messages.append(errorMessage)
                }
            }
        }
        
        // Schedule timeout after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeoutWorkItem)
        
        // Use the debate-specific AIManager instance with the model
        aiManager.generateResponse(userMessage: debatePrompt, model: "gemma3:latest") { result in
            // Cancel timeout since we got a response
            timeoutWorkItem.cancel()
            
            print("Debate message response received")
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.isProcessing = false
                    let aiMessage = ChatMessage(id: UUID(), content: response, isUser: false, timestamp: Date())
                    self.messages.append(aiMessage)
                    
                case .failure(let error):
                    // Try alternative URL
                    print("First URL failed for message: \(error.localizedDescription), trying alternative URL")
                    self.tryAlternativeURLForMessage(messageText: messageText)
                }
            }
        }
    }
    
    private func tryAlternativeURLForMessage(messageText: String) {
        // Configure with an alternative URL and try full model name
        aiManager.configure(
            serverAddress: "https://db53-4-43-60-6.ngrok-free.app/api/generate",
            model: "gemma3:latest",
            personality: aiManager.personalityPrompt
        )
        
        // Try again with new URL
        aiManager.generateResponse(userMessage: messageText, model: "gemma3:latest") { result in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = ChatMessage(id: UUID(), content: response, isUser: false, timestamp: Date())
                    self.messages.append(aiMessage)
                    
                case .failure(let error):
                    // Show error to user
                    print("All URLs failed for message: \(error.localizedDescription)")
                    
                    let errorMessage = ChatMessage(
                        id: UUID(),
                        content: "⚠️ CONNECTION ERROR: I couldn't connect to the AI server. Your message has been saved and I'll respond when connectivity is restored.",
                        isUser: false, 
                        timestamp: Date()
                    )
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height
                // Scroll to latest message when keyboard shows
                self.scrollToLastMessage()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.keyboardHeight = 0
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isInputFocused = false
    }
    
    private func startDebate() {
        hasStartedDebate = true
        isProcessing = true
        
        print("Starting debate on topic: \(topic.title) with model: gemma3:latest")
        
        // Create a debate-specific introduction prompt that contains the topic context
        let introPrompt = """
        Topic: "\(topic.title)" 
        Context: \(topic.description)
        
        You are starting a debate on this topic. Begin with a VERY brief (2-3 sentences) introduction followed by a thought-provoking question. Be conversational and engaging. Do NOT write a long essay or formal debate introduction. Keep it under 75 words total.
        """
        
        // Add timeout handling to prevent infinite loading
        let timeoutWorkItem = DispatchWorkItem {
            if self.isProcessing {
                print("Debate request timed out after 30 seconds")
                DispatchQueue.main.async {
                    self.isProcessing = false
                    let errorMessage = ChatMessage(
                        id: UUID(),
                        content: "⚠️ CONNECTION TIMEOUT: The AI server took too long to respond. Please try again.",
                        isUser: false,
                        timestamp: Date()
                    )
                    self.messages.append(errorMessage)
                }
            }
        }
        
        // Schedule timeout after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeoutWorkItem)
        
        // Use the dedicated debate AI manager
        aiManager.generateResponse(userMessage: introPrompt, model: "gemma3:latest") { result in
            // Cancel timeout since we got a response
            timeoutWorkItem.cancel()
            
            print("Debate response received for \(topic.title)")
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.isProcessing = false
                    let aiMessage = ChatMessage(id: UUID(), content: response, isUser: false, timestamp: Date())
                    self.messages.append(aiMessage)
                    
                case .failure(let error):
                    // Try an alternative URL if the first one failed
                    print("First URL failed: \(error.localizedDescription), trying alternative URL")
                    self.tryAlternativeURL(introPrompt: introPrompt)
                }
            }
        }
    }
    
    private func tryAlternativeURL(introPrompt: String) {
        // Configure with an alternative URL
        aiManager.configure(
            serverAddress: "https://db53-4-43-60-6.ngrok-free.app/api/generate",
            model: "gemma3:latest",
            personality: aiManager.personalityPrompt
        )
        
        // Try again with new URL
        aiManager.generateResponse(userMessage: introPrompt, model: "gemma3:latest") { result in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = ChatMessage(id: UUID(), content: response, isUser: false, timestamp: Date())
                    self.messages.append(aiMessage)
                    
                case .failure(let error):
                    print("All URLs failed: \(error.localizedDescription)")
                    
                    // Show just the error message without offline fallback
                    let errorMessage = ChatMessage(
                        id: UUID(),
                        content: "⚠️ CONNECTION ERROR: The AI server is currently unavailable. We've saved your messages and will restore the conversation when connectivity returns.",
                        isUser: false,
                        timestamp: Date()
                    )
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    // Helper function to scroll to bottom
    private func scrollToLastMessage() {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                if let lastID = messages.last?.id {
                    scrollProxy?.scrollTo(lastID, anchor: .bottom)
                } else {
                    scrollProxy?.scrollTo("bottomID", anchor: .bottom)
                }
            }
        }
    }
}
