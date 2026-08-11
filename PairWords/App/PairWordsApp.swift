//
//  PairWordsApp.swift
//  PairWords
//
//  Created by 더스틴 on 8/7/26.
//

import SwiftUI

import ComposableArchitecture

@main
struct PairWordsApp: App {
    
    let store = Store(initialState: DictionaryFeature.State()) {
        DictionaryFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
