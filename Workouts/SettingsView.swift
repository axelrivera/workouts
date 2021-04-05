//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct SettingsView: View {
    enum ActiveSheet: Identifiable {
        case paywall, feedback, faq, tutorial
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Identifiable {
        case emailError
        var id: Int { hashValue }
    }
    
    @Environment(\.openURL) var openURL
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @State private var weight: Double = AppSettings.weight
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
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
                
//                Section(header: Text("Application Settings")) {
//                    NavigationLink(destination: WeightInputView(weight: $weight)) {
//                        HStack {
//                            Text("Weight")
//                                .foregroundColor(.secondary)
//                            Spacer()
//                            Text(formattedWeightString(for: weight))
//                                .foregroundColor(.primary)
//                        }
//                    }
//                }
                
                Section(header: Text("Help Center"), footer: Text("Helpful hints to learn how to make the most out of Better Workouts.")) {
                    Button("Import Workout Tutorial", action: { activeSheet = .tutorial })
                    Button("Frequently Asked Questions", action: { activeSheet = .faq })
                    Button("Send Feedback", action: feedbackAction)
                }
                
                Section(header: Text("Better Workouts")) {
                    Button("Review on the App Store", action: reviewAction)
                    NavigationLink("Privacy Policy", destination: WebContent(title: "Privacy Policy", urlString: URLStrings.privacy))
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(systemVersionAndBuildString())
                    }
                }
                
            }
            .navigationBarTitle("Settings")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    UpgradeView()
                case .tutorial:
                    SafariView(urlString: URLStrings.tutorial)
                case .faq:
                    SafariView(urlString: URLStrings.faq)
                case .feedback:
                    MailView(recepients: [Emails.support], subject: "Better Workouts Feedback", body: feedbackBody())
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .emailError:
                    let message = String(format: "Unable to send email from this device. If you need support please send us an email to %@", Emails.support)
                    return Alert(
                        title:  Text("Email Error"),
                        message: Text(message),
                        dismissButton: .default(Text("Ok"))
                    )
                }
            }
        }
    }
}

extension SettingsView {
    
    func feedbackAction() {
        guard MailView.canSendEmail else {
            activeAlert = .emailError
            return
        }
        
        activeSheet = .feedback
    }
    
    func feedbackBody() -> String {
        let device = UIDevice.current
        let (version, build) = systemVersionAndBuild()
        let systemName = device.systemName
        let systemVersion = device.systemVersion
        let model = device.localizedModel

        let content = """
        \n\n\n\n
        Better Workouts Version %@ (%@) - %@ %@ %@
        """

        return String(format: content, version, build, model, systemName, systemVersion)
    }
    
    func reviewAction() {
        openURL(URL(string: URLStrings.iTunesReview)!)
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
