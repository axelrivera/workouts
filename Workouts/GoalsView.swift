//
//  GoalsView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/29/21.
//

import SwiftUI

struct GoalsView: View {
    let statuses: [GoalView.Status] = [.pending, .progress, .completed]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(statuses, id: \.self) { status in
                    NavigationLink(destination: Text("Goals View")) {
                        GoalView(status: status)
                            .padding([.top, .bottom], CGFloat(10.0))
                    }
                }
            }
            .navigationTitle("Goals")
        }
    }
}

struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
    }
}
