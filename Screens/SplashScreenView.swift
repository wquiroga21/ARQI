//
//  SplashScreenView.swift
//  SeniorProject
//
//  Created by William Quiroga on 3/7/25.
//

import SwiftUI

struct SplashScreenView: View {
    // Animation states for loading dots
    @State private var isAnimating = false
    
    // Explicitly define the beige background color
    private let beigeBackground = Color(hex: "#F5F1E6") // Warm off-white/beige from AppTheme
    
    var body: some View {
        ZStack {
            // Background color
            beigeBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                Spacer()
                
                // App logo - using the orange "A" logo
                Image("Logo") // Make sure this matches your asset name
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                
                // Simple loading dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.primaryAccent)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Start the loading dots animation
            isAnimating = true
        }
    }
}

// MARK: - Preview
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
} 
