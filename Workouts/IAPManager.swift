//
//  IAPManager.swift
//  Workouts
//
//  Created by Axel Rivera on 3/28/21.
//

import SwiftUI
import Purchases

final class IAPManager: NSObject, ObservableObject {
    enum Constants {
        static let apiKey = "NYucELjRYAuIEelhphHUNKTcZYaCoRSH"
        static let entitlementId = "pro"
        static let freePrice = 1.99
        static let freePriceString = "$1.99"
    }
        
    @Published var purchaserInfo: Purchases.PurchaserInfo? {
        didSet {
            withAnimation {
                self.isActive = purchaserInfo?.entitlements[Constants.entitlementId]?.isActive == true
            }
        }
    }
    @Published var offerings: Purchases.Offerings?
    @Published var isActive: Bool = false {
        didSet {
            #if DEVELOPMENT_BUILD
            AppSettings.mockPurchaseActive = isActive
            #endif
        }
    }
    
    override init() {
        super.init()
        registerPurchasesManager()
        fetchOfferings()
    }
    
    static func preview(isActive: Bool = true) -> IAPManager {
        let manager = IAPManager()
        manager.isActive = isActive
        return manager
    }
    
}

// MARK: - Methods

extension IAPManager {
    
    private func registerPurchasesManager() {
        #if PRODUCTION_BUILD
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: Constants.apiKey)
        Purchases.shared.delegate = self
        #else
        Log.debug("skipping registring purchasing manager")
        #endif
    }
    
    private func fetchOfferings() {
        #if PRODUCTION_BUILD
        Purchases.shared.offerings { (offerings, error) in
            if let error = error {
                Log.debug("failed to fetch offierings: \(error.localizedDescription)")
            }
            
            if let offerings = offerings {
                for offering in offerings.all.values {
                    if let package = offering.lifetime {
                        Log.debug("package for id: \(package.identifier), description: \(package)")
                    } else {
                        Log.debug("Lifetime package not found for \(offering.identifier)")
                    }
                }
            }
            
            self.offerings = offerings
        }
        #elseif DEVELOPMENT_BUILD
        Log.debug("skipping fetching offerings")
        isActive = AppSettings.mockPurchaseActive
        #endif
    }
    
    var offering: Purchases.Offering? {
        offerings?.current
    }
    
    var package: Purchases.Package? {
        offering?.lifetime
    }
    
    var packagePrice: Double {
        #if PRODUCTION_BUILD
        return package?.product.price.doubleValue ?? 0
        #elseif DEVELOPMENT_BUILD
        return Constants.freePrice
        #else
        return 0
        #endif
    }
    
    var packagePriceString: String {
        #if PRODUCTION_BUILD
        return package?.localizedPriceString ?? "n/a"
        #elseif DEVELOPMENT_BUILD
        return Constants.freePriceString
        #else
        return "FAIL"
        #endif
    }
    
    var packageSupportString: String {
        if packagePrice == 0 {
            return "FREE for a limited time!"
        } else {
            return "All features for a one time payment!"
        }
    }
    
    var packageBuyString: String {
        if packagePrice == 0 {
            return "Upgrade FREE"
        } else {
            return String(format: "Upgrade for %@", packagePriceString)
        }
    }
    
    var isCurrentOfferAvailable: Bool {
        #if PRODUCTION_BUILD
        guard let _ = offering else { return false }
        return true
        #elseif DEVELOPMENT_BUILD
        return true
        #endif
    }
    
    func purchase(completionHandler: @escaping (Result<Bool, PurchaseError>) -> Void) {
        #if PRODUCTION_BUILD
        guard let package = package else {
            completionHandler(.failure(.packageNotFound))
            return
        }
        
        Purchases.shared.purchasePackage(package) { (transaction, info, error, userCancelled) in
            DispatchQueue.main.async {
                if let error = error {
                    completionHandler(.failure(.server(error)))
                    return
                }
                
                if userCancelled {
                    completionHandler(.failure(.userCancelled))
                    return
                }
                
                let isActive = info?.entitlements[Constants.entitlementId]?.isActive == true
                guard isActive else {
                    completionHandler(.failure(.invalidPurchase))
                    return
                }
                
                withAnimation {
                    self.isActive = isActive
                }
                completionHandler(.success(isActive))
            }
        }
        #elseif DEVELOPMENT_BUILD
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.isActive = true
            }
            completionHandler(.success(true))
        }
        #endif
    }
    
    func restore(completionHandler: @escaping (Result<Bool, PurchaseError>) -> Void) {
        #if PRODUCTION_BUILD
        Purchases.shared.restoreTransactions { (info, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completionHandler(.failure(.server(error)))
                    return
                }
                
                let isActive = info?.entitlements[Constants.entitlementId]?.isActive == true
                guard isActive else {
                    completionHandler(.failure(.invalidPurchase))
                    return
                }
                
                withAnimation {
                    self.isActive = isActive
                }
                completionHandler(.success(isActive))
            }
        }
        #elseif DEVELOPMENT_BUILD
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.isActive = true
            }
            completionHandler(.success(self.isActive))
        }
        #endif
    }
    
    #if DEVELOPMENT_BUILD
    func resetMockPurchase() {
        withAnimation {
            isActive = false
        }
    }
    #endif
    
}

// MARK: - Purchases Delegate

extension IAPManager: PurchasesDelegate {
    
    func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: Purchases.PurchaserInfo) {
        self.purchaserInfo = purchaserInfo
    }
    
}

// MARK: - Errors

extension IAPManager {
    enum PurchaseError: Error {
        case userCancelled
        case packageNotFound
        case invalidPurchase
        case server(Error)
    }
}

extension IAPManager.PurchaseError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "User Cancelled Purchase"
        case .packageNotFound:
            return "Package Not Found"
        case .invalidPurchase:
            return "Invalid Purchase"
        case .server(let error):
            return error.localizedDescription
        }
    }
    
}

// MARK: - Helpers

extension Purchases.Package: Identifiable {
    public var id: String { self.identifier }
}

