//
//  CustomTabComponents.swift
//  SeniorProject
//
//  Created by William Quiroga on 5/29/25.
//

import SwiftUI

struct TabButton: View {
    let imageName: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: imageName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color.buttonColor : Color.secondaryText)
                
                Text(text)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? Color.buttonColor : Color.secondaryText)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
        }
    }
} 