//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import Combine

struct SettingsView: View {
    enum ActiveSheet: Identifiable {
        case paywall, feedback, faq, tutorial, privacy
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Identifiable {
        case emailError
        case regenerateWorkouts
        var id: Int { hashValue }
    }
    
    @Environment(\.openURL) var openURL
    @Environment(\.managedObjectContext) var viewContext
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @State private var weight: Double = AppSettings.weight
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
        
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    if purchaseManager.isActive {
                        Section(header: Color.clear.frame(height: 20.0)) {
                            HStack(spacing: 10.0) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2.0) {
                                    Text("Better Workouts Pro")
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
                        Section(header: Color.clear.frame(height: 20.0), footer: Text("Purchasing helps support Better Workouts.")) {
                            Button(action: { activeSheet = .paywall }, label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                    Text("Unlock all Better Workouts Features")
                                        .foregroundColor(.primary)
                                }
                            })
                        }
                    }
                    
                    Section(header: Text("Application Settings")) {
                        NavigationLink(destination: HeartRateView()) {
                            Label("Heart Rate Zones", systemImage: "bolt.heart.fill")
                        }
                        
                        Button(action: { activeAlert = .regenerateWorkouts }) {
                            Text("Reset Workout Data")
                        }
                        .disabled(workoutManager.isLoading)
                    }
                    
                    Section(header: Text("Help Center"), footer: Text("Suggestions and feature requests are welcome.")) {
                        //Button("Import Workout Tutorial", action: { activeSheet = .tutorial })
                        //Button("Frequently Asked Questions", action: { activeSheet = .faq })
                        Button("Send Feedback", action: feedbackAction)
                    }
                    
                    Section(header: Text("Better Workouts")) {
                        Button("Review on the App Store", action: reviewAction)
                        Button("Privacy Policy", action: { activeSheet = .privacy })
                        HStack {
                            Text("Version")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(systemVersionAndBuildString())
                        }
                    }
                }
                .disabled(workoutManager.isProcessingRemoteData)
                
                if workoutManager.isProcessingRemoteData {
                    ProcessView(text: "Processing Workouts...", value: $workoutManager.processingRemoteDataValue)
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    UpgradeView()
                case .tutorial:
                    SafariView(urlString: URLStrings.tutorial)
                case .privacy:
                    SafariView(urlString: URLStrings.privacy)
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
                case .regenerateWorkouts:
                    let title = "Reset Workouts"
                    let message = String(format: "This action will reset and regenerate your local workout data from Apple Health.")
                    let continueButton: Alert.Button = .default(Text("Continue")) {
                        let userInfo = [Notification.regenerateDataKey: true]
                        NotificationCenter.default.post(name: .shouldFetchRemoteData, object: nil, userInfo: userInfo)
                    }
                    let cancelButton: Alert.Button = .cancel(Text("Cancel"))
                                        
                    return Alert(
                        title:  Text(title),
                        message: Text(message),
                        primaryButton: continueButton,
                        secondaryButton: cancelButton
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
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    
    static let purchaseManager: IAPManager = {
        let manager = IAPManager()
        manager.isActive = true
        return manager
    }()
    
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(WorkoutManager(context: viewContext))
            .environmentObject(purchaseManager)
            .colorScheme(.dark)
    }
}
