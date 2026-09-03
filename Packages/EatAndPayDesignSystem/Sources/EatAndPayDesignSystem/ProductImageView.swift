import SwiftUI
import UIKit

public struct ProductImageView: View {
    private let imageURL: URL?
    private let size: CGSize
    private let cornerRadius: CGFloat
    private let contentMode: ContentMode
    private let allowsRetry: Bool

    @State private var reloadID = UUID()
    @State private var state: LoadingState = .idle

    public init(
        imageURL: URL?,
        size: CGSize,
        cornerRadius: CGFloat = AppRadius.card,
        contentMode: ContentMode = .fill,
        allowsRetry: Bool = false
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
        self.contentMode = contentMode
        self.allowsRetry = allowsRetry
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppColors.imageBackground)

            switch state {
            case .idle:
                placeholderImage

            case .loading:
                ProgressView()

            case .success(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: size.width, height: size.height)
                    .clipped()

            case .failure:
                failureView
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: TaskID(url: imageURL, reloadID: reloadID)) {
            await loadImage()
        }
    }

    @ViewBuilder
    private var failureView: some View {
        if allowsRetry {
            Button {
                reloadID = UUID()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: size.width, height: size.height)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Повторить загрузку фотографии")
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "cart")
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppColors.accent)
            .padding(min(size.width, size.height) / 4)
    }

    @MainActor
    private func loadImage() async {
        guard let imageURL else {
            state = .idle
            return
        }

        state = .loading

        do {
            let data = try await ProductImageLoader.shared.data(for: imageURL)
            try Task.checkCancellation()

            guard let image = UIImage(data: data) else {
                await ProductImageLoader.shared.removeData(for: imageURL)
                state = .failure
                return
            }

            state = .success(image)
        } catch is CancellationError {
            return
        } catch {
            state = .failure
        }
    }
}

private extension ProductImageView {
    struct TaskID: Hashable {
        let url: URL?
        let reloadID: UUID
    }

    enum LoadingState {
        case idle
        case loading
        case success(UIImage)
        case failure
    }
}
