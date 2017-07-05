
import Foundation
import StoreKit

public class PKCompleteTransactionsController: PKTransactionController {

    public var completeTransactions: PKCompleteTransactions?

    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: PKPaymentQueue) -> [SKPaymentTransaction] {

        guard let completeTransactions = completeTransactions else {
            print("PurchaseKit.completeTransactions() should be called once when the app launches.")
            return transactions
        }

        var unhandledTransactions: [SKPaymentTransaction] = []
        var purchases: [PKPurchase] = []

        for transaction in transactions {

            let transactionState = transaction.transactionState

            if transactionState != .purchasing {

                let purchase = PKPurchase(productId: transaction.payment.productIdentifier, quantity: transaction.payment.quantity, transaction: transaction, originalTransaction: transaction.original, needsFinishTransaction: !completeTransactions.atomically)

                purchases.append(purchase)

                print("Finishing transaction for payment \"\(transaction.payment.productIdentifier)\" with state: \(transactionState.debugDescription)")

                if completeTransactions.atomically {
                    paymentQueue.finishTransaction(transaction)
                }
            } else {
                unhandledTransactions.append(transaction)
            }
        }
        if purchases.count > 0 {
            completeTransactions.callback(purchases)
        }

        return unhandledTransactions
    }
}
