//
//  DictionaryFeature.swift
//  PairWords
//
//  Created by 더스틴 on 8/10/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct DictionaryFeature {
    
    @ObservableState
    struct State: Equatable {
        var groupID: String
        var slangs: [Slang] = []
        var searchKeyword: String = ""
        var searchResults: [Slang] = []
        var errorMessage: String?
    }
    
    enum Action {
        case onAppear
        case updateSlangs([Slang])
        case searchKeywordChanged(String)
        case searchResponse(Result<[Slang], EquatableError>)
        case registerSlang(name: String, meaning: String, audioURL: URL)
        case registerResponse(Result<Void, EquatableError>)
    }
    
    @Dependency(\.slangClient) var slangClient
    
    var body: Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let groupID = state.groupID
                
                return .run { send in
                    let stream = try await slangClient.observeSlangs(groupID: groupID)
                    for await slangs in stream {
                        await send(.updateSlangs(slangs))
                    }
                }
                
            case let .updateSlangs(slangs):
                state.slangs = slangs
                return .none
                
            case let .searchKeywordChanged(keyword):
                state.searchKeyword = keyword
                guard !keyword.isEmpty else {
                    state.searchResults = []
                    return .none
                }
                
                let groupID = state.groupID
                
                return .run { send in
                    do {
                        let slangs = try await slangClient.fetchSlang(groupID: groupID, keyword: keyword)
                        await send(.searchResponse(.success(slangs)))
                    } catch {
                        await send(.searchResponse(.failure(.init(error))))
                    }
                }
                
            case let .searchResponse(result):
                switch result {
                case let .success(slangs):
                    state.searchResults = slangs
                case .failure:
                    state.searchResults = []
                }
                return .none
                
            case let .registerSlang(name, meaning, audioURL):
                let groupID = state.groupID
                
                return .run { send in
                    do {
                        try await slangClient.createSlang(
                            groupID: groupID,
                            name: name,
                            meaning: meaning,
                            audioURL: audioURL
                        )

                        await send(.registerResponse(.success(())))
                    } catch {
                        await send(.registerResponse(.failure(.init(error))))
                    }
                }
                
            case .registerResponse(.success):
                state.errorMessage = nil
                return .none
                
            case .registerResponse(.failure):
                state.errorMessage = "잠시 후 다시 시도해주세요"
                return .none
            }
        }
    }
}
