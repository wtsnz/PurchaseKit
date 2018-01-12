
<p align="center">
  <img src="https://ooo.0o0.ooo/2017/07/22/5972d2dfdbe6e.png" alt="PurchaseKit">
  <br/><br/>
  <a href="https://cocoapods.org/pods/PurchaseKit">
  <img alt="Version" src="https://img.shields.io/badge/version-1.1.0-brightgreen.svg">
  <img alt="Author" src="https://img.shields.io/badge/author-Meniny-blue.svg">
  <img alt="Build Passing" src="https://img.shields.io/badge/build-passing-brightgreen.svg">
  <img alt="Swift" src="https://img.shields.io/badge/swift-3.0%2B-orange.svg">
  <br/>
  <img alt="Platforms" src="https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20tvOS-lightgrey.svg">
  <img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <br/>
  <img alt="Cocoapods" src="https://img.shields.io/badge/cocoapods-compatible-brightgreen.svg">
  <img alt="Carthage" src="https://img.shields.io/badge/carthage-working%20on-red.svg">
  <img alt="SPM" src="https://img.shields.io/badge/swift%20package%20manager-working%20on-red.svg">
  </a>
</p>

***

# Introduction

## What's this?

`PurchaseKit` is an In-App Purchase Framework written in Swift.

## Requirements

* iOS 8.0+
* macOS 10.10+
* tvOS 9.0+
* Xcode 9 with Swift 4

## Installation

#### CocoaPods

```ruby
pod 'PurchaseKit'
```

## Contribution

You are welcome to fork and submit pull requests.

## License

`PurchaseKit` is open-sourced software, licensed under the `MIT` license.

# Usage

### Complete Transactions

