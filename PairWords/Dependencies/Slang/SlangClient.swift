//
//  SlangClient.swift
//  PairWords
//
//  Created by 더스틴 on 8/11/26.
//

import Foundation

import Dependencies
import DependenciesMacros

@DependencyClient
nonisolated struct SlangClient: Sendable {
    var observeSlangs: @Sendable (_ groupID: String) async throws -> AsyncStream<[Slang]>
    var observeMeanings: @Sendable (_ groupID: String, _ slangID: String) async throws -> AsyncStream<[Meaning]>
    var observeRecordings: @Sendable (_ groupID: String, _ slangID: String) async throws -> AsyncStream<[Recording]>
    
    var createSlang: @Sendable (_ groupID: String, _ name: String, _ meaning: String, _ audioURL: URL) async throws -> Void
    var addMeaning: @Sendable (_ groupID: String, _ slangID: String, _ meaning: String) async throws -> Void
    var addRecording: @Sendable (_ groupID: String, _ slangID: String, _ audioURL: URL) async throws -> Void
    var fetchSlang: @Sendable (_ groupID: String, _ keyword: String) async throws -> [Slang]
}
