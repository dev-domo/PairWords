//
//  AudioRecorderClient+DependencyKey.swift
//  PairWords
//

import Foundation
import Dependencies
import AVFoundation

/// AVAudioRecorder는 Sendable이 아니라서, 접근을 하나의 액터로 직렬화합니다.
private actor AudioRecorderStorage {
    private var recorder: AVAudioRecorder?
    private var currentFileURL: URL?

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let newRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        newRecorder.record()

        self.recorder = newRecorder
        self.currentFileURL = fileURL
    }

    func stopRecording() throws -> URL {
        guard let recorder, let fileURL = currentFileURL else {
            throw AudioRecorderError.noActiveRecording
        }
        recorder.stop()
        self.recorder = nil
        self.currentFileURL = nil
        return fileURL
    }

    func cancelRecording() {
        recorder?.stop()
        if let currentFileURL {
            try? FileManager.default.removeItem(at: currentFileURL)
        }
        recorder = nil
        currentFileURL = nil
    }
}

extension AudioRecorderClient: nonisolated DependencyKey {
    nonisolated static let liveValue: AudioRecorderClient = {
        let storage = AudioRecorderStorage()

        return AudioRecorderClient(
            requestPermission: {
                await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            },
            startRecording: {
                do {
                    try await storage.startRecording()
                } catch {
                    throw AudioRecorderError.recordingFailed
                }
            },
            stopRecording: {
                try await storage.stopRecording()
            },
            cancelRecording: {
                await storage.cancelRecording()
            }
        )
    }()
}
