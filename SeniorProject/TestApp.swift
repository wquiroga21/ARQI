//
//  TestApp.swift
//  SeniorProject
//
//  Created by William Quiroga on 02/26/25.
//

import SwiftUI

struct TestApp: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase Test App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("If you can see this, the app is launching successfully")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Test Button") {
                print("Button pressed")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    TestApp()
}
