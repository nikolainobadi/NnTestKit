//
//  BaseUITestCase+Seeding.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 4/11/26.
//

import XCTest
import NnTestVariables

// MARK: - Launch Helpers
public extension BaseUITestCase {
    /// Sets seed config env vars and launches the app. The app's `UITestBootstrapView`
    /// reads these vars, decodes the config, and runs the seeder before rendering UI.
    func launchSeeded<Config: Codable>(
        config: Config,
        envKeys: [String] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        setSeedConfig(config, envKeys: envKeys)
        app.launch()
    }

    /// Sets seed config env vars without launching. Use when another method
    /// (e.g. `signUpWithEmail`) handles the launch.
    func setSeedConfig<Config: Codable>(
        _ config: Config,
        envKeys: [String] = []
    ) {
        let runId = String(UUID().uuidString.prefix(8)).lowercased()
        let email = "tester+\(runId)@uitest.local"

        addKeyToENV(UITestSeedKey.runId.rawValue, value: runId)
        addKeyToENV(UITestSeedKey.userEmail.rawValue, value: email)

        if let jsonData = try? JSONEncoder().encode(config),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            addKeyToENV(UITestSeedKey.seedConfig.rawValue, value: jsonString)
        }

        for key in envKeys {
            addKeyToENV(key)
        }
    }
}


// MARK: - Identity Helpers
public extension BaseUITestCase {
    /// The main test user's email. Must be called after `launchSeeded` or `setSeedConfig`.
    var mainUserEmail: String {
        app.launchEnvironment[UITestSeedKey.userEmail.rawValue] ?? ""
    }

    /// Returns the email for an additional user seeded via the app's seeder.
    /// The email format must match what the app-side seeder uses.
    /// Must be called after `launchSeeded` or `setSeedConfig` (needs runId in env).
    func seedEmail(for userName: String) -> String {
        let runId = app.launchEnvironment[UITestSeedKey.runId.rawValue] ?? ""
        return "\(userName.lowercased())+\(runId)@uitest.local"
    }

    /// Generates a unique name with two random digits appended.
    /// Use for house names, member names, usernames — anything that must not
    /// collide across test runs.
    func makeUniqueName(_ base: String) -> String {
        return "\(base)\(getRandomNumber())\(getRandomNumber())"
    }
}


// MARK: - Password Prompt Helper
public extension BaseUITestCase {
    /// Dismisses the iOS "Save Password?" prompt if it appears.
    /// Call after any login flow that may trigger the prompt.
    func dismissPasswordPromptIfNeeded(timeout: TimeInterval? = nil) {
        let timeout = timeout ?? UITestSeedDefaults.timeout
        let notNow = app.buttons["Not Now"]
        if notNow.waitForExistence(timeout: timeout) {
            notNow.tap()
        }
    }
}
