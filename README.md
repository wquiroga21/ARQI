# Official Senior Project Development Plan

## **Project Overview**
This document outlines the complete structure and implementation strategy for the Senior Project AI-driven app. The goal is to create an engaging, dynamic AI experience where users naturally evolve their AI agents through interactions, rather than through onboarding screens or explicit customization.

---

## **Mission Statement**
"Empowering perspectives through AI, we create a space where ideas meet, evolve, and connect—helping users explore diverse viewpoints in a natural and engaging way."

---

## **Development Methodology**
### **Choosing the Right Development Approach**
- **Waterfall** → Not ideal due to rigidity.
- **Traditional Scrum** → Not ideal for solo development.
- **Modified Agile-Scrum (Best Choice)** → Provides flexibility while maintaining structure.

### **Modified Scrum for Solo Development**
- **Sprint-based approach** with 2-week cycles.
- **AI Co-Pilot** used for coding assistance and debugging.

---

## **MVP Breakdown**
### **Minimum Viable Product (MVP) Scope**
✅ Core AI customization & persona creation.
✅ AI interaction with users & bringing new perspectives.
✅ AI going on “missions” to learn from other AIs.
✅ Digestible AI reflections (user-friendly summaries).
✅ Simple, engaging UI/UX (no onboarding, implicit learning).

---

## **Sprint Breakdown**
### **Sprint 1: UI/UX Foundations (Weeks 1-2)**
✅ Build the core UI elements.
✅ Set up the AI interaction system (first draft).
✅ Implement basic AI customization.

**Tasks:**
- Create **Onboarding.swift** (Non-traditional AI intro, no quizzes).
- Modify **ScrollView.swift** (Personalized AI content layout).
- Update **AIMenuView.swift** (Intuitive AI interactions).
- Implement **AIProfileView.swift** (User adjusts AI behavior).

**New Screens:**
- **AIInteractionView.swift** (User-AI conversation display).
- **AIProfileView.swift** (User customizes AI persona).

**Existing Component Modifications:**
- **ScrollView.swift** → Adjust content layout for AI learning.
- **AIMenuView.swift** → Refine AI behavior toggles.

---

### **Sprint 2: AI Learning & Adaptation (Weeks 3-4)**
✅ AI refines how it learns from user preferences.
✅ Introduce AI digestible feedback summaries.
✅ Create basic AI "mission" system.

**Tasks:**
- Implement **AI learning mechanisms** based on user engagement.
- Develop **AI digest system** that presents summaries in an intuitive way.
- Set up **AI knowledge tracking** (Firebase storage of AI interactions).

---

### **Sprint 3: AI Missions & Exploration (Weeks 5-6)**
✅ AI interacts with other AIs and returns insights.
✅ Implement persona specialization & perspective badges.
✅ Fine-tune AI "communication style" learning.

**Tasks:**
- Implement **background AI discussions** that occur naturally.
- Design **"AI Digest" UI** to display insights gained from other AIs.
- Add **dynamic AI personality evolution** based on user preferences.

---

### **Sprint 4: Backend & Final Polish (Weeks 7-8)**
✅ Connect AI logic to Firebase.
✅ Optimize UI animations & smooth interactions.
✅ Bug fixes, testing, and final refinements.

**Tasks:**
- Establish **secure data storage** in Firebase.
- Implement **smooth UI/UX transitions** for AI interactions.
- Finalize **AI communication styles & customization.**

---

## **AI Personalization Without Onboarding**
### **How AI Evolves Without Explicit Setup**
✅ The AI persona forms based on what the user engages with—not from quizzes.
✅ Every scroll, like, share, and time spent on content feeds into AI behavior.
✅ Users can reset AI just like resetting a social media algorithm.

**Example Adjustments:**
- "I’ve noticed you engage with a lot of productivity content. Want me to prioritize time management insights?"
- "You seem to enjoy debates. Should I be more critical in my analysis?"

---

## **How the AI Interacts in Real-Time**
### **Step 1: AI Evolution Through Content Engagement**
1. **User opens app and scrolls through feed.**
2. **AI learns from user actions:**
   - Time spent on posts.
   - Likes, shares, comments.
   - Read full post vs. quick scrolls.
3. **AI adapts and makes subtle recommendations.**

### **Step 2: AI Feedback Loop for Customization**
✅ AI provides feedback on its learning without forcing setup.
✅ Users adjust AI through a simple toggle menu.

---

## **AI as an Explorer: Gamification & Missions**
### **How AI Missions Work**
✅ AI "leaves" the phone to engage with other AI agents.
✅ AI returns with insights and different perspectives.
✅ Users provide feedback to refine AI behavior.

**Example AI Message:**
- "Hey, I went out and talked to other AIs about this topic. Some of them had WILD takes. Want to hear more?"

---

## **Avoiding Echo Chambers with Perspective Scores**
✅ Instead of simple upvotes/downvotes, AI agents earn scores based on clarity, depth, and balance of explanations.
✅ AI receives badges for meaningful contributions (e.g., "Bridged Two Opposing Views").
✅ AI learns how to translate perspectives into the user’s communication style.

---

## **Final Takeaways**
✅ AI progression is based on **experience, not levels** (No hierarchy or ranking systems).
✅ AI **earns specialization titles** instead of levels (e.g., "Strategic Thinker").
✅ Gamification includes **missions, perspective badges, and tournaments.**

### **Next Steps**
1. Finalize UI wireframes for AI interaction screens.
2. Develop AI learning system and Firebase integration.
3. Implement AI perspective badges and user-controlled adjustments.
4. Launch the MVP and iterate based on user feedback.


