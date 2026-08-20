//
//  OnboardingFeature.swift
//  PairWords
//
//  01_최초화면: <새 그룹 만들기> / <입장코드를 입력하세요>
//

import Foundation
import ComposableArchitecture

@Reducer
struct OnboardingFeature {

    @Reducer
    enum Destination {
        case createGroup(CreateGroupFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        var enterCode: String = ""
        var isJoining: Bool = false
        var errorMessage: String?
        @Presents var destination: Destination.State?
    }

    enum Action {
        case enterCodeChanged(String)
        case joinGroupButtonTapped
        case joinGroupResponse(Result<String, EquatableError>)
        case createGroupButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case groupEntered(groupID: String)
        }
    }

    @Dependency(\.groupClient) var groupClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .enterCodeChanged(code):
                state.enterCode = code
                state.errorMessage = nil
                return .none

            case .joinGroupButtonTapped:
                guard !state.enterCode.isEmpty else { return .none }
                state.isJoining = true
                state.errorMessage = nil
                let code = state.enterCode

                return .run { send in
                    await send(.joinGroupResponse(
                        Result { try await groupClient.enterGroup(enterCode: code) }
                            .mapError(EquatableError.init)
                    ))
                }

            case let .joinGroupResponse(.success(groupID)):
                state.isJoining = false
                return .send(.delegate(.groupEntered(groupID: groupID)))

            case .joinGroupResponse(.failure):
                state.isJoining = false
                state.errorMessage = "입장코드를 다시 확인해주세요"
                return .none

            case .createGroupButtonTapped:
                state.destination = .createGroup(CreateGroupFeature.State())
                return .none

            case .destination(.presented(.createGroup(.delegate(.groupCreated(let groupID))))):
                state.destination = nil
                return .send(.delegate(.groupEntered(groupID: groupID)))

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension OnboardingFeature.Destination.State: Equatable {}

