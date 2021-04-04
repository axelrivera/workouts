//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct SettingsView: View {
    enum ActiveSheet: Identifiable {
        case paywall, feedback, faq
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @State private var weight: Double = AppSettings.weight
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            Form {
                if purchaseManager.isActive {
                    Section {
                        HStack(spacing: 10.0) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            VStack(alignment: .leading, spacing: 2.0) {
                                Text("Better Workout Pro")
                                Text("Thank your for your support!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        #if DEVELOPMENT_BUILD
                        Button("Reset Mock Purchase", action: purchaseManager.resetMockPurchase)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                        #endif
                    }
                } else {
                    Section(footer: Text("Purchasing helps support Better Workouts.")) {
                        Button(action: { activeSheet = .paywall }, label: {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text("Unlock all Better Workout Features")
                                    .foregroundColor(.primary)
                            }
                        })
                    }
                }
                
                Section(header: Text("Application Settings")) {
                    NavigationLink(destination: WeightInputView(weight: $weight)) {
                        HStack {
                            Text("Weight")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedWeightString(for: weight))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("Help Center"), footer: Text("Helpful hints to learn how to make the most out of Better Workouts.")) {
                    NavigationLink("Import Workout Tutorial", destination: WebContent(title: "Import Tutorial", urlString: URLStrings.tutorial))
                    Button("Frequently Asked Questions", action: { activeSheet = .faq })
                    Button("Send Feedback", action: {})
                }
                
                Section(header: Text("Better Workouts")) {
                    Button("Review on the App Store", action: {})
                    NavigationLink("Privacy Policy", destination: WebContent(title: "Privacy Policy", urlString: URLStrings.privacy))
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0 (13)")
                    }
                }
                
            }
            .navigationBarTitle("Settings")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    UpgradeView()
                case .faq:
                    SafariView(urlString: URLStrings.faq)
                default:
                    EmptyView()
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static let purchaseManager: IAPManager = {
        let manager = IAPManager()
        manager.isActive = true
        return manager
    }()
    
    static var previews: some View {
        SettingsView()
            .environmentObject(WorkoutManager())
            .environmentObject(purchaseManager)
            .colorScheme(.dark)
    }
}
