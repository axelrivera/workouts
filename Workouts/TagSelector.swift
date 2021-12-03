//
//  TagSelector.swift
//  Workouts
//
//  Created by Axel Rivera on 11/21/21.
//

import SwiftUI
import CryptoKit

struct TagSelector: View {
    enum ActiveSheet: Identifiable {
        case paywall
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var purchaseManager: IAPManager
    
    @Binding var tags: [Tag]
    @Binding var selectedTags: Set<Tag>
    
    @State private var activeSheet: ActiveSheet?
    
    var toggleAction: (_ tag: Tag) -> Void
        
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 5.0) {
                ForEach(tags, id: \.self) { tag in
                    Button(action: { toggleTag(tag) }) {
                        HStack {
                            GearImage(gearType: tag.gearType)
                                .foregroundColor(tag.colorValue)
                            Text(tag.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: isSelected(tag) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(tag.colorValue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(backgroundForTag(tag))
                        .cornerRadius(12.0)
                    }
                }
                
                if !purchaseManager.isActive {
                    Button(action: { activeSheet = .paywall }) {
                        VStack(spacing: CGFloat(5.0)) {
                            Text("Try out existing tags FREE!")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.5))
                            Label("Upgrade to Pro Now", systemImage: "lock.fill")
                            Text("New Tags require Pro version")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.4))
                        }
                    }
                    .buttonStyle(PaywallButtonStyle())
                    .padding(.top)
                }
            }
            .padding()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .paywall:
                PaywallView()
                    .environmentObject(purchaseManager)
            }
        }
    }
}

extension TagSelector {
    
    func isSelected(_ tag: Tag) -> Bool {
        selectedTags.contains(tag)
    }
    
    func backgroundForTag(_ tag: Tag) -> Color {
        if isSelected(tag) {
            return tag.colorValue.opacity(0.25)
        } else {
            return Color.systemFill
        }
    }
    
    func toggleTag(_ tag: Tag) {
        toggleAction(tag)
    }
    
}

struct TagSelector_Previews: PreviewProvider {
    static var purchaseManager = IAPManagerPreview.manager(isActive: false)
    
    static var previews: some View {
        TagSelector(tags: .constant([]), selectedTags: .constant([])) { tag in
            
        }
        .environmentObject(purchaseManager)
    }
}
