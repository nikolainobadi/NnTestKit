import XCTest
@testable import MyApp

let sharedService = FakeService()
let sharedCache = FakeCache()

final class OrderManagerTests: XCTestCase {
    func makeSUT() -> OrderManager {
        sharedService.shouldFail = false
        return OrderManager(service: sharedService, cache: sharedCache)
    }

    func testSubmit() async throws {
        let order = Order(id: UUID(), items: ["Book"], total: 12, isSubmitted: false)
        let result = try await makeSUT().submit(order)
        XCTAssertTrue(result.isSubmitted)
        XCTAssertEqual(sharedCache.saved.count, 1)
    }

    func testSubmitFails() async {
        sharedService.shouldFail = true
        let sut = OrderManager(service: sharedService, cache: sharedCache)
        do {
            _ = try await sut.submit(Order(id: UUID(), items: [], total: 0, isSubmitted: false))
            XCTFail()
        } catch { }
    }
}

final class FakeService: OrderService {
    var shouldFail = false
    func submit(_ order: Order) async throws {
        if shouldFail { throw URLError(.badServerResponse) }
    }
}

final class FakeCache: OrderCache {
    var saved: [Order] = []
    func save(_ order: Order) { saved.append(order) }
}
