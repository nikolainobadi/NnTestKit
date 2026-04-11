//
//  UITestBootstrapView.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 4/11/26.
//

#if os(iOS)
import SwiftUI

/// A generic view that gates content rendering on an async setup closure.
/// Use this in your test app's `@main` to run seeding (or any async setup)
/// before the main UI appears.
///
/// ```swift
/// UITestBootstrapView(
///     setup: { await runSeeding() },
///     onFailure: { fatalError("Seeding failed: \($0)") }
/// ) {
///     MyMainView()
/// }
/// ```
public struct UITestBootstrapView<Content: View>: View {
    @State private var ready = false

    private let setup: () async throws -> Void
    private let onFailure: (Error) -> Void
    private let content: () -> Content

    public init(
        setup: @escaping () async throws -> Void,
        onFailure: @escaping (Error) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.setup = setup
        self.onFailure = onFailure
        self.content = content
    }

    public var body: some View {
        Group {
            if ready {
                content()
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                try await setup()
            } catch {
                onFailure(error)
            }
            ready = true
        }
    }
}
#endif
