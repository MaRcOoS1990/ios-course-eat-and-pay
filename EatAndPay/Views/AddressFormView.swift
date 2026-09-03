import SwiftUI
import EatAndPayDesignSystem

struct AddressFormView: View {
    private let address: DeliveryAddress?
    private let addressService: any AddressService
    private let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: AddressDraft
    @State private var isSaving = false
    @State private var alert: UserAlert?

    init(
        address: DeliveryAddress? = nil,
        addressService: any AddressService,
        onSaved: @escaping () -> Void = {}
    ) {
        self.address = address
        self.addressService = addressService
        self.onSaved = onSaved
        _draft = State(initialValue: AddressDraft(address: address))
    }

    var body: some View {
        Form {
            Section("Адрес доставки") {
                TextField("Улица, дом, квартира", text: $draft.addressLine, axis: .vertical)
                    .textContentType(.fullStreetAddress)

                TextField("Подъезд", text: $draft.entrance)
                TextField("Этаж", text: $draft.floor)
                TextField("Домофон", text: $draft.intercomCode)
            }

            Section("Комментарий курьеру") {
                TextField("Например, оставить у двери", text: $draft.comment, axis: .vertical)
            }

            Section {
                TextField("Долгота", text: $draft.longitude)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Широта", text: $draft.latitude)
                    .keyboardType(.numbersAndPunctuation)
            } header: {
                Text("Координаты")
            } footer: {
                Text("Координаты нужны серверу для расчёта доставки. Для нового адреса подставлен центр Москвы.")
            }
        }
        .navigationTitle(address == nil ? "Новый адрес" : "Редактировать")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    Task { await save() }
                }
                .disabled(!draft.isValid || isSaving)
            }
        }
        .disabled(isSaving)
        .overlay {
            if isSaving {
                ProgressView()
                    .padding(AppSpacing.large)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            }
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Понятно"))
            )
        }
    }

    @MainActor
    private func save() async {
        guard draft.isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            if let address {
                try await addressService.updateAddress(id: address.id, draft: draft)
            } else {
                try await addressService.createAddress(draft)
            }
            onSaved()
            dismiss()
        } catch {
            alert = .error(error, title: "Не удалось сохранить адрес")
        }
    }
}
