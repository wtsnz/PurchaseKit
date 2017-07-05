
import StoreKit

public class PKInAppProductQueryRequest: NSObject, SKProductsRequestDelegate {

    public typealias PKRequestCallback = (PKRetrieveResults) -> Swift.Void
    private let callback: PKRequestCallback
    private let request: SKProductsRequest
    // http://stackoverflow.com/questions/24011575/what-is-the-difference-between-a-weak-reference-and-an-unowned-reference
    deinit {
        request.delegate = nil
    }
    private init(productIds: Set<String>, callback: @escaping PKRequestCallback) {

        self.callback = callback
        request = SKProductsRequest(productIdentifiers: productIds)
        super.init()
        request.delegate = self
    }

    public class func startQuery(_ productIds: Set<String>, callback: @escaping PKRequestCallback) -> PKInAppProductQueryRequest {
        let request = PKInAppProductQueryRequest(productIds: productIds, callback: callback)
        request.start()
        return request
    }

    public func start() {
        request.start()
    }
    public func cancel() {
        request.cancel()
    }

    // MARK: SKProductsRequestDelegate
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        let retrievedProducts = Set<SKProduct>(response.products)
        let invalidProductIDs = Set<String>(response.invalidProductIdentifiers)
        performCallback(PKRetrieveResults(retrievedProducts: retrievedProducts,
            invalidProductIDs: invalidProductIDs, error: nil))
    }

    public func requestDidFinish(_ request: SKRequest) {}

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        performCallback(PKRetrieveResults(retrievedProducts: Set<SKProduct>(), invalidProductIDs: Set<String>(), error: error))
    }
    
    private func performCallback(_ results: PKRetrieveResults) {
        DispatchQueue.main.async {
            self.callback(results)
        }
    }
}
