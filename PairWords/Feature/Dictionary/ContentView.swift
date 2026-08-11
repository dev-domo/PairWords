//
//  ContentView.swift
//  PairWords
//
//  Created by 더스틴 on 8/7/26.
//

import SwiftUI

import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<DictionaryFeature>
    
    var body: some View {
        VStack {
            Text("\(store.count)")
                        
            Button {
                store.send(.addButtonDidTap)
            } label: {
                Text("단어 추가하기")
            }
        }
        .padding()
    }
}
