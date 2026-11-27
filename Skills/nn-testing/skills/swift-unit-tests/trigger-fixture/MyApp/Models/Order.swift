import Foundation

struct Order: Equatable {
    let id: UUID
    var items: [String]
    var total: Decimal
    var isSubmitted: Bool
}

struct Payment: Equatable {
    let cardNumber: String
    let expiryMonth: Int
    let expiryYear: Int
    let amount: Decimal
}
