
import UIKit
import StoreKit
import PurchaseKit
import NAIManager

enum RegisteredPurchase: String {

    case purchase1
    case purchase2
    case nonConsumablePurchase
    case consumablePurchase
    case autoRenewablePurchase
    case nonRenewingPurchase
}

class ViewController: UIViewController {

    let appBundleId = "cn.meniny.PurchaseKit.iOS"

    let purchase1Suffix = RegisteredPurchase.purchase1
    let purchase2Suffix = RegisteredPurchase.autoRenewablePurchase

    // MARK: actions
    @IBAction func getInfo1() {
        getInfo(purchase1Suffix)
    }
    @IBAction func purchase1() {
        purchase(purchase1Suffix)
    }
    @IBAction func verifyPurchase1() {
        verifyPurchase(purchase1Suffix)
    }
    @IBAction func getInfo2() {
        getInfo(purchase2Suffix)
    }
    @IBAction func purchase2() {
        purchase(purchase2Suffix)
    }
    @IBAction func verifyPurchase2() {
        verifyPurchase(purchase2Suffix)
    }
    
    func getInfo(_ purchase: RegisteredPurchase) {

        NAIManager.operationStarted()
        PurchaseKit.retrieveProductsInfo([appBundleId + "." + purchase.rawValue]) { result in
            NAIManager.operationFinished()

            self.showAlert(self.alertForProductRetrievalInfo(result))
        }
    }

    func purchase(_ purchase: RegisteredPurchase) {

        NAIManager.operationStarted()
        PurchaseKit.purchaseProduct(appBundleId + "." + purchase.rawValue, atomically: true) { result in
            NAIManager.operationFinished()

            if case .success(let purchase) = result {
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    PurchaseKit.finishTransaction(purchase.transaction)
                }
            }
            if let alert = self.alertForPurchaseResult(result) {
                self.showAlert(alert)
            }
        }
    }

    @IBAction func restorePurchases() {

        NAIManager.operationStarted()
        PurchaseKit.restorePurchases(atomically: true) { results in
            NAIManager.operationFinished()

            for purchase in results.restoredPurchases where purchase.needsFinishTransaction {
                // Deliver content from server, then:
                PurchaseKit.finishTransaction(purchase.transaction)
            }
            self.showAlert(self.alertForRestorePurchases(results))
        }
    }

    @IBAction func verifyReceipt() {

        NAIManager.operationStarted()
        verifyReceipt { result in
            NAIManager.operationFinished()
            self.showAlert(self.alertForVerifyReceipt(result))
        }
    }
    
    func verifyReceipt(completion: @escaping (PKVerifyReceiptResult) -> Void) {
        
        let appleValidator = PKAppleReceiptValidator(service: .production)
        let password = "your-shared-secret"
        PurchaseKit.verifyReceipt(using: appleValidator, password: password, completion: completion)
    }

    func verifyPurchase(_ purchase: RegisteredPurchase) {

        NAIManager.operationStarted()
        verifyReceipt { result in
            NAIManager.operationFinished()

            switch result {
            case .success(let receipt):

                let productId = self.appBundleId + "." + purchase.rawValue

                switch purchase {
                case .autoRenewablePurchase:
                    let purchaseResult = PurchaseKit.verifySubscription(
                        type: .autoRenewable,
                        productId: productId,
                        inReceipt: receipt,
                        validUntil: Date()
                    )
                    self.showAlert(self.alertForVerifySubscription(purchaseResult))
                case .nonRenewingPurchase:
                    let purchaseResult = PurchaseKit.verifySubscription(
                        type: .nonRenewing(validDuration: 60),
                        productId: productId,
                        inReceipt: receipt,
                        validUntil: Date()
                    )
                    self.showAlert(self.alertForVerifySubscription(purchaseResult))
                default:
                    let purchaseResult = PurchaseKit.verifyPurchase(
                        productId: productId,
                        inReceipt: receipt
                    )
                    self.showAlert(self.alertForVerifyPurchase(purchaseResult))
                }

            case .error:
                self.showAlert(self.alertForVerifyReceipt(result))
            }
        }
    }

#if os(iOS)
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
#endif
}

// MARK: User facing alerts
extension ViewController {

    func alertWithTitle(_ title: String, message: String) -> UIAlertController {

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        return alert
    }

    func showAlert(_ alert: UIAlertController) {
        guard self.presentedViewController != nil else {
            self.present(alert, animated: true, completion: nil)
            return
        }
    }

