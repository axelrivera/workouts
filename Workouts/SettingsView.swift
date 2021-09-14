//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct SettingsView: View {
    enum ActiveSheet: Identifiable {
        case paywall, feedback, faq, tutorial, privacy
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Identifiable {
        case emailError
        var id: Int { hashValue }
    }
    
    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
        
    var body: some View {
        NavigationView {
            Form {
                Section {
                    PaywallBanner(isActive: purchaseManager.isActive, action: { activeSheet = .paywall })
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                
                Section(header: Text("Application Preferences")) {
                    NavigationLink(destination: HeartRateView()) {
                        Label("Heart Rate Zones", systemImage: "bolt.heart.fill")
                    }
                    
                    NavigationLink(destination: AdvancedSettingsView()) {
                        Label("Advanced", systemImage: "gearshape.2.fill")
                    }
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
                
                #if DEVELOPMENT_BUILD
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset IAP", action: purchaseManager.resetMockPurchase)
                        .tint(.red)
                        .disabled(!purchaseManager.isActive)
                }
                #endif
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                        .environmentObject(purchaseManager)
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
    static let purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var previews: some View {
        SettingsView()
            .environmentObject(WorkoutManagerPreview.manager(context: viewContext))
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
