//
//  AudioRecorderClient.swift
//  PairWords
//

import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
nonisolated struct AudioRecorderClient: Sendable {
    /// 마이크 권한을 요청하고 허용 여부를 반환합니다.
    var requestPermission: @Sendable () async -> Bool = { false }
    /// 녹음을 시작합니다.
    var startRecording: @Sendable () async throws -> Void
    /// 녹음을 중지하고, 녹음된 파일의 로컬 URL을 반환합니다.
    var stopRecording: @Sendable () async throws -> URL
    /// 진행 중인 녹음을 취소하고 임시 파일을 정리합니다. (다시 녹음하기)
    var cancelRecording: @Sendable () async -> Void
}

enum AudioRecorderError: Error, Equatable {
    case permissionDenied
    case recordingFailed
    case noActiveRecording
}
