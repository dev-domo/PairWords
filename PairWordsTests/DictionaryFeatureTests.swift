//
//  DictionaryFeatureTests.swift
//  PairWordsTests
//
//  Created by 더스틴 on 8/7/26.
//

import Foundation
import XCTest
@testable import PairWords
import ComposableArchitecture

@MainActor
final class DictionaryFeatureTests: XCTestCase {
    
    private let expectedSlangs = [
        Slang(
            id: nil,
            name: "무댕",
            representativeMeaning: "하마라는 뜻",
            createdBy: "tester",
            createdAt: .now
        )
    ]
    
    // MARK: - onAppear
    
    func testOnAppear_observesSlangs() async {
        let expectedSlangs = self.expectedSlangs
        
        let store = TestStore(
            initialState: DictionaryFeature.State(groupID: "group1")
        ) {
            DictionaryFeature()
        } withDependencies: {
            $0.slangClient.observeSlangs = { groupID in
                return AsyncStream { continuation in
                    continuation.yield(expectedSlangs)
                    continuation.finish()
                }
            }
        }
        
        await store.send(.onAppear)
        
        await store.receive(\.updateSlangs, expectedSlangs) {
            $0.slangs = expectedSlangs
        }
        
        await store.finish()
    }
    
    // MARK: - Search
    
    func testSearchKeywordChanged_emptyKeyword_clearsResults() async {
        let store = TestStore(
            initialState: DictionaryFeature.State(
                groupID: "group1",
                searchResults: self.expectedSlangs
            )
        ) {
            DictionaryFeature()
        }
        
        await store.send(.searchKeywordChanged("")) {
            $0.searchKeyword = ""
            $0.searchResults = []
        }
    }
    
    func testSearchSlangs_success() async {
        let expectedSlangs = self.expectedSlangs
        
        let store = TestStore(
            initialState: DictionaryFeature.State(groupID: "group1")
        ) {
            DictionaryFeature()
        } withDependencies: {
            $0.slangClient.fetchSlang = { groupID, keyword in
                return expectedSlangs
            }
        }
        
        await store.send(.searchKeywordChanged("무")) {
            $0.searchKeyword = "무"
        }
        
        await store.receive { action in
            if case .searchResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.searchResults = expectedSlangs
        }
        
        await store.finish()
    }
    
    func testSearchSlangs_failure() async {
        let store = TestStore(
            initialState: DictionaryFeature.State(groupID: "group1")
        ) {
            DictionaryFeature()
        } withDependencies: {
            $0.slangClient.fetchSlang = { _, _ in
                throw SlangRegistrationError.retryLater
            }
        }
        
        await store.send(.searchKeywordChanged("라")) {
            $0.searchKeyword = "라"
        }
        
        await store.receive { action in
            if case .searchResponse(.failure) = action {
                return true
            }
            return false
        }
        
        await store.finish()
    }
    
    // MARK: - Register
    
    func testRegisterSlangs_success() async {
        let store = TestStore(
            initialState: DictionaryFeature.State(groupID: "group1")
        ) {
            DictionaryFeature()
        } withDependencies: {
            $0.slangClient.createSlang = { _, _, _, _ in
                return
            }
        }
        
        await store.send(
            .registerSlang(
                name: "무댕",
                meaning: "하마라는 뜻",
                audioURL: URL(string: "https://example.com/audio.mp3")!
            )
        )
        
        await store.receive { action in
            if case .registerResponse(.success) = action {
                return true
            }
            return false
        }
        
        await store.finish()
    }
    
    func testRegisterSlangs_failure() async {
        let store = TestStore(
            initialState: DictionaryFeature.State(groupID: "group1")
        ) {
            DictionaryFeature()
        } withDependencies: {
            $0.slangClient.createSlang = { _, _, _, _ in
                throw SlangRegistrationError.retryLater
            }
        }
        
        await store.send(
            .registerSlang(
                name: "무댕",
                meaning: "하마라는 뜻",
                audioURL: URL(string: "https://example.com/audio.mp3")!
            )
        )
        
        await store.receive { action in
            if case .registerResponse(.failure) = action {
                return true
            }
            return false
        } assert: {
            $0.errorMessage = "잠시 후 다시 시도해주세요"
        }
        
        await store.finish()
    }
}
