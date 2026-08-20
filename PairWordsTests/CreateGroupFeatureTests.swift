//
//  CreateGroupFeatureTests.swift
//  PairWordsTests
//

import Foundation
import XCTest
@testable import PairWords
import ComposableArchitecture

@MainActor
final class CreateGroupFeatureTests: XCTestCase {

    func testGenerateCode_success() async {
        let store = TestStore(initialState: CreateGroupFeature.State()) {
            CreateGroupFeature()
        } withDependencies: {
            $0.groupClient.createGroup = { "AB12CD" }
        }

        await store.send(.generateCodeButtonTapped) {
            $0.isGeneratingCode = true
        }

        await store.receive { action in
            if case .generateCodeResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.isGeneratingCode = false
            $0.generatedCode = "AB12CD"
        }

        XCTAssertTrue(store.state.isCreateGroupButtonEnabled)
    }

    func testGenerateCode_failure() async {
        let store = TestStore(initialState: CreateGroupFeature.State()) {
            CreateGroupFeature()
        } withDependencies: {
            $0.groupClient.createGroup = {
                throw GroupError.codeGenerationFailed
            }
        }

        await store.send(.generateCodeButtonTapped) {
            $0.isGeneratingCode = true
        }

        await store.receive { action in
            if case .generateCodeResponse(.failure) = action {
                return true
            }
            return false
        } assert: {
            $0.isGeneratingCode = false
            $0.errorMessage = "잠시 후 다시 시도해주세요"
        }

        XCTAssertFalse(store.state.isCreateGroupButtonEnabled)
    }

    func testCreateGroupButtonDisabled_untilCodeGenerated() {
        let state = CreateGroupFeature.State()
        XCTAssertFalse(state.isCreateGroupButtonEnabled)
    }

    func testCreateGroup_success_delegatesGroupCreated() async {
        let store = TestStore(
            initialState: CreateGroupFeature.State(generatedCode: "AB12CD")
        ) {
            CreateGroupFeature()
        } withDependencies: {
            $0.groupClient.enterGroup = { code in
                XCTAssertEqual(code, "AB12CD")
                return "group1"
            }
        }

        await store.send(.createGroupButtonTapped) {
            $0.isCreatingGroup = true
        }

        await store.receive { action in
            if case .createGroupResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.isCreatingGroup = false
        }

        await store.receive(\.delegate, .groupCreated(groupID: "group1"))
    }

    func testCreateGroup_withoutGeneratedCode_doesNothing() async {
        let store = TestStore(initialState: CreateGroupFeature.State()) {
            CreateGroupFeature()
        }

        await store.send(.createGroupButtonTapped)
    }
}
