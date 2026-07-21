//
//  ProductImageView.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import SwiftUI

struct ProductImageView: View {
    
    let imageURL: URL?
    let size: CGSize
    let cornerRadius: CGFloat
    
    init(
        imageURL: URL?,
        size: CGSize,
        cornerRadius: CGFloat = AppRadius.card
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppColors.screenBackground)
            
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
