//
//  CreateGroupFeature.swift
//  PairWords
//
//  02_새그룹만들기: <입장코드 생성> → <공유하기> → <그룹 생성하기>
//  <그룹 생성하기>는 입장코드 생성이 완료될 때까지 비활성화 상태.
//

import Foundation
import ComposableArchitecture

@Reducer
struct CreateGroupFeature {

    @ObservableState
    struct State: Equatable {
        var generatedCode: String?
        var isGeneratingCode: Bool = false
        var isCreatingGroup: Bool = false
        var errorMessage: String?

        /// 명세서 2-3: 입장코드 생성이 완료될 때까지 <그룹 생성하기> 버튼은 비활성화.
        var isCreateGroupButtonEnabled: Bool {
            generatedCode != nil && !isCreatingGroup
        }
    }

    enum Action {
        case generateCodeButtonTapped
        case generateCodeResponse(Result<String, EquatableError>)
        case shareButtonTapped
        case createGroupButtonTapped
        case createGroupResponse(Result<String, EquatableError>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case groupCreated(groupID: String)
        }
    }

    @Dependency(\.groupClient) var groupClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .generateCodeButtonTapped:
                state.isGeneratingCode = true
                state.errorMessage = nil

                return .run { send in
                    await send(.generateCodeResponse(
                        Result { try await groupClient.createGroup() }
                            .mapError(EquatableError.init)
                    ))
                }

            case let .generateCodeResponse(.success(code)):
                state.isGeneratingCode = false
                state.generatedCode = code
                return .none

            case .generateCodeResponse(.failure):
                state.isGeneratingCode = false
                state.errorMessage = "잠시 후 다시 시도해주세요"
                return .none

            case .shareButtonTapped:
                // 공유 시트(카카오톡/문자/AirDrop)는 View 레이어에서 UIActivityViewController로 처리.
                return .none

            case .createGroupButtonTapped:
                guard let code = state.generatedCode else { return .none }
                state.isCreatingGroup = true
                state.errorMessage = nil

                return .run { send in
                    await send(.createGroupResponse(
                        Result { try await groupClient.enterGroup(enterCode: code) }
                            .mapError(EquatableError.init)
                    ))
                }

            case let .createGroupResponse(.success(groupID)):
                state.isCreatingGroup = false
                return .send(.delegate(.groupCreated(groupID: groupID)))

            case .createGroupResponse(.failure):
                state.isCreatingGroup = false
                state.errorMessage = "잠시 후 다시 시도해주세요"
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
