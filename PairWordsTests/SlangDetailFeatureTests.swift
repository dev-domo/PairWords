//
//  SlangDetailFeatureTests.swift
//  PairWordsTests
//

import Foundation
import XCTest
@testable import PairWords
import ComposableArchitecture

@MainActor
final class SlangDetailFeatureTests: XCTestCase {

    private func makeState() -> SlangDetailFeature.State {
        SlangDetailFeature.State(groupID: "group1", slangID: "slang1", slangName: "무댕")
    }

    // MARK: - onAppear

    func testOnAppear_observesMeaningsAndRecordings() async {
        let expectedMeanings = [Meaning(id: "m1", text: "하마라는 뜻", createdBy: "tester", createdAt: .now)]
        let expectedRecordings = [Recording(id: "r1", audioURL: "https://example.com/a.m4a", createdBy: "tester", createdAt: .now)]

        let store = TestStore(initialState: makeState()) {
            SlangDetailFeature()
        } withDependencies: {
            $0.slangClient.observeMeanings = { groupID, slangID in
                XCTAssertEqual(groupID, "group1")
                XCTAssertEqual(slangID, "slang1")
                return AsyncStream { continuation in
                    continuation.yield(expectedMeanings)
                    continuation.finish()
                }
            }
            $0.slangClient.observeRecordings = { _, _ in
                AsyncStream { continuation in
                    continuation.yield(expectedRecordings)
                    continuation.finish()
                }
            }
        }

        await store.send(.onAppear)

        await store.receive(\.updateMeanings, expectedMeanings) {
            $0.meanings = expectedMeanings
        }
        await store.receive(\.updateRecordings, expectedRecordings) {
            $0.recordings = expectedRecordings
        }

        await store.finish()
    }

    // MARK: - 뜻 추가

    func testAddMeaningButtonTapped_presentsSheet() async {
        let store = TestStore(initialState: makeState()) {
            SlangDetailFeature()
        }

        await store.send(.addMeaningButtonTapped) {
            $0.isAddMeaningSheetPresented = true
            $0.newMeaningText = ""
        }
    }

    func testConfirmAddMeaning_success() async {
        var state = makeState()
        state.isAddMeaningSheetPresented = true
        state.newMeaningText = "새로운 뜻"

        let store = TestStore(initialState: state) {
            SlangDetailFeature()
        } withDependencies: {
            $0.slangClient.addMeaning = { groupID, slangID, meaning in
                XCTAssertEqual(groupID, "group1")
                XCTAssertEqual(slangID, "slang1")
                XCTAssertEqual(meaning, "새로운 뜻")
            }
        }

        await store.send(.confirmAddMeaningButtonTapped) {
            $0.isAddingMeaning = true
        }

        await store.receive { action in
            if case .addMeaningResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.isAddingMeaning = false
            $0.isAddMeaningSheetPresented = false
            $0.newMeaningText = ""
        }
    }

    func testConfirmAddMeaning_emptyText_doesNothing() async {
        var state = makeState()
        state.newMeaningText = "   "

        let store = TestStore(initialState: state) {
            SlangDetailFeature()
        }

        await store.send(.confirmAddMeaningButtonTapped)
    }

    func testConfirmAddMeaning_failure() async {
        var state = makeState()
        state.newMeaningText = "새로운 뜻"

        let store = TestStore(initialState: state) {
            SlangDetailFeature()
        } withDependencies: {
            $0.slangClient.addMeaning = { _, _, _ in
                throw SlangRegistrationError.retryLater
            }
        }

        await store.send(.confirmAddMeaningButtonTapped) {
            $0.isAddingMeaning = true
        }

        await store.receive { action in
            if case .addMeaningResponse(.failure) = action {
                return true
            }
            return false
        } assert: {
            $0.isAddingMeaning = false
            $0.errorMessage = "잠시 후 다시 시도해주세요"
        }
    }

    // MARK: - 음성 추가 상태 머신

    func testRecordingFlow_startStopContinue() async {
        let recordedURL = URL(string: "file:///tmp/recorded.m4a")!

        var state = makeState()
        state.isAddRecordingSheetPresented = true

        let store = TestStore(initialState: state) {
            SlangDetailFeature()
        } withDependencies: {
            $0.audioRecorderClient.requestPermission = { true }
            $0.audioRecorderClient.startRecording = {}
            $0.audioRecorderClient.stopRecording = { recordedURL }
            $0.slangClient.addRecording = { groupID, slangID, audioURL in
                XCTAssertEqual(groupID, "group1")
                XCTAssertEqual(slangID, "slang1")
                XCTAssertEqual(audioURL, recordedURL)
            }
        }

        // 1. 녹음 시작
        await store.send(.startRecordingButtonTapped)
        await store.receive { action in
            if case .startRecordingResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.recordingSheetState = .recording
        }

        // 2. 녹음 중지
        await store.send(.stopRecordingButtonTapped)
        await store.receive { action in
            if case .stopRecordingResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.recordingSheetState = .recorded(fileURL: recordedURL)
        }

        // 3. 계속하기 → addRecording 호출
        await store.send(.continueRecordingButtonTapped) {
            $0.isAddingRecording = true
        }
        await store.receive { action in
            if case .addRecordingResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.isAddingRecording = false
            $0.isAddRecordingSheetPresented = false
            $0.recordingSheetState = .idle
        }
    }

    func testRecordingFlow_retryDiscardsRecording() async {
        var state = makeState()
        state.isAddRecordingSheetPresented = true
        state.recordingSheetState = .recorded(fileURL: URL(string: "file:///tmp/a.m4a")!)

        let store = TestStore(initialState: state) {
            SlangDetailFeature()
        } withDependencies: {
            $0.audioRecorderClient.cancelRecording = {}
        }

        await store.send(.retryRecordingButtonTapped) {
            $0.recordingSheetState = .idle
        }
    }

    func testStartRecording_permissionDenied() async {
        var state = makeState()
        state.isAddRecordingSheetPresented = true

        let store = TestStore(initialState: state) {
            SlangDetailFeature()
        } withDependencies: {
            $0.audioRecorderClient.requestPermission = { false }
        }

        await store.send(.startRecordingButtonTapped)

        await store.receive { action in
            if case .startRecordingResponse(.failure) = action {
                return true
            }
            return false
        } assert: {
            $0.errorMessage = "마이크 권한을 확인해주세요"
        }
    }
}
