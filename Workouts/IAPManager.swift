//
//  IAPManager.swift
//  Workouts
//
//  Created by Axel Rivera on 3/28/21.
//

import SwiftUI
import StoreKit

typealias Transaction = StoreKit.Transaction

class IAPManager: ObservableObject {
    enum Constants {
        static let proIdentifier = "me.axelrivera.Workouts.pro"
    }
    
    @Published private(set) var pro: Product?
    @Published var isActive: Bool = false
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        updateListenerTask = listenForTransactions()
    }
    
    func reload() {
        Task {
            await requestProducts()
            await refreshPurchase()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    @MainActor
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: [Constants.proIdentifier])
            
            if let pro = storeProducts.first {
                self.pro = pro
            } else {
                throw PurchaseError.missingProduct
            }
        } catch {
            Log.debug("product error: \(error.localizedDescription)")
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions which didn't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    //Deliver content to the user.
                    await self.updatePurchase(transaction)

                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a receipt it can read but it failed verification. Don't deliver content to the user.
                    Log.debug("transaction failed verification: \(error.localizedDescription)")
                }
            }
        }
    }
    
}

// MARK: - Methods

extension IAPManager {
    
    var isFreeUser: Bool {
        !isActive
    }
    
    var packagePrice: Double {
        if let pro = pro {
            return NSDecimalNumber(decimal: pro.price).doubleValue
        } else {
            return Double.nan
        }
    }
    
    var packagePriceString: String {
        pro?.displayPrice ?? "n/a"
    }
    
    var packageSupportString: String {
        if packagePrice == 0 {
            return NSLocalizedString("FREE for a limited time!", comment: "Text")
        } else {
            return NSLocalizedString("All features for a one time payment!", comment: "Text")
        }
    }
    
    var packageBuyString: String {
        if packagePrice == 0 {
            return NSLocalizedString("Upgrade FREE", comment: "Action")
        } else {
            let string = NSLocalizedString( "Upgrade for %@", comment: "Action [amount]")
            return String(format: string, packagePriceString)
        }
    }
    
    func purchase(source: AnalyticsManager.PaywallSource, completionHandler: @escaping (Result<Bool, PurchaseError>) -> Void) {
        guard let product = pro else {
            completionHandler(.failure(PurchaseError.missingProduct))
            return
        }
        
        Task {
            do {
                try await purchase(product)
                
                AnalyticsManager.shared.purchase(
                    source: source.rawValue,
                    price: NSDecimalNumber(decimal: product.price).doubleValue,
                    displayPrice: product.displayPrice,
                    identifier: product.id
                )
                
                DispatchQueue.main.async {
                    completionHandler(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    let localError = error as? PurchaseError ?? .server(error)
                    completionHandler(.failure(localError))
                }
            }
        }
    }
    
    @MainActor
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            //Deliver content to the user.
            await updatePurchase(transaction)

            //Always finish a transaction.
            await transaction.finish()
        case .pending:
            break
        case .userCancelled:
            throw PurchaseError.userCancelled
        default:
            throw PurchaseError.invalidPurchase
        }
    }
    
    @MainActor
    func refreshPurchase() async {
        Task {
            isActive = (try? await isPurchased(Constants.proIdentifier)) ?? false
        }
    }
    
    func isPurchased(_ productIdentifier: String) async throws -> Bool {
        //Get the most recent transaction receipt for this `productIdentifier`.
        guard let result = await Transaction.latest(for: productIdentifier) else {
            //If there is no latest transaction, the product has not been purchased.
            return false
        }

        let transaction = try checkVerified(result)

        //Ignore revoked transactions, they're no longer purchased.

        //For subscriptions, a user can upgrade in the middle of their subscription period. The lower service
        //tier will then have the `isUpgraded` flag set and there will be a new transaction for the higher service
        //tier. Ignore the lower service tier transactions which have been upgraded.
        return transaction.revocationDate == nil && !transaction.isUpgraded
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check if the transaction passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit has parsed the JWS but failed verification. Don't deliver content to the user.
            throw PurchaseError.invalidPurchase
        case .verified(let safe):
            //If the transaction is verified, unwrap and return it.
            return safe
        }
    }
    
    @MainActor
    func updatePurchase(_ transaction: Transaction) async {
        withAnimation {
            if transaction.revocationDate == nil {
                isActive = true
            } else {
                isActive = false
            }
        }
    }
    
    func restore(completionHandler: @escaping (Result<Bool, PurchaseError>) -> Void) {
        Task {
            do {
                try await AppStore.sync()
                let isActive = try await isPurchased(Constants.proIdentifier)
                
                guard isActive else {
                    throw PurchaseError.invalidPurchase
                }
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.isActive = isActive
                    }
                    completionHandler(.success(isActive))
                }
            } catch PurchaseError.invalidPurchase {
                DispatchQueue.main.async {
                    completionHandler(.failure(.invalidPurchase))
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(.failure(.server(error)))
                }
            }
        }
    }
    
}

// MARK: - Errors

extension IAPManager {
    enum PurchaseError: Error {
        case missingProduct
        case userCancelled
        case packageNotFound
        case invalidPurchase
        case server(Error)
    }
}

extension IAPManager.PurchaseError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .missingProduct:
            return NSLocalizedString("Missing Product", comment: "Error")
        case .userCancelled:
            return NSLocalizedString("User Cancelled Purchase", comment: "Error")
        case .packageNotFound:
            return NSLocalizedString("Package Not Found", comment: "Error")
        case .invalidPurchase:
            return NSLocalizedString("Invalid Purchase", comment: "Error")
        case .server(let error):
            return error.localizedDescription
        }
    }
    
}

// MARK: - Previews

class IAPManagerPreview: IAPManager {
    
    static func manager(isActive: Bool) -> IAPManager {
        let manager = IAPManagerPreview()
        manager.isActive = isActive
        return manager as IAPManager
    }
    
}

