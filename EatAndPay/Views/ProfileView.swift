import SwiftUI
import EatAndPayDesignSystem

struct ProfileView: View {
    let profileService: any ProfileService
    let orderService: any OrderService
    let addressService: any AddressService

    @State private var profile: UserProfile?
    @State private var isLoading = false
    @State private var didLoad = false
    @State private var showsEditor = false
    @State private var alert: UserAlert?

    var body: some View {
        Group {
            if isLoading && !didLoad {
                ProgressView("Загрузка профиля...")
            } else if let profile {
                profileContent(profile)
            } else {
                ContentUnavailableView {
                    Label("Профиль недоступен", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("Не удалось получить данные пользователя")
                } actions: {
                    Button("Повторить") {
                        Task { await loadProfile() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .background(AppColors.screenBackground)
        .navigationTitle("Профиль")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Изменить") {
                    showsEditor = true
                }
                .disabled(profile == nil || isLoading)
            }
        }
        .task {
            if !didLoad {
                await loadProfile()
            }
        }
        .sheet(isPresented: $showsEditor) {
            if let profile {
                ProfileEditView(profile: profile, service: profileService) {
                    await loadProfile()
                }
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

    private func profileContent(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.extraLarge) {
                profileCard(profile)
                navigationSection
            }
            .padding(AppSpacing.large)
        }
        .refreshable {
            await loadProfile()
        }
    }

    private func profileCard(_ profile: UserProfile) -> some View {
        VStack(spacing: AppSpacing.large) {
            ProductImageView(
                imageURL: profile.imageURL,
                size: CGSize(width: 112, height: 112),
                cornerRadius: 56,
                contentMode: .fill,
                allowsRetry: true,
                placeholderSystemImage: "person.crop.circle.fill"
            )
            .accessibilityLabel("Фотография пользователя")

            VStack(spacing: AppSpacing.small) {
                Text(profile.name.nilIfBlank ?? "Имя не указано")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.primaryText)

                if let phone = profile.phone.nilIfBlank {
                    Label(phone, systemImage: "phone")
                }

                Label(
                    profile.birthday.nilIfBlank ?? "Дата рождения не указана",
                    systemImage: "birthday.cake"
                )
            }
            .font(.subheadline)
            .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.extraLarge)
        .background(AppGradients.smoky)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .contentTransition(.opacity)
    }

    private var navigationSection: some View {
        VStack(spacing: AppSpacing.medium) {
            NavigationLink {
                OrderListView(orderService: orderService)
            } label: {
                navigationRow(
                    title: "Мои заказы",
                    subtitle: "Статусы, состав и стоимость",
                    systemImage: "shippingbox"
                )
            }

            NavigationLink {
                AddressListView(addressService: addressService)
            } label: {
                navigationRow(
                    title: "Мои адреса",
                    subtitle: "Адреса для доставки",
                    systemImage: "mappin.and.ellipse"
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func navigationRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: AppSpacing.large) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AppColors.favoriteActive)
                .frame(width: 36, height: 36)
                .background(AppGradients.smoky)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.smallCard))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(AppSpacing.large)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .shadow(
            color: AppShadow.cardColor,
            radius: AppShadow.cardRadius,
            x: AppShadow.cardX,
            y: AppShadow.cardY
        )
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }

    @MainActor
    private func loadProfile() async {
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            didLoad = true
        }

        do {
            let loadedProfile = try await profileService.loadProfile()
            withAnimation(AppMotion.standard) {
                profile = loadedProfile
            }
        } catch {
            alert = .error(error, title: "Не удалось загрузить профиль")
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
