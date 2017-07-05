
import StoreKit

// MARK: - Typealias

// Info for receipt returned by server
public typealias PKReceipt = [String: AnyObject]

// MARK: - Structs

public struct PKCompleteTransactions {
    public let atomically: Bool
    public let callback: ([PKPurchase]) -> Swift.Void
    
    public init(atomically: Bool, callback: @escaping ([PKPurchase]) -> Swift.Void) {
        self.atomically = atomically
        self.callback = callback
    }
}

public struct PKRestorePurchases {
    public let atomically: Bool
    public let applicationUsername: String?
    public let callback: ([PKTransactionResult]) -> Swift.Void
    
    public init(atomically: Bool, applicationUsername: String? = nil, callback: @escaping ([PKTransactionResult]) -> Swift.Void) {
        self.atomically = atomically
        self.applicationUsername = applicationUsername
        self.callback = callback
    }
}

// Products information
public struct PKRetrieveResults {
    public let retrievedProducts: Set<SKProduct>
    public let invalidProductIDs: Set<String>
    public let error: Error?
}

// Restore purchase results
public struct PKRestoreResults {
    public let restoredPurchases: [PKPurchase]
    public let restoreFailedPurchases: [(SKError, String?)]
}

public struct PKReceiptItem {
    // The product identifier of the item that was purchased. This value corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
    public let productId: String
    // The number of items purchased. This value corresponds to the quantity property of the SKPayment object stored in the transaction’s payment property.
    public let quantity: Int
    // The transaction identifier of the item that was purchased. This value corresponds to the transaction’s transactionIdentifier property.
    public let transactionId: String
    // For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier. This value corresponds to the original transaction’s transactionIdentifier property. All receipts in a chain of renewals for an auto-renewable subscription have the same value for this field.
    public let originalTransactionId: String
    // The date and time that the item was purchased. This value corresponds to the transaction’s transactionDate property.
    public let purchaseDate: Date
    // For a transaction that restores a previous transaction, the date of the original transaction. This value corresponds to the original transaction’s transactionDate property. In an auto-renewable subscription receipt, this indicates the beginning of the subscription period, even if the subscription has been renewed.
    public let originalPurchaseDate: Date
    // The primary key for identifying subscription purchases.
    public let webOrderLineItemId: String?
    // The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT. This key is only present for auto-renewable subscription receipts.
    public let subscriptionExpirationDate: Date?
    // For a transaction that was canceled by Apple customer support, the time and date of the cancellation. Treat a canceled receipt the same as if no purchase had ever been made.
    public let cancellationDate: Date?
    
    public let isTrialPeriod: Bool
}

public struct PKPayment: Hashable {
    public let product: SKProduct
    public let quantity: Int
    public let atomically: Bool
    public let applicationUsername: String
    public let callback: (PKTransactionResult) -> Swift.Void
    
    public var hashValue: Int {
        return product.productIdentifier.hashValue
    }
    public static func == (lhs: PKPayment, rhs: PKPayment) -> Bool {
        return lhs.product.productIdentifier == rhs.product.productIdentifier
    }
}

// Purchased or restored product
public struct PKPurchase {
    public let productId: String
    public let quantity: Int
    public let transaction: PKPaymentTransaction
    public let originalTransaction: PKPaymentTransaction?
    public let needsFinishTransaction: Bool
}

public struct PKPurchaseDetails {
    public let productId: String
    public let quantity: Int
    public let product: SKProduct
    public let transaction: PKPaymentTransaction
    public let needsFinishTransaction: Bool
}

// MARK: - Enums

public enum PKTransactionResult {
    case purchased(purchase: PKPurchaseDetails)
    case restored(purchase: PKPurchase)
    case failed(error: SKError)
}

// PKPurchase result
public enum PKPurchaseResult {
    case success(purchase: PKPurchaseDetails)
    case error(error: SKError)
}

// Refresh receipt result
public enum PKRefreshReceiptResult {
    case success(receiptData: Data)
    case error(error: Error)
}

// Verify receipt result
public enum PKVerifyReceiptResult {
    case success(receipt: PKReceipt)
    case error(error: PKReceiptError)
}

// Result for Consumable and NonConsumable
public enum PKVerifyPurchaseResult {
    case purchased(item: PKReceiptItem)
    case notPurchased
}

