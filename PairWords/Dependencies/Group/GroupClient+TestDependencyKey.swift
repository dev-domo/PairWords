//
//  GroupClient+TestDependencyKey.swift
//  PairWords
//
//  Created by 더스틴 on 8/14/26.
//

import Dependencies

extension GroupClient: nonisolated TestDependencyKey {
    nonisolated static let previewValue = GroupClient(
        createGroup: { "AB12CD" },
        enterGroup: { _ in "preview-group-id" },
        withdrawGroup: { _ in }
    )

    nonisolated static let testValue = GroupClient()
}
