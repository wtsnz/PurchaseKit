
import Foundation
import StoreKit

// MARK - receipt mangement
internal class PKInAppReceipt {

    /**
     *  Verify the purchase of a Consumable or NonConsumable product in a receipt
     *  - Parameter productId: the product id of the purchase to verify
     *  - Parameter inReceipt: the receipt to use for looking up the purchase
     *  - return: either notPurchased or purchased
     */
    class func verifyPurchase(
        productId: String,
        inReceipt receipt: PKReceipt
    ) -> PKVerifyPurchaseResult {

        // Get receipts info for the product
        let receipts = receipt["receipt"]?["in_app"] as? [PKReceipt]
        let receiptsInfo = filterReceiptsInfo(receipts: receipts, withProductId: productId)
        let nonCancelledReceiptsInfo = receiptsInfo.filter { receipt in receipt["cancellation_date"] == nil }

        let receiptItems = nonCancelledReceiptsInfo.flatMap { PKReceiptItem(receiptInfo: $0) }
        // Verify that at least one receipt has the right product id
        if let firstItem = receiptItems.first {
            return .purchased(item: firstItem)
        }
        return .notPurchased
    }

    /**
     *  Verify the purchase of a subscription (auto-renewable, free or non-renewing) in a receipt. This method extracts all transactions mathing the given productId and sorts them by date in descending order, then compares the first transaction expiry date against the validUntil value.
     *  - parameter type: .autoRenewable or .nonRenewing(duration)
     *  - Parameter productId: the product id of the purchase to verify
     *  - Parameter inReceipt: the receipt to use for looking up the subscription
     *  - Parameter validUntil: date to check against the expiry date of the subscription. If nil, no verification
     *  - Parameter validDuration: the duration of the subscription. Only required for non-renewable subscription.
     *  - return: either NotPurchased or Purchased / Expired with the expiry date found in the receipt
     */
    class func verifySubscription(
        type: PKSubscriptionType,
        productId: String,
        inReceipt receipt: PKReceipt,
        validUntil date: Date = Date()
    ) -> PKVerifySubscriptionResult {

        // The values of the latest_receipt and latest_receipt_info keys are useful when checking whether an auto-renewable subscription is currently active. By providing any transaction receipt for the subscription and checking these values, you can get information about the currently-active subscription period. If the receipt being validated is for the latest renewal, the value for latest_receipt is the same as receipt-data (in the request) and the value for latest_receipt_info is the same as receipt.
        let (receipts, duration) = getReceiptsAndDuration(for: type, inReceipt: receipt)
        let receiptsInfo = filterReceiptsInfo(receipts: receipts, withProductId: productId)
        let nonCancelledReceiptsInfo = receiptsInfo.filter { receipt in receipt["cancellation_date"] == nil }
        if nonCancelledReceiptsInfo.count == 0 {
            return .notPurchased
        }

        let receiptDate = getReceiptRequestDate(inReceipt: receipt) ?? date

        let receiptItems = nonCancelledReceiptsInfo.flatMap { PKReceiptItem(receiptInfo: $0) }

        if nonCancelledReceiptsInfo.count > receiptItems.count {
            print("receipt has \(nonCancelledReceiptsInfo.count) items, but only \(receiptItems.count) were parsed")
        }

        let sortedExpiryDatesAndItems = expiryDatesAndItems(receiptItems: receiptItems, duration: duration).sorted { a, b in
            return a.0 > b.0
        }

        guard let firstExpiryDateItemPair = sortedExpiryDatesAndItems.first else {
            return .notPurchased
        }

        let sortedReceiptItems = sortedExpiryDatesAndItems.map { $0.1 }
        if firstExpiryDateItemPair.0 > receiptDate {
            return .purchased(expiryDate: firstExpiryDateItemPair.0, items: sortedReceiptItems)
        } else {
            return .expired(expiryDate: firstExpiryDateItemPair.0, items: sortedReceiptItems)
        }
    }

    private class func expiryDatesAndItems(receiptItems: [PKReceiptItem], duration: TimeInterval?) -> [(Date, PKReceiptItem)] {

        if let duration = duration {
            return receiptItems.map {
                let expirationDate = Date(timeIntervalSince1970: $0.originalPurchaseDate.timeIntervalSince1970 + duration)
                return (expirationDate, $0)
            }
        } else {
            return receiptItems.flatMap {
                if let expirationDate = $0.subscriptionExpirationDate {
                    return (expirationDate, $0)
                }
                return nil
            }
        }
    }

    private class func getReceiptsAndDuration(for subscriptionType: PKSubscriptionType, inReceipt receipt: PKReceipt) -> ([PKReceipt]?, TimeInterval?) {
        switch subscriptionType {
        case .autoRenewable:
            return (receipt["latest_receipt_info"] as? [PKReceipt], nil)
        case .nonRenewing(let duration):
            return (receipt["receipt"]?["in_app"] as? [PKReceipt], duration)
        }
    }

    private class func getReceiptRequestDate(inReceipt receipt: PKReceipt) -> Date? {

        guard let receiptInfo = receipt["receipt"] as? PKReceipt,
            let requestDateString = receiptInfo["request_date_ms"] as? String else {
            return nil
        }
        return Date(millisecondsSince1970: requestDateString)
    }

