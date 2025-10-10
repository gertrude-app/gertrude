import Dependencies
import DependenciesMacros
import Foundation
import LibCore
import LibViews
import StoreKit

@DependencyClient
struct StoreKitClient: Sendable {
  var getProducts: @Sendable () async throws -> [Product]
  var purchase: @Sendable (_ product: Product) async throws -> Product.PurchaseResult
  var verifiedCurrentEntitlements: @Sendable () async throws -> [Transaction]
  var transactionUpdates: @Sendable () async throws -> any AsyncSequence<Transaction, Never>
}

extension StoreKitClient: DependencyKey {
  static var liveValue: StoreKitClient {
    .init(
      getProducts: {
        let productIds = Set(Subscription.ProductId.allCases.map(\.rawValue))
        return try await Product.products(for: productIds)
      },
      purchase: { product in
        try await product.purchase()
      },
      verifiedCurrentEntitlements: {
        var transactions: [Transaction] = []
        for await result in Transaction.currentEntitlements {
          if case .verified(let transaction) = result {
            transactions.append(transaction)
          }
        }
        return transactions
      },
      transactionUpdates: {
        Transaction.updates.compactMap { result in
          if case .verified(let transaction) = result {
            transaction
          } else {
            nil
          }
        }
      }
    )
  }
}

extension DependencyValues {
  var storeKit: StoreKitClient {
    get { self[StoreKitClient.self] }
    set { self[StoreKitClient.self] = newValue }
  }
}
