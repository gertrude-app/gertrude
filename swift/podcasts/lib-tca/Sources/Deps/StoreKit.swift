import Dependencies
import DependenciesMacros
import Foundation
import LibCore
import LibViews
import StoreKit
import Synchronization

@DependencyClient
struct StoreKitClient: Sendable {
  var purchaseSubscription: @Sendable () async throws -> PurchaseResult
  var finishTransaction: @Sendable (_ id: Transaction.ID) async -> Void
  var verifiedCurrentEntitlements: @Sendable () async throws -> [TransactionData]
  var transactionUpdates: @Sendable () async throws -> any AsyncSequence<TransactionData, Never>
}

enum PurchaseResult {
  case success(TransactionData)
  case unverified(TransactionData, String)
  case userCancelled
  case pending
  case unknown
}

struct TransactionData: Equatable, Sendable {
  var id: Transaction.ID
  var productID: String
  var originalID: Transaction.ID
  var purchaseDate: Date
  var expirationDate: Date?
  var revocationDate: Date?
}

extension Transaction {
  var data: TransactionData {
    .init(
      id: self.id,
      productID: self.productID,
      originalID: self.originalID,
      purchaseDate: self.purchaseDate,
      expirationDate: self.expirationDate,
      revocationDate: self.revocationDate
    )
  }
}

extension StoreKitClient {
  enum Error: Swift.Error {
    case productNotFound
  }
}

extension StoreKitClient: DependencyKey {
  static var liveValue: StoreKitClient {
    .init(
      purchaseSubscription: {
        let productIds = Set(Subscription.ProductId.allCases.map(\.rawValue))
        let products = try await Product.products(for: productIds)
        guard let product = products.first else {
          log(.unexpected("c8f3e1b4"), "No products found")
          throw Error.productNotFound
        }
        let productPurchaseResult = try await product.purchase()
        switch productPurchaseResult {
        case .success(let verificationResult):
          switch verificationResult {
          case .verified(let transaction):
            Task { dep(\.db).insertEvent(
              kind: .subscription,
              label: "purchase success",
              detail: "\(transaction)"
            ) }
            _transactions.withLock { $0[transaction.id] = transaction }
            return .success(transaction.data)
          case .unverified(let transaction, let error):
            Task { dep(\.db).insertEvent(
              kind: .subscription,
              label: "unverified transaction",
              detail: "\(transaction), error: \(error.localizedDescription)"
            ) }
            return .unverified(transaction.data, error.localizedDescription)
          }
        case .userCancelled:
          return .userCancelled
        case .pending:
          return .pending
        @unknown default:
          return .unknown
        }
      },
      finishTransaction: { id in
        guard let transaction = _transactions.withLock({ $0.removeValue(forKey: id) }) else {
          log(.unexpected("c8f3e1b4"), "No transaction found to finish")
          return
        }
        await transaction.finish()
      },
      verifiedCurrentEntitlements: {
        var transactions: [Transaction] = []
        for await result in Transaction.currentEntitlements {
          if case .verified(let transaction) = result {
            transactions.append(transaction)
          }
        }
        return transactions.map(\.data)
      },
      transactionUpdates: {
        Transaction.updates.compactMap { result in
          Task { dep(\.db).insertEvent(
            kind: .subscription,
            label: "received transaction update",
            detail: "\(result)"
          ) }
          if case .verified(let transaction) = result {
            _transactions.withLock { $0[transaction.id] = transaction }
            return transaction.data
          } else {
            return nil
          }
        }
      }
    )
  }
}

private let _transactions = Mutex<[Transaction.ID: Transaction]>([:])

extension DependencyValues {
  var storekit: StoreKitClient {
    get { self[StoreKitClient.self] }
    set { self[StoreKitClient.self] = newValue }
  }
}
