import SwiftUI

@Observable
@MainActor
final class ToastManager {
    private(set) var toasts: [ToastMessage] = []
    private var dismissTasks: [UUID: Task<Void, Never>] = [:]

    func show(_ toast: ToastMessage) {
        toasts.append(toast)
        scheduleDismiss(for: toast)
    }

    func show(_ variant: ToastVariant, message: String) {
        show(ToastMessage(variant: variant, message: message))
    }

    func dismiss(_ toast: ToastMessage) {
        dismissTasks[toast.id]?.cancel()
        dismissTasks[toast.id] = nil
        withAnimation(.easeOut(duration: 0.2)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }

    func dismissAll() {
        for (_, task) in dismissTasks {
            task.cancel()
        }
        dismissTasks.removeAll()
        withAnimation {
            toasts.removeAll()
        }
    }

    private func scheduleDismiss(for toast: ToastMessage) {
        let seconds = toast.variant.autoDismissSeconds
        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.dismiss(toast)
        }
        dismissTasks[toast.id] = task
    }
}
