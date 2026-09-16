import Testing
@testable import GogoAppSupport

private actor FakePermissionService: PermissionService {
    var prompts: [Bool] = []
    var result: AutomationAccess = .notRequested
    var pending: CheckedContinuation<AutomationAccess, Never>?
    var started: CheckedContinuation<Void, Never>?
    var pause = false

    func automation(request: Bool) async -> AutomationAccess {
        prompts.append(request)
        guard pause else { return result }
        pause = false
        return await withCheckedContinuation { continuation in
            pending = continuation
            started?.resume(); started = nil
        }
    }
    func setResult(_ value: AutomationAccess, pauseNext: Bool = false) { result = value; pause = pauseNext }
    func waitForQuery() async {
        if pending != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func finishQuery() { pending?.resume(returning: result); pending = nil }
}

@Test @MainActor func refreshOnlyQueriesAutomationWithoutRequestingConsent() async {
    let service = FakePermissionService()
    let model = PermissionsModel(preview: false, service: service)
    await model.refresh()
    #expect(await service.prompts == [false])
    #expect(model.automation == .notRequested)
    await service.setResult(.allowed)
    await model.requestAutomation()
    #expect(await service.prompts == [false, true])
    #expect(model.automation == .allowed)
    #expect(!model.busy)
}

@Test @MainActor func permissionsPreviewHasNoSystemSideEffects() async {
    let service = FakePermissionService()
    let model = PermissionsModel(preview: true, service: service)
    await model.refresh()
    await model.requestAutomation()
    #expect(await service.prompts.isEmpty)
}

@Test @MainActor func pendingAutomationRequestPreventsDuplicatePrompts() async {
    let service = FakePermissionService()
    await service.setResult(.allowed, pauseNext: true)
    let model = PermissionsModel(preview: false, service: service)
    let first = Task { await model.requestAutomation() }
    await service.waitForQuery()
    #expect(model.busy)
    await model.requestAutomation()
    await model.refresh()
    #expect(await service.prompts == [true])
    await service.finishQuery()
    await first.value
    #expect(!model.busy)
    #expect(model.automation == .allowed)
}

@Test @MainActor func automationRefreshReplacesOldAuthorizationAndReopeningStartsUnknown() async {
    let service = FakePermissionService()
    await service.setResult(.allowed)
    let model = PermissionsModel(preview: false, service: service)
    await model.refresh()
    #expect(model.automation == .allowed)
    await service.setResult(.denied, pauseNext: true)
    let refresh = Task { await model.refresh() }
    await service.waitForQuery()
    #expect(model.automation == .unknown)
    await service.finishQuery()
    await refresh.value
    #expect(model.automation == .denied)
    let reopened = PermissionsModel(preview: false, service: service)
    #expect(reopened.automation == .unknown)
    await reopened.refresh()
    #expect(reopened.automation == .denied)
    #expect(await service.prompts == [false, false, false])
}