Apple recommends to register a transaction observer [as soon as the app starts](https://developer.apple.com/library/ios/technotes/tn2387/_index.html):
> Adding your app's observer at launch ensures that it will persist during all launches of your app, thus allowing your app to receive all the payment queue notifications.

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

	PurchaseKit.completeTransactions(atomically: true) { purchases in

	    for purchase in purchases {

	        if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {

               if purchase.needsFinishTransaction {
                   // Deliver content from server, then:
                   PurchaseKit.finishTransaction(purchase.transaction)
               }
               print("purchased: \(purchase)")
	        }
	    }
	}
 	return true
}
```

## Purchases

### Retrieve products info

```swift
PurchaseKit.retrieveProductsInfo(["cn.meniny.PurchaseKit.Purchase1"]) { result in
    if let product = result.retrievedProducts.first {
        let priceString = product.localizedPrice!
        print("Product: \(product.localizedDescription), price: \(priceString)")
    }
    else if let invalidProductId = result.invalidProductIDs.first {
        return alertWithTitle("Could not retrieve product info", message: "Invalid product identifier: \(invalidProductId)")
    }
    else {
	     print("Error: \(result.error)")
    }
}
```

### Purchase a product

```swift
PurchaseKit.purchaseProduct("cn.meniny.PurchaseKit.Purchase1", quantity: 1, atomically: true) { result in
    switch result {
    case .success(let purchase):
        print("Purchase Success: \(purchase.productId)")
    case .error(let error):
        switch error.code {
        case .unknown: print("Unknown error. Please contact support")
        case .clientInvalid: print("Not allowed to make the payment")
        case .paymentCancelled: break
        case .paymentInvalid: print("The purchase identifier was invalid")
        case .paymentNotAllowed: print("The device is not allowed to make the payment")
        case .storeProductNotAvailable: print("The product is not available in the current storefront")
        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
        }
    }
}
```

```swift
PurchaseKit.purchaseProduct("cn.meniny.PurchaseKit.Purchase1", quantity: 1, atomically: false) { result in
    switch result {
    case .success(let product):
        // fetch content from your server, then:
        if product.needsFinishTransaction {
            PurchaseKit.finishTransaction(product.transaction)
        }
        print("Purchase Success: \(product.productId)")
    case .error(let error):
        switch error.code {
        case .unknown: print("Unknown error. Please contact support")
        case .clientInvalid: print("Not allowed to make the payment")
        case .paymentCancelled: break
        case .paymentInvalid: print("The purchase identifier was invalid")
        case .paymentNotAllowed: print("The device is not allowed to make the payment")
        case .storeProductNotAvailable: print("The product is not available in the current storefront")
        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
        }
    }
}
```

```swift
PurchaseKit.retrieveProductsInfo(["cn.meniny.PurchaseKit.Purchase1"]) { result in
    if let product = result.retrievedProducts.first {
        PurchaseKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
            // handle result (same as above)
        }
    }
}
```

### Restore previous purchases

```swift
PurchaseKit.restorePurchases(atomically: true) { results in
    if results.restoreFailedPurchases.count > 0 {
        print("Restore Failed: \(results.restoreFailedPurchases)")
    }
    else if results.restoredPurchases.count > 0 {
        print("Restore Success: \(results.restoredPurchases)")
    }
    else {
        print("Nothing to Restore")
    }
}
```

```swift
PurchaseKit.restorePurchases(atomically: false) { results in
    if results.restoreFailedPurchases.count > 0 {
        print("Restore Failed: \(results.restoreFailedPurchases)")
    }
    else if results.restoredPurchases.count > 0 {
        for purchase in results.restoredPurchases {
            // fetch content from your server, then:
            if purchase.needsFinishTransaction {
                PurchaseKit.finishTransaction(purchase.transaction)
            }
        }
        print("Restore Success: \(results.restoredPurchases)")
    }
    else {
        print("Nothing to Restore")
    }
}
```

## Receipt verification

### Retrieve local receipt

```swift
let receiptData = PurchaseKit.localReceiptData
let receiptString = receiptData.base64EncodedString(options: [])
// do your receipt validation here
```

### Verify Receipt

```swift
let appleValidator = PKAppleReceiptValidator(service: .production)
PurchaseKit.verifyReceipt(using: appleValidator, password: "your-shared-secret", forceRefresh: false) { result in
    switch result {
    case .success(let receipt):
        print("Verify receipt Success: \(receipt)")
    case .error(let error):
        print("Verify receipt Failed: \(error)")
	}
}
```

## Verifying purchases and subscriptions

### Verify Purchase

```swift
let appleValidator = PKAppleReceiptValidator(service: .production)
PurchaseKit.verifyReceipt(using: appleValidator, password: "your-shared-secret") { result in
    switch result {
    case .success(let receipt):
        // Verify the purchase of Consumable or NonConsumable
        let purchaseResult = PurchaseKit.verifyPurchase(
            productId: "cn.meniny.PurchaseKit.Purchase1",
            inReceipt: receipt)

        switch purchaseResult {
        case .purchased(let receiptItem):
            print("Product is purchased: \(receiptItem)")
        case .notPurchased:
            print("The user has never purchased this product")
        }
    case .error(let error):
        print("Receipt verification failed: \(error)")
    }
}
```
### Verify Subscription

```swift
let appleValidator = PKAppleReceiptValidator(service: .production)
PurchaseKit.verifyReceipt(using: appleValidator, password: "your-shared-secret") { result in
    switch result {
    case .success(let receipt):
        // Verify the purchase of a Subscription
        let purchaseResult = PurchaseKit.verifySubscription(
            type: .autoRenewable, // or .nonRenewing (see below)
            productId: "cn.meniny.PurchaseKit.Subscription",
            inReceipt: receipt)

        switch purchaseResult {
        case .purchased(let expiryDate, let receiptItems):
            print("Product is valid until \(expiryDate)")
        case .expired(let expiryDate, let receiptItems):
            print("Product is expired since \(expiryDate)")
        case .notPurchased:
            print("The user has never purchased this product")
        }

    case .error(let error):
        print("Receipt verification failed: \(error)")
    }
}
```

#### Auto-Renewable

```swift
let purchaseResult = PurchaseKit.verifySubscription(
            type: .autoRenewable,
            productId: "cn.meniny.PurchaseKit.Subscription",
            inReceipt: receipt)
```

#### Non-Renewing

```swift
// validDuration: time interval in seconds
let purchaseResult = PurchaseKit.verifySubscription(
            type: .nonRenewing(validDuration: 3600 * 24 * 30),
            productId: "cn.meniny.PurchaseKit.Subscription",
            inReceipt: receipt)
```

#### Purchasing and verifying a subscription

```swift
let productId = "your-product-id"
PurchaseKit.purchaseProduct(productId, atomically: true) { result in

    if case .success(let purchase) = result {
        // Deliver content from server, then:
        if purchase.needsFinishTransaction {
            PurchaseKit.finishTransaction(purchase.transaction)
        }

        let appleValidator = PKAppleReceiptValidator(service: .production)
        PurchaseKit.verifyReceipt(using: appleValidator, password: "your-shared-secret") { result in

            if case .success(let receipt) = result {
                let purchaseResult = PurchaseKit.verifySubscription(
                    type: .autoRenewable,
                    productId: productId,
                    inReceipt: receipt)

                switch purchaseResult {
                case .purchased(let expiryDate, let receiptItems):
                    print("Product is valid until \(expiryDate)")
                case .expired(let expiryDate, let receiptItems):
                    print("Product is expired since \(expiryDate)")
                case .notPurchased:
                    print("This product has never been purchased")
                }

            } else {
                // receipt verification error
            }
        }
    } else {
        // purchase error
    }
}
```
