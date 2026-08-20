//
//  SettingsFeature.swift
//  PairWords
//
//  12_설정 / 13_입장코드공유 / 14_입장코드재생성 / 15_그룹탈퇴모달
//

import Foundation
import ComposableArchitecture

@Reducer
struct SettingsFeature {

    @ObservableState
    struct State: Equatable {
        var groupID: String
        var currentCode: String

        // 입장코드 재생성
        var isRegeneratingCode: Bool = false

        // 그룹 탈퇴 확인 모달
        var isWithdrawConfirmationPresented: Bool = false
        var isWithdrawing: Bool = false

        var errorMessage: String?
    }

    enum Action {
        // 코드 공유는 View에서 UIActivityViewController로 처리 (Reducer는 트리거만 담당)
        case shareCodeButtonTapped

        // 코드 재생성
        case regenerateCodeButtonTapped
        case regenerateCodeResponse(Result<String, EquatableError>)

        // 그룹 탈퇴
        case withdrawButtonTapped
        case cancelWithdrawButtonTapped
        case confirmWithdrawButtonTapped
        case withdrawResponse(Result<Void, EquatableError>)

        case delegate(Delegate)

        enum Delegate: Equatable {
            case didWithdraw
        }
    }

    @Dependency(\.groupClient) var groupClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .shareCodeButtonTapped:
                return .none

            case .regenerateCodeButtonTapped:
                state.isRegeneratingCode = true
                state.errorMessage = nil

                return .run { send in
                    await send(.regenerateCodeResponse(
                        Result { try await groupClient.createGroup() }
                            .mapError(EquatableError.init)
                    ))
                }

            case let .regenerateCodeResponse(.success(newCode)):
                state.isRegeneratingCode = false
                state.currentCode = newCode
                return .none

            case .regenerateCodeResponse(.failure):
                state.isRegeneratingCode = false
                state.errorMessage = "잠시 후 다시 시도해주세요"
                return .none

            case .withdrawButtonTapped:
                state.isWithdrawConfirmationPresented = true
                return .none

            case .cancelWithdrawButtonTapped:
                state.isWithdrawConfirmationPresented = false
                return .none

            case .confirmWithdrawButtonTapped:
                state.isWithdrawing = true
                let groupID = state.groupID

                return .run { send in
                    await send(.withdrawResponse(
                        Result { try await groupClient.withdrawGroup(groupID: groupID) }
                            .mapError(EquatableError.init)
                    ))
                }

            case .withdrawResponse(.success):
                state.isWithdrawing = false
                state.isWithdrawConfirmationPresented = false
                return .send(.delegate(.didWithdraw))

            case .withdrawResponse(.failure):
                state.isWithdrawing = false
                state.errorMessage = "잠시 후 다시 시도해주세요"
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
