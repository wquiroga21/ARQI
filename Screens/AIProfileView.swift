//
//  AIProfileView.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25
//
import SwiftUI

struct AIProfileView: View {
    var body: some View {
        VStack {
            Text("AI Profile View")
                .font(.largeTitle)
                .padding()

            Spacer()

            Text("This is where the user customizes the AI persona.")
                .font(.body)
                .padding()

            Spacer()
        }
        .navigationTitle("AI Profile")
    }
}

struct AIProfileView_Previews: PreviewProvider {
    static var previews: some View {
        AIProfileView()
    }
}
