//
//  ObservationHelpers.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 5/23/26.
//

import Testing
import Observation

// MARK: - Stream

/// Bridges an `@Observable` property to an `AsyncStream` of its values.
///
/// `withObservationTracking` only fires once per registration. This helper
/// re-registers inside its own `onChange` callback so callers get a
/// continuous stream of values produced *after* each change.
///
/// Pair with `AsyncStream.waitUntil(timeout:condition:)` for the same
/// ergonomics as `Published.Publisher.waitUntil` in `CombineHelpers`.
///
/// Caveats:
/// - The stream yields only on changes, not the initial value. If the
///   property already satisfies your predicate at subscribe time,
///   `waitUntil` will still wait for the next mutation.
/// - Rapid successive mutations may coalesce into a single yield with the
///   latest value, since re-registration is dispatched asynchronously.
///   Tests that wait for a property to *settle* on a value are unaffected;
///   tests that need every intermediate transition are not the right fit.
///
/// - Parameter read: An autoclosure-style closure that reads the tracked
///   property. Must be `@MainActor`-isolated.
/// - Returns: An `AsyncStream` that yields the latest value after each
///   observed change.
@MainActor
@available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
public func observationStream<T: Sendable>(
    of read: @escaping @MainActor () -> T
) -> AsyncStream<T> {
    let (stream, continuation) = AsyncStream<T>.makeStream()

    @MainActor func track() {
        withObservationTracking {
            _ = read()
        } onChange: {
            Task { @MainActor in
                let result = continuation.yield(read())
                if case .terminated = result { return }
                track()
            }
        }
    }

    track()
    return stream
}

// MARK: - waitUntil

public extension AsyncStream where Element: Sendable {
    /// Errors that can be thrown while waiting on a stream.
    enum WaitError: Error {
        /// Thrown when the condition is not satisfied within the timeout.
        case timeout
    }

    /// Asynchronously waits for the stream to yield a value that satisfies
    /// `condition`, or throws `WaitError.timeout` if the timeout elapses.
    ///
    /// Mirrors `Published.Publisher.waitUntil` in `CombineHelpers` so tests
    /// can use the same shape regardless of whether the source is
    /// `@Published` or `@Observable`.
    ///
    /// - Parameters:
    ///   - timeout: Maximum seconds to wait. Defaults to 1.
    ///   - condition: Returns `true` for the value that satisfies the wait.
    /// - Throws: `WaitError.timeout` if no matching value arrives in time,
    ///   or `CancellationError` if the stream finishes first.
    func waitUntil(
        timeout: Double = 1,
        condition: @escaping (Element) -> Bool
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw WaitError.timeout
            }
            group.addTask {
                for await value in self {
                    if condition(value) { return }
                }
                throw CancellationError()
            }
            try await group.next()
            group.cancelAll()
        }
    }
}

// MARK: - One-shot assertion

/// Asserts that an `@Observable` property change propagates through
/// `withObservationTracking` after running `trigger`.
///
/// Useful for verifying that abstraction layers — protocol witnesses,
/// computed properties, view-model wrappers — preserve observation
/// propagation rather than silently breaking it.
///
/// Built on top of `observationStream(of:)` + `AsyncStream.waitUntil`, so
/// it handles async triggers and actor hops reliably (within `timeout`).
///
/// - Parameters:
///   - trigger: Mutate the source `@Observable` here.
///   - read: An autoclosure that reads a property whose change should fire observation.
///   - timeout: Maximum seconds to wait for the change. Defaults to 1.
///   - sourceLocation: Set automatically by Swift Testing.
@MainActor
@available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)
public func expectObservationFires<T: Sendable>(
    when trigger: () async throws -> Void,
    afterReading read: @autoclosure @escaping @MainActor () -> T,
    timeout: Double = 1,
    sourceLocation: SourceLocation = #_sourceLocation
) async rethrows {
    let stream = observationStream(of: read)

    try await trigger()

    let fired = (try? await stream.waitUntil(timeout: timeout) { _ in true }) != nil
    #expect(fired, "Observation did not fire within \(timeout)s", sourceLocation: sourceLocation)
}
