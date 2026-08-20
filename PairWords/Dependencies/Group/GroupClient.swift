//
//  GroupClient.swift
//  PairWords
//
//  Created by 더스틴 on 8/14/26.
//

import Dependencies
import DependenciesMacros
import FirebaseFirestore
import FirebaseStorage

@DependencyClient
nonisolated struct GroupClient: Sendable {
    var createGroup: @Sendable () async throws -> String
    var enterGroup: @Sendable (_ enterCode: String) async throws -> String
    var withdrawGroup: @Sendable (_ groupID: String) async throws -> Void
}