// Verify subscription result
public enum PKVerifySubscriptionResult {
    case purchased(expiryDate: Date, items: [PKReceiptItem])
    case expired(expiryDate: Date, items: [PKReceiptItem])
    case notPurchased
}

public enum PKSubscriptionType {
    case autoRenewable
    case nonRenewing(validDuration: TimeInterval)
}

// Error when managing receipt
public enum PKReceiptError: Swift.Error {
    // No receipt data
    case noReceiptData
    // No data received
    case noRemoteData
    // Error when encoding HTTP body into JSON
    case requestBodyEncodeError(error: Swift.Error)
    // Error when proceeding request
    case networkError(error: Swift.Error)
    // Error when decoding response
    case jsonDecodeError(string: String?)
    // Receive invalid - bad status returned
    case receiptInvalid(receipt: PKReceipt, status: PKReceiptStatus)
}

// Status code returned by remote server
// see Table 2-1  Status codes
public enum PKReceiptStatus: Int {
    // Not decodable status
    case unknown = -2
    // No status returned
    case none = -1
    // valid statu
    case valid = 0
    // The App Store could not read the JSON object you provided.
    case jsonNotReadable = 21000
    // The data in the receipt-data property was malformed or missing.
    case malformedOrMissingData = 21002
    // The receipt could not be authenticated.
    case receiptCouldNotBeAuthenticated = 21003
    // The shared secret you provided does not match the shared secret on file for your account.
    case secretNotMatching = 21004
    // The receipt server is not currently available.
    case receiptServerUnavailable = 21005
    // This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response.
    case subscriptionExpired = 21006
    //  This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
    case testReceipt = 21007
    // This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.
    case productionEnvironment = 21008
    
    var isValid: Bool { return self == .valid}
}

// Receipt field as defined in : https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1
public enum PKReceiptInfoField: String {
    // Bundle Identifier. This corresponds to the value of CFBundleIdentifier in the Info.plist file.
    case bundle_id
    // The app’s version number.This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in OS X) in the Info.plist.
    case application_version
    // The version of the app that was originally purchased. This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in OS X) in the Info.plist file when the purchase was originally made.
    case original_application_version
    // The date when the app receipt was created.
    case creation_date
    // The date that the app receipt expires. This key is present only for apps purchased through the Volume PKPurchase Program.
    case expiration_date
    
    // The receipt for an in-app purchase.
    case in_app
    
    public enum InApp: String {
        // The number of items purchased. This value corresponds to the quantity property of the SKPayment object stored in the transaction’s payment property.
        case quantity
        // The product identifier of the item that was purchased. This value corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
        case product_id
        // The transaction identifier of the item that was purchased. This value corresponds to the transaction’s transactionIdentifier property.
        case transaction_id
        // For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier. This value corresponds to the original transaction’s transactionIdentifier property. All receipts in a chain of renewals for an auto-renewable subscription have the same value for this field.
        case original_transaction_id
        // The date and time that the item was purchased. This value corresponds to the transaction’s transactionDate property.
        case purchase_date
        // For a transaction that restores a previous transaction, the date of the original transaction. This value corresponds to the original transaction’s transactionDate property. In an auto-renewable subscription receipt, this indicates the beginning of the subscription period, even if the subscription has been renewed.
        case original_purchase_date
        // The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT. This key is only present for auto-renewable subscription receipts.
        case expires_date
        // For a transaction that was canceled by Apple customer support, the time and date of the cancellation. Treat a canceled receipt the same as if no purchase had ever been made.
        case cancellation_date
        #if os(iOS) || os(tvOS)
        // A string that the App Store uses to uniquely identify the application that created the transaction. If your server supports multiple applications, you can use this value to differentiate between them. Apps are assigned an identifier only in the production environment, so this key is not present for receipts created in the test environment. This field is not present for Mac apps. See also Bundle Identifier.
        case app_item_id
        #endif
        // An arbitrary number that uniquely identifies a revision of your application. This key is not present for receipts created in the test environment.
        case version_external_identifier
        // The primary key for identifying subscription purchases.
        case web_order_line_item_id
    }
}

#if os(OSX)
    public enum PKReceiptExitCode: Int32 {
        // If validation fails in OS X, call exit with a status of 173. This exit status notifies the system that your application has determined that its receipt is invalid. At this point, the system attempts to obtain a valid receipt and may prompt for the user’s iTunes credentials
        case notValid = 173
    }
