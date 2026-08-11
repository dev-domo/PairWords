//
//  DictionaryFeature.swift
//  PairWords
//
//  Created by 더스틴 on 8/10/26.
//

import ComposableArchitecture

@Reducer
struct DictionaryFeature {
    
    @ObservableState
    struct State: Equatable {
        var count = 0
    }
    
    enum Action {
        case addButtonDidTap
    }
    
    var body: Reduce<State, Action> {
        Reduce { state, action in
            switch action {
            case .addButtonDidTap:
                state.count += 1
                return .none
            }
        }
    }
}
