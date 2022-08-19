//
//  SettingsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct SettingsView: View {
    enum ActiveSheet: Identifiable, Hashable {
        case paywall, feedback, share, website(urlString: String, reader: Bool = true)
        var id: Self { self }
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
                    NavigationLink(destination: TagsManageView()) {
                        Label("Manage Tags", systemImage: "tag.fill")
                    }
                    
                    NavigationLink(destination: HeartRateView()) {
                        Label("Heart Rate", systemImage: "heart.fill")
                    }
                    
                    NavigationLink(destination: AdvancedSettingsView()) {
                        Label("Advanced", systemImage: "gearshape.2.fill")
                    }
                }
                
                Section(header: Text("Help Center"), footer: Text("Suggestions and feature requests are welcome.")) {
                    Button("Frequently Asked Questions", action: { activeSheet = .website(urlString: URLStrings.faq, reader: false) })
                    Button("Send Feedback", action: feedbackAction)
                }
                
                Section(header: Text("Better Workouts"), footer: footerView()) {
                    Button("About Rivera Labs", action: { activeSheet = .website(urlString: URLStrings.about) })
                    Button("Review on the App Store", action: reviewAction)
                    Button("Share with Friends", action: { activeSheet = .share })
                    Button("Privacy Policy", action: { activeSheet = .website(urlString: URLStrings.privacy) })
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
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView(source: .settings)
                        .environmentObject(purchaseManager)
                case .share:
                    ActivitySheet(items: [URL(string: URLStrings.iTunesURL)!])
                case .website(let url, let reader):
                    SafariView(urlString: url, entersReaderIfAvailable: reader)
                        .ignoresSafeArea(.all, edges: .bottom)
                case .feedback:
                    MailView(recepients: [Emails.support], subject: feedbackSubject(), body: feedbackBody())
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .emailError:
                    let message = String(format: "Unable to send email from this device. If you need support please send me an email to %@", Emails.support)
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
    
    @ViewBuilder
    func footerView() -> some View {
        VStack(spacing: 5.0) {
            Text("© 2021 Rivera Labs LLC")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Made with ❤️ in Orlando, FL")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.subheadline)
        .padding(.top, CGFloat(15.0))
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
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
    
    func feedbackSubject() -> String {
        let (version, _) = systemVersionAndBuild()
        return String(format: "Better Workouts %@", version)
    }
    
    func feedbackBody() -> String {
        let device = UIDevice.current
        
        let systemName = device.systemName
        let systemVersion = device.systemVersion
        let model = device.localizedModel

        let content = """
        \n\n\n\n
        %@ %@ %@
        """

        return String(format: content, model, systemName, systemVersion)
    }
    
    func reviewAction() {
        openURL(URL(string: URLStrings.iTunesReview)!)
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static let viewContext = WorkoutsProvider.preview.container.viewContext
    static let purchaseManager = IAPManagerPreview.manager(isActive: false)
    
    static var previews: some View {
        SettingsView()
            .environmentObject(WorkoutManagerPreview.manager(context: viewContext))
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}
