//
//  AudioRecorderClient+TestDependencyKey.swift
//  PairWords
//

import Foundation
import Dependencies

extension AudioRecorderClient: nonisolated TestDependencyKey {
    nonisolated static let previewValue = AudioRecorderClient(
        requestPermission: { true },
        startRecording: {},
        stopRecording: { URL(string: "file:///preview-recording.m4a")! },
        cancelRecording: {}
    )

    nonisolated static let testValue = AudioRecorderClient()
}
