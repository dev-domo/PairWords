//
//  DependencyValues+AudioRecorderClient.swift
//  PairWords
//

import Dependencies

extension DependencyValues {
    nonisolated var audioRecorderClient: AudioRecorderClient {
        get { self[AudioRecorderClient.self] }
        set { self[AudioRecorderClient.self] = newValue }
    }
}
