import SwiftUI

// MARK: - Shared Components
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