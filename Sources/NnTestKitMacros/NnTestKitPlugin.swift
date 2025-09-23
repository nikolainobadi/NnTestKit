//
//  NnTestKitPlugin.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 9/23/25.
//

import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct NnTestKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [LeakTrackedMacro.self]
}
