import Foundation

protocol OrderService {
    func submit(_ order: Order) async throws
}

protocol OrderCache {
    func save(_ order: Order)
}

final class OrderManager {
    private let service: OrderService
    private let cache: OrderCache

    init(service: OrderService, cache: OrderCache) {
        self.service = service
        self.cache = cache
    }

    func submit(_ order: Order) async throws -> Order {
        try await service.submit(order)
        var submitted = order
        submitted.isSubmitted = true
        cache.save(submitted)
        return submitted
    }
}