#endif

// MARK: - Protocols

public protocol PKTransactionController {
    
    /**
     * - param transactions: transactions to process
     * - param paymentQueue: payment queue for finishing transactions
     * - return: array of unhandled transactions
     */
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: PKPaymentQueue) -> [SKPaymentTransaction]
}

public protocol PKPaymentQueue: class {
    
    func add(_ observer: SKPaymentTransactionObserver)
    func remove(_ observer: SKPaymentTransactionObserver)
    
    func add(_ payment: SKPayment)
    
    func restoreCompletedTransactions(withApplicationUsername username: String?)
    
    func finishTransaction(_ transaction: SKPaymentTransaction)
}

//Conform to this protocol to provide custom receipt validator
public protocol PKReceiptValidator {
    func validate(receipt: String, password autoRenewPassword: String?, completion: @escaping (PKVerifyReceiptResult) -> Swift.Void)
}

// PKPayment transaction
public protocol PKPaymentTransaction {
    var transactionState: SKPaymentTransactionState { get }
    var transactionIdentifier: String? { get }
}


// MARK: - Extensions

public extension SKProduct {

    public var localizedPrice: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = self.priceLocale
        numberFormatter.numberStyle = .currency
        return numberFormatter.string(from: self.price)
    }
}

// MARK: - missing SKMutablePayment init with product on OSX
#if os(OSX)
    extension SKMutablePayment {
        convenience init(product: SKProduct) {
            self.init()
            self.productIdentifier = product.productIdentifier
        }
    }
#endif

public extension Date {
    
    public init?(millisecondsSince1970: String) {
        guard let millisecondsNumber = Double(millisecondsSince1970) else {
            return nil
        }
        self = Date(timeIntervalSince1970: millisecondsNumber / 1000)
    }
}

extension SKPaymentQueue: PKPaymentQueue { }

extension SKPaymentTransaction {
    
    open override var debugDescription: String {
        let transactionId = transactionIdentifier ?? "null"
        return "productId: \(payment.productIdentifier), transactionId: \(transactionId), state: \(transactionState), date: \(String(describing: transactionDate))"
    }
}

extension SKPaymentTransactionState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .purchasing: return "purchasing"
        case .purchased: return "purchased"
        case .failed: return "failed"
        case .restored: return "restored"
        case .deferred: return "deferred"
        }
    }
}

public extension PKReceiptItem {
    
    public init?(receiptInfo: PKReceipt) {
        guard
            let productId = receiptInfo["product_id"] as? String,
            let quantityString = receiptInfo["quantity"] as? String,
            let quantity = Int(quantityString),
            let transactionId = receiptInfo["transaction_id"] as? String,
            let originalTransactionId = receiptInfo["original_transaction_id"] as? String,
            let purchaseDate = PKReceiptItem.parseDate(from: receiptInfo, key: "purchase_date_ms"),
            let originalPurchaseDate = PKReceiptItem.parseDate(from: receiptInfo, key: "original_purchase_date_ms")
            else {
                print("could not parse receipt item: \(receiptInfo). Skipping...")
                return nil
        }
        self.productId = productId
        self.quantity = quantity
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.webOrderLineItemId = receiptInfo["web_order_line_item_id"] as? String
        self.subscriptionExpirationDate = PKReceiptItem.parseDate(from: receiptInfo, key: "expires_date_ms")
        self.cancellationDate = PKReceiptItem.parseDate(from: receiptInfo, key: "cancellation_date_ms")
        if let isTrialPeriod = receiptInfo["is_trial_period"] as? String {
            self.isTrialPeriod = Bool(isTrialPeriod) ?? false
        } else {
            self.isTrialPeriod = false
        }
    }
    
    private static func parseDate(from receiptInfo: PKReceipt, key: String) -> Date? {
        
        guard
            let requestDateString = receiptInfo[key] as? String,
            let requestDateMs = Double(requestDateString) else {
                return nil
        }
        return Date(timeIntervalSince1970: requestDateMs / 1000)
    }
}

// Add PKPaymentTransaction conformance to SKPaymentTransaction
extension SKPaymentTransaction : PKPaymentTransaction { }
