//
//  CombineHelpers.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 4/20/25.
//

import Combine

@MainActor
public extension Published.Publisher where Output: Equatable & Sendable {
    /// Errors that can be thrown while waiting on a publisher.
    enum PublisherError: Error {
        /// Thrown when the expected value does not appear within the timeout period.
        case timeout
    }
    
    /// Asynchronously waits for the publisher to emit a value that satisfies a given condition, or throws an error if the timeout is reached.
    ///
    /// - Parameters:
    ///   - timeout: The maximum number of seconds to wait. Defaults to 1 second.
    ///   - condition: A closure that receives each emitted value and returns `true` when the desired condition is met.
    ///
    /// - Throws: `PublisherError.timeout` if the condition is not met within the specified timeout, or `CancellationError` if the task is canceled.
    ///
    /// This method is useful in tests where you want to assert that a `@Published` property eventually reaches a specific state.
    func waitUntil(timeout: Double = 1, condition: @escaping (Output) -> Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var didResume = false

            func resumeOnce(with result: Result<Void, Error>) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(with: result)
            }

            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: .init(timeout * 1_000_000_000))
                resumeOnce(with: .failure(PublisherError.timeout))
            }

            _ = Task {
                for await newValue in values {
                    if condition(newValue) {
                        timeoutTask.cancel()
                        resumeOnce(with: .success(()))
                        return
                    }
                }
                resumeOnce(with: .failure(CancellationError()))
            }
        }
    }
}
