import SwiftUI
import EatAndPayDesignSystem

struct ReviewFormView: View {
    let product: Product
    let service: any ReviewService
    let onSubmitted: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var state = ReviewFormState()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(product.name).font(.headline)
                    HStack(spacing: AppSpacing.small) {
                        ForEach(1...5, id: \.self) { rating in
                            Button {
                                state.draft.rating = rating
                            } label: {
                                Image(systemName: rating <= state.draft.rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(AppColors.accent)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Оценка \(rating)")
                            .accessibilityIdentifier("review.rating.\(rating)")
                            .accessibilityValue(state.draft.rating == rating ? "Выбрано" : "")
                        }
                    }
                } header: { Text("Оценка") }
                Section {
                    TextEditor(text: $state.draft.text)
                        .frame(minHeight: 140)
                        .accessibilityLabel("Текст отзыва")
                        .accessibilityIdentifier("review.text")
                } header: { Text("Комментарий") }
                  footer: { Text("Отзыв будет публичным и появится под твоим именем.") }

                if let message = state.errorMessage {
                    Text(message).foregroundStyle(AppColors.errorText)
                }
                Section {
                    Button {
                        Task {
                            if await state.submit(productID: product.id, using: service) {
                                await onSubmitted()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if state.isSubmitting || state.didSubmit { ProgressView() }
                            Text(state.didSubmit ? "Обновляем товар…" : "Отправить отзыв")
                            Spacer()
                        }
                    }
                    .disabled(!state.canSubmit)
                    .accessibilityIdentifier("review.submit")
                }
            }
            .disabled(state.isSubmitting || state.didSubmit)
            .navigationTitle("Отзыв о товаре")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .disabled(state.isSubmitting || state.didSubmit)
                }
            }
            .interactiveDismissDisabled(state.isSubmitting || state.didSubmit)
        }
    }
}
