// Copyright © 2020 Metabolist. All rights reserved.

import XCTest
import Combine
import CombineExpectations
@testable import Metatext

class AddIdentityViewModelTests: XCTestCase {
    func testAddIdentity() throws {
        let environment = AppEnvironment.fresh()
        let sut = AddIdentityViewModel(networkClient: MastodonClient.fresh(), environment: environment)
        let addedIDRecorder = sut.$addedIdentityID.record()
        XCTAssertNil(try wait(for: addedIDRecorder.next(), timeout: 1))

        sut.urlFieldText = "https://mastodon.social"
        sut.goTapped()

        let addedIdentityID = try wait(for: addedIDRecorder.next(), timeout: 1)!
        let identityRecorder = environment.identityDatabase.identityObservation(id: addedIdentityID).record()
        let addedIdentity = try wait(for: identityRecorder.next(), timeout: 1)!

        XCTAssertEqual(addedIdentity.id, addedIdentityID)
        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)
        XCTAssertEqual(environment.preferences[.recentIdentityID], addedIdentity.id)
        XCTAssertEqual(
            try environment.secrets.item(.clientID, forIdentityID: addedIdentityID) as String?,
            "AUTHORIZATION_CLIENT_ID_STUB_VALUE")
        XCTAssertEqual(
            try environment.secrets.item(.clientSecret, forIdentityID: addedIdentityID) as String?,
            "AUTHORIZATION_CLIENT_SECRET_STUB_VALUE")
        XCTAssertEqual(
            try environment.secrets.item(.accessToken, forIdentityID: addedIdentityID) as String?,
            "ACCESS_TOKEN_STUB_VALUE")
    }

    func testAddIdentityWithoutScheme() throws {
        let environment = AppEnvironment.fresh()
        let sut = AddIdentityViewModel(networkClient: MastodonClient.fresh(), environment: environment)
        let addedIDRecorder = sut.$addedIdentityID.record()
        XCTAssertNil(try wait(for: addedIDRecorder.next(), timeout: 1))

        sut.urlFieldText = "mastodon.social"
        sut.goTapped()

        let addedIdentityID = try wait(for: addedIDRecorder.next(), timeout: 1)!
        let identityRecorder = environment.identityDatabase.identityObservation(id: addedIdentityID).record()
        let addedIdentity = try wait(for: identityRecorder.next(), timeout: 1)!

        XCTAssertEqual(addedIdentity.url, URL(string: "https://mastodon.social")!)
    }

    func testInvalidURL() throws {
        let sut = AddIdentityViewModel(networkClient: MastodonClient.fresh(), environment: .fresh())
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "🐘.social"
        sut.goTapped()

        let alertItem = try wait(for: recorder.next(), timeout: 1)

        XCTAssertEqual((alertItem?.error as? URLError)?.code, URLError.badURL)
    }

    func testDoesNotAlertCanceledLogin() throws {
        let environment = AppEnvironment.fresh(webAuthSessionType: CanceledLoginStubbingWebAuthSession.self)
        let sut = AddIdentityViewModel(networkClient: MastodonClient.fresh(), environment: environment)
        let recorder = sut.$alertItem.record()

        XCTAssertNil(try wait(for: recorder.next(), timeout: 1))

        sut.urlFieldText = "https://mastodon.social"
        sut.goTapped()

        try wait(for: recorder.next().inverted, timeout: 1)
    }
}
