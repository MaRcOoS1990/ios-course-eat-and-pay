import SwiftUI
import EatAndPayDesignSystem

struct AddressListView: View {
    let addressService: any AddressService

    @State private var addresses: [DeliveryAddress] = []
    @State private var isLoading = false
    @State private var didLoad = false
    @State private var alert: UserAlert?

    var body: some View {
        Group {
            if isLoading && !didLoad {
                ProgressView("Загрузка адресов...")
            } else if addresses.isEmpty {
                ContentUnavailableView {
                    Label("Адресов пока нет", systemImage: "mappin.and.ellipse")
                } description: {
                    Text("Добавь адрес, чтобы оформить заказ")
                } actions: {
                    NavigationLink("Добавить адрес") {
                        AddressFormView(addressService: addressService)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(addresses) { address in
                        NavigationLink {
                            AddressFormView(address: address, addressService: addressService)
                        } label: {
                            addressRow(address)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await delete(address) }
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadAddresses()
                }
            }
        }
        .navigationTitle("Мои адреса")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddressFormView(addressService: addressService)
                } label: {
                    Label("Добавить адрес", systemImage: "plus")
                }
            }
        }
        .onAppear {
            Task { await loadAddresses() }
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Понятно"))
            )
        }
    }

    private func addressRow(_ address: DeliveryAddress) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(address.addressLine)
                .font(.headline)

            let details = [
                address.entrance.isEmpty ? nil : "подъезд \(address.entrance)",
                address.floor.isEmpty ? nil : "этаж \(address.floor)"
            ].compactMap { $0 }.joined(separator: ", ")

            if !details.isEmpty {
                Text(details)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.vertical, AppSpacing.small)
    }

    @MainActor
    private func loadAddresses() async {
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            didLoad = true
        }

        do {
            addresses = try await addressService.loadAddresses()
        } catch {
            alert = .error(error, title: "Не удалось загрузить адреса")
        }
    }

    @MainActor
    private func delete(_ address: DeliveryAddress) async {
        do {
            try await addressService.deleteAddress(id: address.id)
            addresses.removeAll { $0.id == address.id }
        } catch {
            alert = .error(error, title: "Не удалось удалить адрес")
        }
    }
}
