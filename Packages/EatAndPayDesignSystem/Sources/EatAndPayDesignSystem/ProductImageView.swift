import SwiftUI

public struct ProductImageView: View {
    private let imageURL: URL?
    private let size: CGSize
    private let cornerRadius: CGFloat
    private let contentMode: ContentMode
    private let allowsRetry: Bool
    @State private var reloadID = UUID()

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

            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()

                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .frame(width: size.width, height: size.height)
                            .clipped()

                    case .failure:
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

                    @unknown default:
                        placeholderImage
                    }
                }
                .id("\(imageURL.absoluteString)-\(reloadID)")
            } else {
                placeholderImage
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholderImage: some View {
        Image(systemName: "cart")
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppColors.accent)
            .padding(min(size.width, size.height) / 4)
    }
}
