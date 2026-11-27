import Foundation

struct Coupon {
    let percentOff: Double
    let expiresAt: Date
}

final class CartStore {
    private(set) var subtotal: Double = 0

    func add(price: Double) {
        subtotal += price
    }

    func total(applying coupon: Coupon?, now: Date) -> Double {
        guard let coupon, coupon.expiresAt > now else {
            return subtotal
        }

        return subtotal * (1 - coupon.percentOff / 100)
    }
}
