//
//  ReportConversationScreen.swift
//  ios
//

import SwiftUI
import FirebaseAuth

struct ReportConversationScreen: View {
    let report: UserReport
    let viewModel: ReportsViewModel

    @Environment(ToastManager.self) private var toastManager
    @State private var messages: [ReportMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    @State private var isSending = false

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    private var isClosed: Bool {
        report.status == .closed || report.status == .finalized
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesView

            if !isClosed {
                inputBar
            }
        }
        .navigationTitle(report.reportType?.displayName ?? String(localized: "reports.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMessages()
        }
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    if isLoading {
                        AppSpinner()
                            .padding(.top, Spacing.xl)
                    } else if messages.isEmpty {
                        Text(String(localized: "report.conversation.empty"))
                            .font(Typography.footnote)
                            .foregroundStyle(AppColors.grey400)
                            .padding(.top, Spacing.xl)
                    } else {
                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .onChange(of: messages.count) {
                if let lastId = messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func messageBubble(_ message: ReportMessage) -> some View {
        let isUser = message.senderRole == .user

        return HStack {
            if isUser { Spacer(minLength: 50) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Spacing.xxs) {
                Text(message.message)
                    .font(Typography.body)
                    .foregroundStyle(isUser ? .white : AppColors.grey800)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(isUser ? AppColors.primary : AppColors.grey100)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(message.timestamp, style: .time)
                    .font(Typography.bodyTiny)
                    .foregroundStyle(AppColors.grey400)
            }

            if !isUser { Spacer(minLength: 50) }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            VStack(alignment: .trailing, spacing: 2) {
                TextField(String(localized: "report.conversation.placeholder"), text: $newMessage, axis: .vertical)
                    .font(Typography.body)
                    .lineLimit(1...4)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.grey50)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.grey200, lineWidth: 1)
                    )

                Text("\(newMessage.count)/220")
                    .font(Typography.bodyTiny)
                    .foregroundStyle(newMessage.count > 220 ? AppColors.error : AppColors.grey400)
                    .padding(.trailing, Spacing.xs)
            }

            Button {
                sendMessage()
            } label: {
                if isSending {
                    AppSpinner()
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? AppColors.primary : AppColors.grey300)
                }
            }
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(AppColors.background)
    }

    private var canSend: Bool {
        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 220
    }

    private func loadMessages() async {
        guard let reportId = report.id else { return }
        isLoading = true
        do {
            messages = try await viewModel.getMessages(reportId: reportId)
        } catch {
            toastManager.show(.error, message: String(localized: "report.conversation.loadError"))
        }
        isLoading = false
    }

    private func sendMessage() {
        guard let reportId = report.id, let uid = userId else { return }
        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard viewModel.validateMessage(trimmed) == nil else { return }

        isSending = true
        Task {
            do {
                try await viewModel.addMessage(reportId: reportId, senderId: uid, message: trimmed)
                newMessage = ""
                HapticService.lightImpact()
                await loadMessages()
            } catch {
                toastManager.show(.error, message: String(localized: "report.conversation.sendError"))
            }
            isSending = false
        }
    }
}
