//
//  UITestSeedKeys.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 4/11/26.
//

import Foundation

public enum UITestSeedKey: String {
    case runId = "UITEST_RUN_ID"
    case userEmail = "UITEST_USER_EMAIL"
    case seedConfig = "UITEST_SEED_CONFIG"
}

public enum UITestSeedDefaults {
    public static let password = "uitest-password"

    /// Default timeout for seeding helpers. Client apps can override this
    /// (e.g. in `setUpWithError`) to adjust for slower environments.
    public static var timeout: TimeInterval = 10
}
