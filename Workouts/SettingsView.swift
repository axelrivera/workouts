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
                
                Section(header: Text(NSLocalizedString("Application Preferences", comment: "Label"))) {
                    NavigationLink(destination: TagsManageView()) {
                        Label(NSLocalizedString("Manage Tags", comment: "Label"), systemImage: "tag.fill")
                    }
                    
                    NavigationLink(destination: HeartRateView()) {
                        Label(LabelStrings.heartRate, systemImage: "heart.fill")
                    }
                    
                    NavigationLink(destination: AdvancedSettingsView()) {
                        Label(NSLocalizedString("Advanced", comment: "Label"), systemImage: "gearshape.2.fill")
                    }
                }
                
                Section {
                    Button(NSLocalizedString("Frequently Asked Questions", comment: "Label"), action: { activeSheet = .website(urlString: URLStrings.faq, reader: false) })
                    Button(NSLocalizedString("Send Feedback", comment: "Label"), action: feedbackAction)
                } header: {
                    Text(NSLocalizedString("Help Center", comment: "Label"))
                } footer: {
                    Text(NSLocalizedString("Suggestions and feature requests are welcome.", comment: "Footer"))
                }
                
                Section {
                    Button(NSLocalizedString("About Rivera Labs", comment: "Action"), action: { activeSheet = .website(urlString: URLStrings.about) })
                    Button(NSLocalizedString("Review on the App Store", comment: "Action"), action: reviewAction)
                    Button(NSLocalizedString("Share with Friends", comment: "Action"), action: { activeSheet = .share })
                    Button(NSLocalizedString("Privacy Policy", comment: "Action"), action: { activeSheet = .website(urlString: URLStrings.privacy) })
                    HStack {
                        Text(NSLocalizedString("Version", comment: "Label"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(systemVersionAndBuildString())
                    }
                } header: {
                    Text(NSLocalizedString("Better Workouts", comment: "Label"))
                } footer: {
                    VStack(spacing: 5.0) {
                        Text(NSLocalizedString("© 2021 Rivera Labs LLC", comment: "Text"))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(NSLocalizedString("Made with ❤️ in Orlando, FL", comment: "Text"))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .font(.subheadline)
                    .padding(.top, CGFloat(15.0))
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .navigationTitle(NSLocalizedString("Settings", comment: "Screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.done, action: { presentationMode.wrappedValue.dismiss() })
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
                    let string = NSLocalizedString("Unable to send email from this device. If you need support please send me an email to %@", comment: "Email error message")
                    let message = String(format: string, Emails.support)
                    return Alert(
                        title:  Text(NSLocalizedString("Email Error", comment: "Alert title")),
                        message: Text(message),
                        dismissButton: .default(Text(ActionStrings.ok))
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
