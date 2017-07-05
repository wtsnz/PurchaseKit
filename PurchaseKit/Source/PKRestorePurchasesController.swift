
import Foundation
import StoreKit

public class PKRestorePurchasesController: PKTransactionController {

    public var restorePurchases: PKRestorePurchases?

    private var restoredPurchases: [PKTransactionResult] = []

    public func processTransaction(_ transaction: SKPaymentTransaction, atomically: Bool, on paymentQueue: PKPaymentQueue) -> PKPurchase? {

        let transactionState = transaction.transactionState

        if transactionState == .restored {

            let transactionProductIdentifier = transaction.payment.productIdentifier
            
            let purchase = PKPurchase(productId: transactionProductIdentifier, quantity: transaction.payment.quantity, transaction: transaction, originalTransaction: transaction.original, needsFinishTransaction: !atomically)
            if atomically {
                paymentQueue.finishTransaction(transaction)
            }
            return purchase
        }
        return nil
    }

    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: PKPaymentQueue) -> [SKPaymentTransaction] {

        guard let restorePurchases = restorePurchases else {
            return transactions
        }

        var unhandledTransactions: [SKPaymentTransaction] = []
        for transaction in transactions {
            if let restoredPurchase = processTransaction(transaction, atomically: restorePurchases.atomically, on: paymentQueue) {
                restoredPurchases.append(.restored(purchase: restoredPurchase))
            } else {
                unhandledTransactions.append(transaction)
            }
        }

        return unhandledTransactions
    }

    public func restoreCompletedTransactionsFailed(withError error: Error) {

        guard let restorePurchases = restorePurchases else {
            print("Callback already called. Returning")
            return
        }
        restoredPurchases.append(.failed(error: SKError(_nsError: error as NSError)))
        restorePurchases.callback(restoredPurchases)

        // Reset state after error received
        restoredPurchases = []
        self.restorePurchases = nil

    }

    public func restoreCompletedTransactionsFinished() {

        guard let restorePurchases = restorePurchases else {
            print("Callback already called. Returning")
            return
        }
        restorePurchases.callback(restoredPurchases)

        // Reset state after error transactions finished
        restoredPurchases = []
        self.restorePurchases = nil
    }
}
