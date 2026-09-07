import SwiftUI
import EatAndPayDesignSystem

struct ProfileEditView: View {
    let service: any ProfileService
    let onUpdated: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: UserProfileDraft
    @State private var isSaving = false
    @State private var alert: UserAlert?

    init(
        profile: UserProfile,
        service: any ProfileService,
        onUpdated: @escaping () async -> Void
    ) {
        self.service = service
        self.onUpdated = onUpdated
        _draft = State(initialValue: profile.draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Имя", text: $draft.name)
                        .textContentType(.name)
                        .accessibilityIdentifier("profile.name")

                    TextField("Дата рождения", text: $draft.birthday)
                        .textContentType(.birthdate)
                        .keyboardType(.numbersAndPunctuation)
                        .accessibilityIdentifier("profile.birthday")
                } header: {
                    Text("Личные данные")
                } footer: {
                    Text("Дата рождения — в формате ДД.ММ.ГГГГ.")
                }

                Section {
                    TextField("https://example.com/avatar.jxl", text: $draft.imageURI)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("profile.imageURI")
                } header: {
                    Text("Фотография")
                } footer: {
                    Text("Сервер принимает ссылку на изображение в формате JXL.")
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }

                        Text(isSaving ? "Сохраняем..." : "Сохранить")
                    }
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(!draft.isValid || isSaving)
                .padding(AppSpacing.medium)
                .background(.regularMaterial)
                .accessibilityIdentifier("profile.save")
            }
            .interactiveDismissDisabled(isSaving)
            .alert(item: $alert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("Понятно"))
                )
            }
        }
    }

    @MainActor
    private func save() async {
        guard draft.isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try await service.updateProfile(draft)
            await onUpdated()
            dismiss()
        } catch {
            alert = .error(error, title: "Не удалось обновить профиль")
        }
    }
}
