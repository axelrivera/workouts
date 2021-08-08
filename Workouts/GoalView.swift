//
//  GoalView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/25/21.
//

import SwiftUI

struct GoalView: View {
    enum Status {
        case pending, progress, completed
        
        var color: Color {
            switch self {
            case .pending: return .secondary
            case .progress: return .yellow
            case .completed: return .green
            }
        }
        
        var image: String {
            switch self {
            case .pending: return "circle"
            case .progress: return "bolt.horizontal.circle"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Cycling this Week")
                .font(.title3)
            
            HStack(spacing: 20) {
                Image(systemName: status.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(status.color)
                    
                VStack(alignment: .leading) {
                    Text("63 mi of 75 mi")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    BarView(value: 0.5, total: 1, barColor: .accentColor)
                }
                
                Text("50%")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct GoalView_Previews: PreviewProvider {
    static var previews: some View {
        GoalView(status: .progress)
            .padding()
    }
}
