//
//  SlangDetailFeature.swift
//  PairWords
//
//  05_유행어상세: 이름/뜻/음성 조회, 뜻·음성 "추가"만 가능 (수정/삭제 불가)
//

import Foundation
import ComposableArchitecture

@Reducer
struct SlangDetailFeature {

    /// 음성 녹음 추가 bottom sheet의 상태 머신.
    /// 명세서 5-3-2: 녹음 버튼 → 중지 버튼 → (다시 녹음하기 / 계속하기)
    enum RecordingSheetState: Equatable {
        case idle
        case recording
        case recorded(fileURL: URL)
    }

    @ObservableState
    struct State: Equatable {
        var groupID: String
        var slangID: String
        var slangName: String

        var meanings: [Meaning] = []
        var recordings: [Recording] = []

        // 뜻 추가 bottom sheet
        var isAddMeaningSheetPresented: Bool = false
        var newMeaningText: String = ""
        var isAddingMeaning: Bool = false

        // 음성 추가 bottom sheet
        var isAddRecordingSheetPresented: Bool = false
        var recordingSheetState: RecordingSheetState = .idle
        var isAddingRecording: Bool = false

        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case updateMeanings([Meaning])
        case updateRecordings([Recording])

        // 뜻 추가
        case addMeaningButtonTapped
        case newMeaningTextChanged(String)
        case confirmAddMeaningButtonTapped
        case addMeaningResponse(Result<Void, EquatableError>)
        case dismissAddMeaningSheet

        // 음성 추가
        case addRecordingButtonTapped
        case startRecordingButtonTapped
        case startRecordingResponse(Result<Void, EquatableError>)
        case stopRecordingButtonTapped
        case stopRecordingResponse(Result<URL, EquatableError>)
        case retryRecordingButtonTapped
        case continueRecordingButtonTapped
        case addRecordingResponse(Result<Void, EquatableError>)
        case dismissAddRecordingSheet
    }

    @Dependency(\.slangClient) var slangClient
    @Dependency(\.audioRecorderClient) var audioRecorderClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let groupID = state.groupID
                let slangID = state.slangID

                return .merge(
                    .run { send in
                        let stream = try await slangClient.observeMeanings(groupID: groupID, slangID: slangID)
                        for await meanings in stream {
                            await send(.updateMeanings(meanings))
                        }
                    },
                    .run { send in
                        let stream = try await slangClient.observeRecordings(groupID: groupID, slangID: slangID)
                        for await recordings in stream {
                            await send(.updateRecordings(recordings))
                        }
                    }
                )

            case let .updateMeanings(meanings):
                state.meanings = meanings
                return .none

            case let .updateRecordings(recordings):
                state.recordings = recordings
                return .none

            // MARK: - 뜻 추가

            case .addMeaningButtonTapped:
                state.isAddMeaningSheetPresented = true
                state.newMeaningText = ""
                return .none

            case let .newMeaningTextChanged(text):
                state.newMeaningText = text
                return .none

            case .confirmAddMeaningButtonTapped:
                let text = state.newMeaningText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return .none }

                state.isAddingMeaning = true
                let groupID = state.groupID
                let slangID = state.slangID

                return .run { send in
                    await send(.addMeaningResponse(
                        Result { try await slangClient.addMeaning(groupID: groupID, slangID: slangID, meaning: text) }
                            .mapError(EquatableError.init)
                    ))
                }

            case .addMeaningResponse(.success):
                state.isAddingMeaning = false
                state.isAddMeaningSheetPresented = false
                state.newMeaningText = ""
                return .none

            case .addMeaningResponse(.failure):
                state.isAddingMeaning = false
                state.errorMessage = "잠시 후 다시 시도해주세요"
                return .none

            case .dismissAddMeaningSheet:
                state.isAddMeaningSheetPresented = false
                state.newMeaningText = ""
                return .none

            // MARK: - 음성 추가

            case .addRecordingButtonTapped:
                state.isAddRecordingSheetPresented = true
                state.recordingSheetState = .idle
                return .none

            case .startRecordingButtonTapped:
                return .run { send in
                    let granted = await audioRecorderClient.requestPermission()
                    guard granted else {
                        await send(.startRecordingResponse(.failure(.init(AudioRecorderError.permissionDenied))))
                        return
                    }
                    await send(.startRecordingResponse(
                        Result { try await audioRecorderClient.startRecording() }
                            .mapError(EquatableError.init)
                    ))
                }

            case .startRecordingResponse(.success):
                state.recordingSheetState = .recording
                return .none

            case .startRecordingResponse(.failure):
                state.errorMessage = "마이크 권한을 확인해주세요"
                return .none

            case .stopRecordingButtonTapped:
                return .run { send in
                    await send(.stopRecordingResponse(
                        Result { try await audioRecorderClient.stopRecording() }
                            .mapError(EquatableError.init)
                    ))
                }

            case let .stopRecordingResponse(.success(fileURL)):
                state.recordingSheetState = .recorded(fileURL: fileURL)
                return .none

            case .stopRecordingResponse(.failure):
                state.recordingSheetState = .idle
                state.errorMessage = "녹음에 실패했어요"
                return .none

            case .retryRecordingButtonTapped:
                state.recordingSheetState = .idle
                return .run { _ in
                    await audioRecorderClient.cancelRecording()
                }

            case .continueRecordingButtonTapped:
                guard case let .recorded(fileURL) = state.recordingSheetState else { return .none }
                state.isAddingRecording = true
                let groupID = state.groupID
                let slangID = state.slangID

                return .run { send in
                    await send(.addRecordingResponse(
                        Result { try await slangClient.addRecording(groupID: groupID, slangID: slangID, audioURL: fileURL) }
                            .mapError(EquatableError.init)
                    ))
                }

            case .addRecordingResponse(.success):
                state.isAddingRecording = false
                state.isAddRecordingSheetPresented = false
                state.recordingSheetState = .idle
                return .none

            case .addRecordingResponse(.failure):
                state.isAddingRecording = false
                state.errorMessage = "잠시 후 다시 시도해주세요"
                return .none

            case .dismissAddRecordingSheet:
                state.isAddRecordingSheetPresented = false
                let wasRecording = state.recordingSheetState != .idle
                state.recordingSheetState = .idle
                guard wasRecording else { return .none }
                return .run { _ in
                    await audioRecorderClient.cancelRecording()
                }
            }
        }
    }
}
