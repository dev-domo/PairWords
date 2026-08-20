//
//  DependencyValues+GroupClient.swift
//  PairWords
//
//  Created by 더스틴 on 8/14/26.
//

import Dependencies

extension DependencyValues {
    nonisolated var groupClient: GroupClient {
        get { self[GroupClient.self] }
        set { self[GroupClient.self] = newValue }
    }
}
