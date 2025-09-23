//  LeakTrackedMacroTests.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 1/22/25.
//

import Testing
@testable import NnSwiftTestingHelpers

private final class LeakFreeSUT {}
private final class LeakySUT {
    var closure: (() -> Void)?
    init() { closure = { _ = self } }
}

@LeakTracked
final class LeakTrackedParityTests {
    @Test("trackForMemoryLeaks is injected")
    func apiIsInjected() {
        let sut = LeakFreeSUT()

        trackForMemoryLeaks(sut)
    }

    @Test("Leak free passes with default behavior")
    func leakFree_default_passes() {
        let sut = LeakFreeSUT()
        trackForMemoryLeaks(sut)
    }
}

@LeakTracked
final class LeakTrackedCrossActorTests {
    @Test("Background actor call is safe")
    func backgroundCall() async {
        let t = Task { [self] in
            let sut = LeakFreeSUT()
            self.trackForMemoryLeaks(sut)
        }
        await t.value
    }

    @Test("Main actor call is safe")
    func mainActorCall() async {
        let sut = LeakFreeSUT()
        _ = await MainActor.run { [self] in
            self.trackForMemoryLeaks(sut)
        }
    }
}

@LeakTracked
final class LeakTrackedBehaviorTests {
    @Test("EXPECT LEAK passes for leaky SUT")
    func expectLeak_passes_forLeaky() {
        let sut = LeakySUT()
        trackForMemoryLeaks(sut, behavior: .expectLeak)
    }

    @Test("WARN ONLY does not fail")
    func warnOnly_passes_forLeaky() {
        let sut = LeakySUT()
        trackForMemoryLeaks(sut, behavior: .warnIfLeaked)
    }
    
    @Test("Default FAILS on leak", .disabled())
    func default_failOnLeak() {
        let sut = LeakySUT()
        trackForMemoryLeaks(sut)              // will FAIL (by design)
    }

    @Test("EXPECT LEAK fails for leak-free SUT", .disabled())
    func expectLeak_fails_forLeakFree() {
        let sut = LeakFreeSUT()
        trackForMemoryLeaks(sut, behavior: .expectLeak) // will FAIL (by design)
    }
}
