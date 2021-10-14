//
//  OnboardingView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct OnboardingView: View {
    enum Tabs: String, Identifiable {
        case watch, health
        var id: String { rawValue }
    }
    
    @Environment(\.colorScheme) var colorScheme
        
    var action = {}    
    @State private var selected = Tabs.watch
    
    var body: some View {
        TabView(selection: $selected) {
            WatchOnboarding(action: nextAction)
                .tag(Tabs.watch)
            
            HealthOnboarding(action: action)
                .tag(Tabs.health)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: colorScheme == .dark ? .never : .always))
    }
    
}

extension OnboardingView {
    
    func nextAction() {
        withAnimation {
            selected = .health
        }
    }
    
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .preferredColorScheme(.dark)
    }
}
