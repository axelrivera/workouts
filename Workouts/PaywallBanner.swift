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
                    Text("Better Workouts Pro")
                        .font(isActive ? .fixedTitle2 : .fixedTitle)
                    Text("Thank you for your support!")
                        .font(.fixedSubheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack {
                    Text("Better Workouts Pro")
                        .font(.fixedTitle)
                    Text("All features for a one time payment!")
                        .font(.fixedBody)
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                }
               
                VStack {
                    PaywallButton(action: action)
                    Text("Purchasing helps support future development.")
                        .font(.fixedSubheadline)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(PlainButtonStyle())
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
            VStack(spacing: 20.0) {
                PaywallBanner(isActive: true, action: {})
                PaywallBanner(isActive: false, action: {})
                PaywallLockButton(action: {})
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
        Button("Upgrade to Pro Now", action: action)
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
    var action = {}
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "lock.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 92.0, height: 92.0, alignment: .center)
        }
        .buttonStyle(PaywallLockButtonStyle())
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
