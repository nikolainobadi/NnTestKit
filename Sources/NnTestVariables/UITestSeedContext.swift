//
//  UITestSeedContext.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 4/11/26.
//

import Foundation

public struct UITestSeedContext<Config: Codable & Sendable>: Sendable {
    public let runId: String
    public let config: Config
    public let userEmail: String
    public let userPassword: String

    public init(runId: String, config: Config, userEmail: String, userPassword: String) {
        self.runId = runId
        self.config = config
        self.userEmail = userEmail
        self.userPassword = userPassword
    }
}

public extension UITestSeedContext {
    static func fromEnvironment(_ configType: Config.Type) -> UITestSeedContext? {
        let env = ProcessInfo.processInfo.environment

        guard let runId = env[UITestSeedKey.runId.rawValue],
              let email = env[UITestSeedKey.userEmail.rawValue]
        else {
            return nil
        }

        let config: Config
        if let jsonString = env[UITestSeedKey.seedConfig.rawValue],
           let data = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(Config.self, from: data) {
            config = decoded
        } else {
            return nil
        }

        return UITestSeedContext(
            runId: runId,
            config: config,
            userEmail: email,
            userPassword: UITestSeedDefaults.password
        )
    }
}