    func alertForProductRetrievalInfo(_ result: PKRetrieveResults) -> UIAlertController {

        if let product = result.retrievedProducts.first {
            let priceString = product.localizedPrice!
            return alertWithTitle(product.localizedTitle, message: "\(product.localizedDescription) - \(priceString)")
        } else if let invalidProductId = result.invalidProductIDs.first {
            return alertWithTitle("Could not retrieve product info", message: "Invalid product identifier: \(invalidProductId)")
        } else {
            let errorString = result.error?.localizedDescription ?? "Unknown error. Please contact support"
            return alertWithTitle("Could not retrieve product info", message: errorString)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func alertForPurchaseResult(_ result: PKPurchaseResult) -> UIAlertController? {
        switch result {
        case .success(let purchase):
            print("Purchase Success: \(purchase.productId)")
            return alertWithTitle("Thank You", message: "Purchase completed")
        case .error(let error):
            print("Purchase Failed: \(error)")
            switch error.code {
            case .unknown: return alertWithTitle("Purchase failed", message: "Unknown error. Please contact support")
            case .clientInvalid: // client is not allowed to issue the request, etc.
                return alertWithTitle("Purchase failed", message: "Not allowed to make the payment")
            case .paymentCancelled: // user cancelled the request, etc.
                return nil
            case .paymentInvalid: // purchase identifier was invalid, etc.
                return alertWithTitle("Purchase failed", message: "The purchase identifier was invalid")
            case .paymentNotAllowed: // this device is not allowed to make the payment
                return alertWithTitle("Purchase failed", message: "The device is not allowed to make the payment")
            case .storeProductNotAvailable: // Product is not available in the current storefront
                return alertWithTitle("Purchase failed", message: "The product is not available in the current storefront")
            case .cloudServicePermissionDenied: // user has not allowed access to cloud service information
                return alertWithTitle("Purchase failed", message: "Access to cloud service information is not allowed")
            case .cloudServiceNetworkConnectionFailed: // the device could not connect to the nework
                return alertWithTitle("Purchase failed", message: "Could not connect to the network")
            case .cloudServiceRevoked: // user has revoked permission to use this cloud service
                return alertWithTitle("Purchase failed", message: "Cloud service was revoked")
            }
        }
    }

    func alertForRestorePurchases(_ results: PKRestoreResults) -> UIAlertController {

        if results.restoreFailedPurchases.count > 0 {
            print("Restore Failed: \(results.restoreFailedPurchases)")
            return alertWithTitle("Restore failed", message: "Unknown error. Please contact support")
        } else if results.restoredPurchases.count > 0 {
            print("Restore Success: \(results.restoredPurchases)")
            return alertWithTitle("Purchases Restored", message: "All purchases have been restored")
        } else {
            print("Nothing to Restore")
            return alertWithTitle("Nothing to restore", message: "No previous purchases were found")
        }
    }

    func alertForVerifyReceipt(_ result: PKVerifyReceiptResult) -> UIAlertController {

        switch result {
        case .success(let receipt):
            print("Verify receipt Success: \(receipt)")
            return alertWithTitle("Receipt verified", message: "Receipt verified remotely")
        case .error(let error):
            print("Verify receipt Failed: \(error)")
            switch error {
            case .noReceiptData:
                return alertWithTitle("Receipt verification", message: "No receipt data. Try again.")
            case .networkError(let error):
                return alertWithTitle("Receipt verification", message: "Network error while verifying receipt: \(error)")
            default:
                return alertWithTitle("Receipt verification", message: "Receipt verification failed: \(error)")
            }
        }
    }

    func alertForVerifySubscription(_ result: PKVerifySubscriptionResult) -> UIAlertController {

        switch result {
        case .purchased(let expiryDate):
            print("Product is valid until \(expiryDate)")
            return alertWithTitle("Product is purchased", message: "Product is valid until \(expiryDate)")
        case .expired(let expiryDate):
            print("Product is expired since \(expiryDate)")
            return alertWithTitle("Product expired", message: "Product is expired since \(expiryDate)")
        case .notPurchased:
            print("This product has never been purchased")
            return alertWithTitle("Not purchased", message: "This product has never been purchased")
        }
    }

    func alertForVerifyPurchase(_ result: PKVerifyPurchaseResult) -> UIAlertController {

        switch result {
        case .purchased:
            print("Product is purchased")
            return alertWithTitle("Product is purchased", message: "Product will not expire")
        case .notPurchased:
            print("This product has never been purchased")
            return alertWithTitle("Not purchased", message: "This product has never been purchased")
        }
    }
}
