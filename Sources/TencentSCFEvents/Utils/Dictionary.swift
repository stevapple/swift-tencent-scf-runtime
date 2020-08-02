//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2020 stevapple and the SwiftTencentSCFRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftTencentSCFRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

extension Dictionary {
    @inlinable public func mapKeys<T: Hashable>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        var transformed = [T: Value]()
        try self.forEach { key, value in
            transformed[try transform(key)] = value
        }
        return transformed
    }

    @inlinable public func compactMapKeys<T: Hashable>(_ transform: (Key) throws -> T?) rethrows -> [T: Value] {
        var transformed = [T: Value]()
        try self.forEach { key, value in
            if let newKey = try transform(key) {
                transformed[newKey] = value
            }
        }
        return transformed
    }
}
