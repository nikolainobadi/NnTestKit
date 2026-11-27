import Foundation

enum PaymentValidationError: Error, Equatable {
    case invalidCardNumber
    case expired
    case nonPositiveAmount
}

struct PaymentValidator {
    let currentMonth: Int
    let currentYear: Int

    func validate(_ payment: Payment) throws {
        let digits = payment.cardNumber.filter(\.isNumber)
        guard (13...19).contains(digits.count) else { throw PaymentValidationError.invalidCardNumber }

        if payment.expiryYear < currentYear || (payment.expiryYear == currentYear && payment.expiryMonth < currentMonth) {
            throw PaymentValidationError.expired
        }

        guard payment.amount > 0 else { throw PaymentValidationError.nonPositiveAmount }
    }
}
