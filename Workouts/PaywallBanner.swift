//
//  PaywallViewBanner.swift
//  Workouts
//
//  Created by Axel Rivera on 7/16/21.
//

import SwiftUI

struct PaywallBanner: View {
    
    var isActive: Bool
    var action = {}
    
    init(isActive: Bool, action: @escaping () -> Void) {
        self.isActive = isActive
        self.action = action
    }
    
    var imageWidth: CGFloat {
        isActive ? 25.0 : 50.0
    }
    
    var body: some View {
        VStack(spacing: isActive ? 5.0 : 15.0) {
            Image(systemName: isActive ? "heart.fill" : "flame.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageWidth, height: imageWidth)
                .foregroundColor(isActive ? .red : .white)
            if isActive {
                VStack {
                    Text(NSLocalizedString("Better Workouts Pro", comment: "Label"))
                        .font(isActive ? .fixedTitle2 : .fixedTitle)
                    Text(NSLocalizedString("Thank you for your support!", comment: "Text"))
                        .font(.fixedSubheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack {
                    Text(NSLocalizedString("Better Workouts Pro", comment: "Label"))
                        .font(.fixedTitle)
                    Text(NSLocalizedString("All features for a one time payment!", comment: "Text"))
                        .font(.fixedBody)
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                }
               
                VStack(alignment: .center) {
                    PaywallButton(action: action)
                        .buttonStyle(PlainButtonStyle())
                    Text(NSLocalizedString("Purchasing helps support future development.", comment: "Text"))
                        .font(.fixedSubheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        
                }
            }
        }
        .foregroundColor(isActive ? .primary : .white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(isActive ? Color.clear : Color.accentColor)
    }
    
}


struct PaywallBanner_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            Form {
                Section {
                    PaywallBanner(isActive: true, action: {})
                }
                
                Section {
                    PaywallBanner(isActive: false, action: {})
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: Button

struct PaywallButton: View {
    var action = {}
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(NSLocalizedString("Upgrade to Pro Now", comment: "Action"), action: action)
            .buttonStyle(PaywallButtonStyle())
    }
    
}

struct PaywallButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
        .foregroundColor(.black)
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding()
        .background(configuration.isPressed ? Color.lightGray : Color.yellow)
        .cornerRadius(Constants.cornerRadius)
        .shadow(radius: 1)
  }

}

// MARK: Lock Button

struct PaywallLockButton: View {
    enum ButtonType {
        case `default`, small
    }
    
    let sample: Bool
    let buttonType: ButtonType
    var action = {}
    
    init(sample: Bool = true, type: ButtonType = .default, action: @escaping () -> Void) {
        self.sample = sample
        self.buttonType = type
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10.0) {
                Image(systemName: "lock.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: buttonSize, height: buttonSize, alignment: .center)
                if showSample {
                    Text(NSLocalizedString("SAMPLE DATA", comment: "Label capitalized"))
                        .font(.fixedFootnote)
                        .foregroundColor(.black.opacity(0.75))
                }
            }
            .padding(.all, buttonType == .small ? 10 : nil)
        }
        .buttonStyle(PaywallLockButtonStyle())
    }
    
    var buttonSize: CGFloat {
        switch buttonType {
        case .default:
            return 64
        case .small:
            return 24
        }
    }
    
    var showSample: Bool {
        guard buttonType == .default else { return false }
        return sample
    }
    
}

struct PaywallLockButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
        .foregroundColor(.black)
        .padding()
        .background(configuration.isPressed ? Color.lightGray : Color.yellow)
        .clipShape(Circle())
        .shadow(radius: 1)
  }

}
