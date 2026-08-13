import SwiftUI

public struct ProductImageView: View {
    private let imageURL: URL?
    private let size: CGSize
    private let cornerRadius: CGFloat

    public init(
        imageURL: URL?,
        size: CGSize,
        cornerRadius: CGFloat = AppRadius.card
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
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
                            .scaledToFill()
                            .frame(width: size.width, height: size.height)
                            .clipped()

                    case .failure:
                        placeholderImage

                    @unknown default:
                        placeholderImage
                    }
                }
                .id(imageURL)
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
            .padding(AppSpacing.extraLarge)
    }
}
