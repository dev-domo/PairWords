//
//  DependencyValues+SlangClient.swift
//  PairWords
//
//  Created by 더스틴 on 8/14/26.
//

import Dependencies

extension DependencyValues {
    nonisolated var slangClient: SlangClient {
        get { self[SlangClient.self] }
        set { self[SlangClient.self] = newValue }
    }
}
