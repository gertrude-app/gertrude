import Foundation

public enum Stripe {
  public enum Api {
    public enum Currency: String {
      case USD
    }

    public struct PaymentIntent: Decodable {
      public var id: String
      public var clientSecret: String

      public init(id: String, clientSecret: String) {
        self.id = id
        self.clientSecret = clientSecret
      }
    }

    public struct Refund: Decodable {
      public var id: String

      public init(id: String) {
        self.id = id
      }
    }

    public struct CheckoutSession: Codable {
      public var id: String
      public var url: String?
      public var subscription: String?
      public var clientReferenceId: String?

      public init(id: String, url: String?, subscription: String?, clientReferenceId: String?) {
        self.id = id
        self.url = url
        self.subscription = subscription
        self.clientReferenceId = clientReferenceId
      }
    }

    public struct Subscription: Decodable {
      public enum Status: String, Decodable {
        case incomplete
        case incompleteExpired = "incomplete_expired"
        case trialing
        case active
        case pastDue = "past_due"
        case canceled
        case unpaid
      }

      public struct Items: Decodable {
        public struct Item: Decodable {
          public struct Price: Decodable {
            public let id: String
            public init(id: String) {
              self.id = id
            }
          }

          public let id: String
          public let price: Price
          public init(id: String, price: Price) {
            self.id = id
            self.price = price
          }
        }

        public let data: [Item]
        public init(data: [Item]) {
          self.data = data
        }
      }

      public let id: String
      public let status: Status
      public let customer: String
      public let items: Items

      /// unix epoch timestamp (seconds)
      public let currentPeriodEnd: Int

      public init(
        id: String,
        status: Status,
        customer: String,
        currentPeriodEnd: Int,
        items: [Items.Item] = [],
      ) {
        self.id = id
        self.status = status
        self.customer = customer
        self.currentPeriodEnd = currentPeriodEnd
        self.items = Items(data: items)
      }
    }

    public struct UpdateSubscriptionData: Equatable {
      public enum ProrationBehavior: String {
        case alwaysInvoice = "always_invoice"
        case createProrations = "create_prorations"
        case none
      }

      public enum PaymentBehavior: String {
        case errorIfIncomplete = "error_if_incomplete"
        case allowIncomplete = "allow_incomplete"
      }

      public enum BillingCycleAnchor: String {
        case now
        case unchanged
      }

      public let subscriptionId: String
      public let itemId: String
      public let priceId: String
      public let prorationBehavior: ProrationBehavior
      public let paymentBehavior: PaymentBehavior
      public let billingCycleAnchor: BillingCycleAnchor

      public init(
        subscriptionId: String,
        itemId: String,
        priceId: String,
        prorationBehavior: ProrationBehavior = .alwaysInvoice,
        paymentBehavior: PaymentBehavior = .errorIfIncomplete,
        billingCycleAnchor: BillingCycleAnchor = .now,
      ) {
        self.subscriptionId = subscriptionId
        self.itemId = itemId
        self.priceId = priceId
        self.prorationBehavior = prorationBehavior
        self.paymentBehavior = paymentBehavior
        self.billingCycleAnchor = billingCycleAnchor
      }
    }

    public struct BillingPortalSession: Decodable {
      public let id: String
      public let url: String

      public init(id: String, url: String) {
        self.id = id
        self.url = url
      }
    }

    public struct Error: Swift.Error {
      public let type: String
      public let code: String?
      public let message: String?
      public let docUrl: String?
      public let param: String?

      public init(
        type: String,
        code: String? = nil,
        message: String? = nil,
        docUrl: String? = nil,
        param: String? = nil,
      ) {
        self.type = type
        self.code = code
        self.message = message
        self.docUrl = docUrl
        self.param = param
      }
    }
  }

  public struct CheckoutSessionData: Equatable {
    public struct LineItem: Equatable {
      public let quantity: Int
      public let priceId: String

      public init(quantity: Int, priceId: String) {
        self.quantity = quantity
        self.priceId = priceId
      }
    }

    public enum Mode: String {
      case payment
      case setup
      case subscription
    }

    public enum TrialEndBehavior: String {
      case pause
      case createInvoice = "create_invoice"
    }

    public enum PaymentMethodCollection: String {
      case always
      case ifRequired = "if_required"
    }

    public let successUrl: String
    public let cancelUrl: String
    public let lineItems: [LineItem]
    public let mode: Mode
    public let clientReferenceId: String?
    public let customer: String?
    public let customerEmail: String?
    public let trialPeriodDays: Int?
    public let trialEndBehavior: TrialEndBehavior?
    public let paymentMethodCollection: PaymentMethodCollection?

    public init(
      successUrl: String,
      cancelUrl: String,
      lineItems: [Stripe.CheckoutSessionData.LineItem],
      mode: Stripe.CheckoutSessionData.Mode,
      clientReferenceId: String?,
      customer: String? = nil,
      customerEmail: String?,
      trialPeriodDays: Int?,
      trialEndBehavior: TrialEndBehavior?,
      paymentMethodCollection: PaymentMethodCollection?,
    ) {
      self.successUrl = successUrl
      self.cancelUrl = cancelUrl
      self.lineItems = lineItems
      self.mode = mode
      self.clientReferenceId = clientReferenceId
      self.customer = customer
      self.customerEmail = customerEmail
      self.trialPeriodDays = trialPeriodDays
      self.trialEndBehavior = trialEndBehavior
      self.paymentMethodCollection = paymentMethodCollection
    }
  }
}

extension Stripe.Api.Error: CustomStringConvertible {
  public var description: String {
    "Stripe.Api.Error(type: `\(type)`, code: `\(code ?? "nil")`, message: `\(message ?? "nil")`, docUrl: `\(docUrl ?? "nil")`, param: `\(param ?? "nil")`)"
  }
}

extension Stripe.Api.Error: CustomDebugStringConvertible {
  public var debugDescription: String { self.description }
}

extension Stripe.Api.Error: Decodable {}
