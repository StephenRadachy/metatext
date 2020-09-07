// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public class EditFilterViewModel: ObservableObject {
    @Published public var filter: Filter
    @Published public var saving = false
    @Published public var alertItem: AlertItem?
    public let saveCompleted: AnyPublisher<Void, Never>

    public var date: Date {
        didSet { filter.expiresAt = date }
    }

    private let environment: IdentifiedEnvironment
    private let saveCompletedInput = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(filter: Filter, environment: IdentifiedEnvironment) {
        self.filter = filter
        self.environment = environment
        date = filter.expiresAt ?? Date()
        saveCompleted = saveCompletedInput.eraseToAnyPublisher()
    }
}

public extension EditFilterViewModel {
    var isNew: Bool { filter.id == Filter.newFilterID }

    var isSaveDisabled: Bool { filter.phrase == "" || filter.context.isEmpty }

    func toggleSelection(context: Filter.Context) {
        if filter.context.contains(context) {
            filter.context.removeAll { $0 == context }
        } else {
            filter.context.append(context)
        }
    }

    func save() {
        (isNew ? environment.identityService.createFilter(filter) : environment.identityService.updateFilter(filter))
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.saving = true },
                receiveCompletion: { [weak self] in
                    guard let self = self else { return }

                    self.saving = false

                    if case .finished = $0 {
                        self.saveCompletedInput.send(())
                    }
                })
            .sink { _ in }
            .store(in: &cancellables)
    }
}
