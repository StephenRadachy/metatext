// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class NotificationTypesPreferencesViewModel: ObservableObject {
    @Published public var pushSubscriptionAlerts: PushSubscription.Alerts
    @Published public var alertItem: AlertItem?

    private let environment: IdentifiedEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        pushSubscriptionAlerts = environment.identity.pushSubscriptionAlerts

        environment.$identity
            .map(\.pushSubscriptionAlerts)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$pushSubscriptionAlerts)

        $pushSubscriptionAlerts
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] in self?.update(alerts: $0) }
            .store(in: &cancellables)
    }
}

private extension NotificationTypesPreferencesViewModel {
    func update(alerts: PushSubscription.Alerts) {
        guard alerts != environment.identity.pushSubscriptionAlerts else { return }

        environment.identityService.updatePushSubscription(alerts: alerts)
            .sink { [weak self] in
                guard let self = self, case let .failure(error) = $0 else { return }

                self.alertItem = AlertItem(error: error)
                self.pushSubscriptionAlerts = self.environment.identity.pushSubscriptionAlerts
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
