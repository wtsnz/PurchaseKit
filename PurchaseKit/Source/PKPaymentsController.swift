
import Foundation
import StoreKit

public class PKPaymentsController: PKTransactionController {

    private var payments: [PKPayment] = []

    private func findPaymentIndex(withProductIdentifier identifier: String) -> Int? {
        for payment in payments where payment.product.productIdentifier == identifier {
            return payments.index(of: payment)
        }
        return nil
    }

    public func hasPayment(_ payment: PKPayment) -> Bool {
        return findPaymentIndex(withProductIdentifier: payment.product.productIdentifier) != nil
    }

    public func append(_ payment: PKPayment) {
        payments.append(payment)
    }

    public func processTransaction(_ transaction: SKPaymentTransaction, on paymentQueue: PKPaymentQueue) -> Bool {

        let transactionProductIdentifier = transaction.payment.productIdentifier

        guard let paymentIndex = findPaymentIndex(withProductIdentifier: transactionProductIdentifier) else {

            return false
        }
        let payment = payments[paymentIndex]

        let transactionState = transaction.transactionState

        if transactionState == .purchased {
            
            let purchase = PKPurchaseDetails(productId: transactionProductIdentifier, quantity: transaction.payment.quantity, product: payment.product, transaction: transaction, needsFinishTransaction: !payment.atomically)
            
            payment.callback(.purchased(purchase: purchase))

            if payment.atomically {
                paymentQueue.finishTransaction(transaction)
            }
            payments.remove(at: paymentIndex)
            return true
        }
        if transactionState == .failed {

            payment.callback(.failed(error: transactionError(for: transaction.error as NSError?)))

            paymentQueue.finishTransaction(transaction)
            payments.remove(at: paymentIndex)
            return true
        }

        if transactionState == .restored {
            print("Unexpected restored transaction for payment \(transactionProductIdentifier)")
        }
        return false
    }

    public func transactionError(for error: NSError?) -> SKError {
        let message = "Unknown error"
        let altError = NSError(domain: SKErrorDomain, code: SKError.unknown.rawValue, userInfo: [ NSLocalizedDescriptionKey: message ])
        let nsError = error ?? altError
        return SKError(_nsError: nsError)
    }

    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: PKPaymentQueue) -> [SKPaymentTransaction] {

        return transactions.filter { !processTransaction($0, on: paymentQueue) }
    }
}
