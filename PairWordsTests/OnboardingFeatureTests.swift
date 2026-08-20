//
//  OnboardingFeatureTests.swift
//  PairWordsTests
//

import Foundation
import XCTest
@testable import PairWords
import ComposableArchitecture

@MainActor
final class OnboardingFeatureTests: XCTestCase {

    func testEnterCodeChanged() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.enterCodeChanged("AB12CD")) {
            $0.enterCode = "AB12CD"
        }
    }

    func testJoinGroup_success() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(enterCode: "AB12CD")
        ) {
            OnboardingFeature()
        } withDependencies: {
            $0.groupClient.enterGroup = { enterCode in
                XCTAssertEqual(enterCode, "AB12CD")
                return "group1"
            }
        }

        await store.send(.joinGroupButtonTapped) {
            $0.isJoining = true
        }

        await store.receive { action in
            if case .joinGroupResponse(.success) = action {
                return true
            }
            return false
        } assert: {
            $0.isJoining = false
        }

        await store.receive(\.delegate, .groupEntered(groupID: "group1"))
    }

    func testJoinGroup_failure() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(enterCode: "WRONG1")
        ) {
            OnboardingFeature()
        } withDependencies: {
            $0.groupClient.enterGroup = { _ in
                throw GroupError.notFound
            }
        }

        await store.send(.joinGroupButtonTapped) {
            $0.isJoining = true
        }

        await store.receive { action in
            if case .joinGroupResponse(.failure) = action {
                return true
            }
            return false
        } assert: {
            $0.isJoining = false
            $0.errorMessage = "입장코드를 다시 확인해주세요"
        }
    }

    func testJoinGroup_emptyCode_doesNothing() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.joinGroupButtonTapped)
    }

    func testCreateGroupButtonTapped_presentsDestination() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.createGroupButtonTapped) {
            $0.destination = .createGroup(CreateGroupFeature.State())
        }
    }

    func testCreateGroupFinished_dismissesAndDelegates() async {
        let store = TestStore(
            initialState: OnboardingFeature.State(
                destination: .createGroup(CreateGroupFeature.State(generatedCode: "AB12CD"))
            )
        ) {
            OnboardingFeature()
        }

        await store.send(.destination(.presented(.createGroup(.delegate(.groupCreated(groupID: "group1")))))) {
            $0.destination = nil
        }

        await store.receive(\.delegate, .groupEntered(groupID: "group1"))
    }
}
