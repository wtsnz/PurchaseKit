
import Foundation
import StoreKit

public class PKProductsInfoController: NSObject {

    // As we can have multiple inflight queries and purchases, we store them in a dictionary by product id
    private var inflightQueries: [Set<String>: PKInAppProductQueryRequest] = [:]

    public func retrieveProductsInfo(_ productIds: Set<String>, completion: @escaping (PKRetrieveResults) -> Swift.Void) {

        inflightQueries[productIds] = PKInAppProductQueryRequest.startQuery(productIds) { result in
            
            self.inflightQueries[productIds] = nil
            completion(result)
        }
    }
}