    /**
     *  Get all the receipts info for a specific product
     *  - Parameter receipts: the receipts array to grab info from
     *  - Parameter productId: the product id
     */
    private class func filterReceiptsInfo(receipts: [PKReceipt]?, withProductId productId: String) -> [PKReceipt] {

        guard let receipts = receipts else {
            return []
        }

        // Filter receipts with matching product id
        let receiptsMatchingProductId = receipts
            .filter { (receipt) -> Bool in
                let product_id = receipt["product_id"] as? String
                return product_id == productId
            }

        return receiptsMatchingProductId
    }
}

public class PKInAppReceiptRefreshRequest: NSObject, SKRequestDelegate {
    
    public enum PKResultType {
        case success
        case error(e: Error)
    }
    
    public typealias PKRequestCallback = (PKResultType) -> Swift.Void
    public typealias PKReceiptRefresh = (_ receiptProperties: [String : Any]?, _ callback: @escaping PKRequestCallback) -> PKInAppReceiptRefreshRequest
    
    public class func refresh(_ receiptProperties: [String : Any]? = nil, callback: @escaping PKRequestCallback) -> PKInAppReceiptRefreshRequest {
        let request = PKInAppReceiptRefreshRequest(receiptProperties: receiptProperties, callback: callback)
        request.start()
        return request
    }
    
    public let refreshReceiptRequest: SKReceiptRefreshRequest
    public let callback: PKRequestCallback
    
    deinit {
        refreshReceiptRequest.delegate = nil
    }
    
    public init(receiptProperties: [String : Any]? = nil, callback: @escaping PKRequestCallback) {
        self.callback = callback
        self.refreshReceiptRequest = SKReceiptRefreshRequest(receiptProperties: receiptProperties)
        super.init()
        self.refreshReceiptRequest.delegate = self
    }
    
    public func start() {
        self.refreshReceiptRequest.start()
    }
    
    public func requestDidFinish(_ request: SKRequest) {
        /*if let resoreRequest = request as? SKReceiptRefreshRequest {
         let receiptProperties = resoreRequest.receiptProperties ?? [:]
         for (k, v) in receiptProperties {
         print("\(k): \(v)")
         }
         }*/
        performCallback(.success)
    }
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        // XXX could here check domain and error code to return typed exception
        performCallback(.error(e: error))
    }
    private func performCallback(_ result: PKResultType) {
        DispatchQueue.main.async {
            self.callback(result)
        }
    }
}

public class PKInAppReceiptVerificator: NSObject {
    
    public let appStoreReceiptURL: URL?
    public init(appStoreReceiptURL: URL? = Bundle.main.appStoreReceiptURL) {
        self.appStoreReceiptURL = appStoreReceiptURL
    }
    
    public var appStoreReceiptData: Data? {
        guard let receiptDataURL = appStoreReceiptURL,
            let data = try? Data(contentsOf: receiptDataURL) else {
                return nil
        }
        return data
    }
    
    private var receiptRefreshRequest: PKInAppReceiptRefreshRequest?
    
    /**
     *  Verify application receipt. This method does two things:
     *  * If the receipt is missing, refresh it
     *  * If the receipt is available or is refreshed, validate it
     *  - Parameter validator: Validator to check the encrypted receipt and return the receipt in readable format
     *  - Parameter password: Your app’s shared secret (a hexadecimal string). Only used for receipts that contain auto-renewable subscriptions.
     *  - Parameter forceRefresh: If true, refreshes the receipt even if one already exists.
     *  - Parameter refresh: closure to perform receipt refresh (this is made explicit for testability)
     *  - Parameter completion: handler for result
     */
    public func verifyReceipt(using validator: PKReceiptValidator,
                              password: String? = nil,
                              forceRefresh: Bool,
                              refresh: PKInAppReceiptRefreshRequest.PKReceiptRefresh = PKInAppReceiptRefreshRequest.refresh,
                              completion: @escaping (PKVerifyReceiptResult) -> Swift.Void) {
        
        if let receiptData = appStoreReceiptData, forceRefresh == false {
            
            verify(receiptData: receiptData, using: validator, password: password, completion: completion)
        } else {
            
            receiptRefreshRequest = refresh(nil) { result in
                
                self.receiptRefreshRequest = nil
                
                switch result {
                case .success:
                    if let receiptData = self.appStoreReceiptData {
                        self.verify(receiptData: receiptData, using: validator, password: password, completion: completion)
                    } else {
                        completion(.error(error: .noReceiptData))
                    }
                case .error(let e):
                    completion(.error(error: .networkError(error: e)))
                }
            }
        }
    }
    
    /**
     *  - Parameter receiptData: encrypted receipt data
     *  - Parameter validator: Validator to check the encrypted receipt and return the receipt in readable format
     *  - Parameter password: Your app’s shared secret (a hexadecimal string). Only used for receipts that contain auto-renewable subscriptions.
     *  - Parameter completion: handler for result
     */
    private func verify(receiptData: Data, using validator: PKReceiptValidator, password: String? = nil, completion: @escaping (PKVerifyReceiptResult) -> Swift.Void) {
        
        // The base64 encoded receipt data.
        let base64EncodedString = receiptData.base64EncodedString(options: [])
        
        validator.validate(receipt: base64EncodedString, password: password) { result in
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
