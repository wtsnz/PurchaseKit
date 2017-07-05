
import Foundation
import StoreKit

public class PKPaymentQueueController: NSObject, SKPaymentTransactionObserver {

    private let paymentsController: PKPaymentsController

    private let restorePurchasesController: PKRestorePurchasesController

    private let completeTransactionsController: PKCompleteTransactionsController

    unowned let paymentQueue: PKPaymentQueue

    deinit {
        paymentQueue.remove(self)
    }

    init(paymentQueue: PKPaymentQueue = SKPaymentQueue.default(),
         paymentsController: PKPaymentsController = PKPaymentsController(),
         restorePurchasesController: PKRestorePurchasesController = PKRestorePurchasesController(),
         completeTransactionsController: PKCompleteTransactionsController = PKCompleteTransactionsController()) {

        self.paymentQueue = paymentQueue
        self.paymentsController = paymentsController
        self.restorePurchasesController = restorePurchasesController
        self.completeTransactionsController = completeTransactionsController
        super.init()
        paymentQueue.add(self)
    }

    func startPayment(_ payment: PKPayment) {

        let skPayment = SKMutablePayment(product: payment.product)
        skPayment.applicationUsername = payment.applicationUsername
        skPayment.quantity = payment.quantity
        paymentQueue.add(skPayment)

        paymentsController.append(payment)
    }

    func restorePurchases(_ restorePurchases: PKRestorePurchases) {

        if restorePurchasesController.restorePurchases != nil {
            return
        }

        paymentQueue.restoreCompletedTransactions(withApplicationUsername: restorePurchases.applicationUsername)

        restorePurchasesController.restorePurchases = restorePurchases
    }

    func registerTransactions(_ completeTransactions: PKCompleteTransactions) {

        guard completeTransactionsController.completeTransactions == nil else {
            print("PurchaseKit.completeTransactions() should only be called once when the app launches. Ignoring this call")
            return
        }

        completeTransactionsController.completeTransactions = completeTransactions
    }

    func finishTransaction(_ transaction: PKPaymentTransaction) {
        guard let skTransaction = transaction as? SKPaymentTransaction else {
            print("Object is not a SKPaymentTransaction: \(transaction)")
            return
        }
        paymentQueue.finishTransaction(skTransaction)
    }

    // MARK: SKPaymentTransactionObserver
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

        /*
         * Some notes about how requests are processed by SKPaymentQueue:
         *
         * SKPaymentQueue is used to queue payments or restore purchases requests.
         * Payments are processed serially and in-order and require user interaction.
         * Restore purchases requests don't require user interaction and can jump ahead of the queue.
         * SKPaymentQueue rejects multiple restore purchases calls.
         * Having one payment queue observer for each request causes extra processing
         * Failed transactions only ever belong to queued payment requests.
         * restoreCompletedTransactionsFailedWithError is always called when a restore purchases request fails.
         * paymentQueueRestoreCompletedTransactionsFinished is always called following 0 or more update transactions when a restore purchases request succeeds.
         * A complete transactions handler is require to catch any transactions that are updated when the app is not running.
         * Registering a complete transactions handler when the app launches ensures that any pending transactions can be cleared.
         * If a complete transactions handler is missing, pending transactions can be mis-attributed to any new incoming payments or restore purchases.
         *
         * The order in which transaction updates are processed is:
         * 1. payments (transactionState: .purchased and .failed for matching product identifiers)
         * 2. restore purchases (transactionState: .restored, or restoreCompletedTransactionsFailedWithError, or paymentQueueRestoreCompletedTransactionsFinished)
         * 3. complete transactions (transactionState: .purchased, .failed, .restored, .deferred)
         * Any transactions where state == .purchasing are ignored.
         */
        var unhandledTransactions = paymentsController.processTransactions(transactions, on: paymentQueue)

        unhandledTransactions = restorePurchasesController.processTransactions(unhandledTransactions, on: paymentQueue)

        unhandledTransactions = completeTransactionsController.processTransactions(unhandledTransactions, on: paymentQueue)

        unhandledTransactions = unhandledTransactions.filter { $0.transactionState != .purchasing }
        if unhandledTransactions.count > 0 {
            let strings = unhandledTransactions.map { $0.debugDescription }.joined(separator: "\n")
            print("unhandledTransactions:\n\(strings)")
        }
    }

    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {

    }

    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {

        restorePurchasesController.restoreCompletedTransactionsFailed(withError: error)
    }

    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {

        restorePurchasesController.restoreCompletedTransactionsFinished()
    }

    public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {

    }

}
