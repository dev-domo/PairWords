//
//  SettingsFeatureTests.swift
//  PairWordsTests
//

import Foundation
import XCTest
@testable import PairWords
import ComposableArchitecture

@MainActor
final class SettingsFeatureTests: XCTestCase {

    private func makeState() -> SettingsFeature.State {
        SettingsFeature.State(groupID: "group1", currentCode: "AB12CD")
    }

    // MARK: - 코드 재생성

    func testRegenerateCode_success() async {
        let store = TestStore(initialState: makeState()) {
            SettingsFeature()
        } withDependencies: {
            $0.groupClient.createGroup = { "ZZ99YY" }
        }

        await store.send(.regenerateCodeButtonTapped) {
            $0.isRegeneratingCode = true
        }

        await store.receive { action in
            if case .regenerateCodeResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.isRegeneratingCode = false
            $0.currentCode = "ZZ99YY"
        }
    }

    func testRegenerateCode_failure() async {
        let store = TestStore(initialState: makeState()) {
            SettingsFeature()
        } withDependencies: {
            $0.groupClient.createGroup = {
                throw GroupError.codeGenerationFailed
            }
        }

        await store.send(.regenerateCodeButtonTapped) {
            $0.isRegeneratingCode = true
        }

        await store.receive { action in
            if case .regenerateCodeResponse(.failure) = action {
                return true
            }
            return false
        } assert: {
            $0.isRegeneratingCode = false
            $0.errorMessage = "잠시 후 다시 시도해주세요"
        }
    }

    // MARK: - 그룹 탈퇴

    func testWithdrawFlow_presentsConfirmationThenCancels() async {
        let store = TestStore(initialState: makeState()) {
            SettingsFeature()
        }

        await store.send(.withdrawButtonTapped) {
            $0.isWithdrawConfirmationPresented = true
        }

        await store.send(.cancelWithdrawButtonTapped) {
            $0.isWithdrawConfirmationPresented = false
        }
    }

    func testWithdraw_success_delegatesDidWithdraw() async {
        var state = makeState()
        state.isWithdrawConfirmationPresented = true

        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.groupClient.withdrawGroup = { groupID in
                XCTAssertEqual(groupID, "group1")
            }
        }

        await store.send(.confirmWithdrawButtonTapped) {
            $0.isWithdrawing = true
        }

        await store.receive { action in
            if case .withdrawResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.isWithdrawing = false
            $0.isWithdrawConfirmationPresented = false
        }

        await store.receive(\.delegate, .didWithdraw)
    }

    func testWithdraw_failure() async {
        var state = makeState()
        state.isWithdrawConfirmationPresented = true

        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.groupClient.withdrawGroup = { _ in
                throw GroupError.notFound
            }
        }

        await store.send(.confirmWithdrawButtonTapped) {
            $0.isWithdrawing = true
        }

        await store.receive { action in
            if case .withdrawResponse(.failure) = action {
                return true
            }
            return false
        } assert: {
            $0.isWithdrawing = false
            $0.errorMessage = "잠시 후 다시 시도해주세요"
        }
    }
}
