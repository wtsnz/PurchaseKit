
import UIKit
import PurchaseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {

        completeIAPTransactions()

        return true
    }

    func completeIAPTransactions() {

        PurchaseKit.completeTransactions(atomically: true) { purchases in

            for purchase in purchases {
                // swiftlint:disable:next for_where
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {

                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        PurchaseKit.finishTransaction(purchase.transaction)
                    }
                    print("purchased: \(purchase.productId)")
                }
            }
        }
    }
}
