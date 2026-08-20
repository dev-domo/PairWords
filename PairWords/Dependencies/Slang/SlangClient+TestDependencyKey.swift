//
//  SlangClient+TestDependencyKey.swift
//  PairWords
//
//  Created by 더스틴 on 8/14/26.
//

import Foundation

import Dependencies

extension SlangClient: nonisolated TestDependencyKey {
    nonisolated static let previewValue = SlangClient(
        observeSlangs: { _ in
            AsyncStream { continuation in
                continuation.yield([
                    Slang(id: "1", name: "무댕", representativeMeaning: "하마라는 뜻", createdBy: "preview", createdAt: Date())
                ])
                continuation.finish()
            }
        },
        observeMeanings: { _, _ in
            AsyncStream { continuation in
                continuation.yield([Meaning(id: "1", text: "심부름 시키는 것", createdBy: "preview", createdAt: Date())])
                continuation.finish()
            }
        },
        observeRecordings: { _, _ in
            AsyncStream { continuation in continuation.finish() }
        },
        createSlang: { _, _, _, _ in },
        addMeaning: { _, _, _ in },
        addRecording: { _, _, _ in },
        fetchSlang: { _, _ in [] }
    )

    nonisolated static let testValue = SlangClient()
}
