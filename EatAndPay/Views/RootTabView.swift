//
//  RootTabView.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 21.07.2026.
//

import SwiftUI
import EatAndPayDesignSystem

struct RootTabView: View {
    
    private let catalogService: any CatalogService
    private let categoryService: any CategoryService
    private let favoriteService: any FavoriteService
    private let cartStore: CartStore
    private let productDetailService: any ProductDetailService
    private let addressService: any AddressService
    private let orderService: any OrderService
    private let cartPersistence: any CartPersistence
    
    @State private var products: [Product] = []
    @State private var cart = Cart()
    @State private var favorites = Favorites()
    @State private var deliveryPrice = Decimal.zero
    @State private var didRestoreCart = false
    @State private var showsCheckout = false
    @State private var isSynchronizingCart = false
    @State private var pendingCartOperations = 0
    @State private var alert: UserAlert?
    
    init(
        catalogService: any CatalogService,
        categoryService: any CategoryService,
        favoriteService: any FavoriteService,
        cartStore: CartStore,
        productDetailService: any ProductDetailService,
        addressService: any AddressService,
        orderService: any OrderService,
        cartPersistence: any CartPersistence
    ) {
        self.catalogService = catalogService
        self.categoryService = categoryService
        self.favoriteService = favoriteService
        self.cartStore = cartStore
        self.productDetailService = productDetailService
        self.addressService = addressService
        self.orderService = orderService
        self.cartPersistence = cartPersistence
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                ProductListView(
                    catalogService: catalogService,
                    productDetailService: productDetailService,
                    favoriteService: favoriteService,
                    updatedProducts: products,
                    cart: $cart,
                    favorites: $favorites,
                    onProductsLoaded: { loadedProducts in
                        mergeProducts(loadedProducts)
                    },
                    onProductUpdated: updateProduct,
                    onAddToCart: addToCart,
                    onRemoveFromCart: removeFromCart
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            CategoryListView(
                                categoryService: categoryService,
                                catalogService: catalogService,
                                productDetailService: productDetailService,
                                favoriteService: favoriteService,
                                updatedProducts: products,
                                cart: $cart,
                                favorites: $favorites,
                                onProductsLoaded: { loadedProducts in
                                    mergeProducts(loadedProducts)
                                },
                                onProductUpdated: updateProduct,
                                onAddToCart: addToCart,
                                onRemoveFromCart: removeFromCart
                            )
                        } label: {
                            Label("Категории", systemImage: "square.grid.3x3")
                        }
                    }
                }
            }
            .tabItem {
                Label("Каталог", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                FavoriteListView(
                    products: products,
                    productDetailService: productDetailService,
                    favoriteService: favoriteService,
                    cart: $cart,
                    favorites: $favorites,
                    onProductUpdated: updateProduct,
                    onAddToCart: addToCart,
                    onRemoveFromCart: removeFromCart
                )
            }
            .tabItem {
                Label("Избранное", systemImage: "heart.fill")
            }
            .badge(favorites.count)
            
            NavigationStack {
                CartView(
                    products: products,
                    cart: cart,
                    deliveryPrice: deliveryPrice,
                    isLoading: isSynchronizingCart,
                    onAddToCart: { product in
                        addToCart(product)
                    },
                    onRemoveFromCart: { product in
                        removeFromCart(product)
                    },
                    onCheckout: {
                        showsCheckout = true
                    }
                )
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        NavigationLink {
                            OrderListView(orderService: orderService)
                        } label: {
                            Label("Заказы", systemImage: "shippingbox")
                        }

                        NavigationLink {
                            AddressListView(addressService: addressService)
                        } label: {
                            Label("Мои адреса", systemImage: "mappin.and.ellipse")
                        }
                    }
                }
                .sheet(isPresented: $showsCheckout) {
                    NavigationStack {
                        CheckoutView(
                            products: products,
                            cart: cart,
                            deliveryPrice: deliveryPrice,
                            addressService: addressService,
                            orderService: orderService,
                            onOrderCompleted: completeOrder
                        )
                    }
                }
            }
            .tabItem {
                Label("Корзина", systemImage: "cart")
            }
            .badge(cartItemsCount)
        }
        .overlay {
            if pendingCartOperations > 0 {
                ProgressView("Обновляем корзину...")
                    .padding(.horizontal, AppSpacing.large)
                    .padding(.vertical, AppSpacing.medium)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                    .shadow(radius: 8)
                    .allowsHitTesting(false)
            }
        }
        .task {
            await restoreAndSynchronizeCart()
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Понятно"))
            )
        }
    }
    
    private var cartItemsCount: Int {
        cart.itemsCount
    }
    
    private func addToCart(_ product: Product) {
        pendingCartOperations += 1

        Task { @MainActor in
            defer { pendingCartOperations -= 1 }

            do {
                let snapshot = try await cartStore.add(product)
                applyCartSnapshot(snapshot)
            } catch {
                alert = .error(error, title: "Не удалось обновить корзину")
            }
        }
    }
    
    private func removeFromCart(_ product: Product) {
        pendingCartOperations += 1

        Task { @MainActor in
            defer { pendingCartOperations -= 1 }

            do {
                let snapshot = try await cartStore.remove(product)
                applyCartSnapshot(snapshot)
            } catch {
                alert = .error(error, title: "Не удалось обновить корзину")
            }
        }
    }

    private func completeOrder() {
        Task { @MainActor in
            let snapshot = await cartStore.clear()
            applyCartSnapshot(snapshot, shouldPersist: false)

            do {
                try cartPersistence.clear()
            } catch {
                alert = .error(error, title: "Не удалось очистить локальную корзину")
            }
        }
    }

    private func mergeProducts(_ loadedProducts: [Product]) {
        favorites.synchronize(with: loadedProducts)
        let loadedProductIDs = Set(loadedProducts.map(\.id))
        products.removeAll { loadedProductIDs.contains($0.id) }
        products.append(contentsOf: loadedProducts)
        persistCart(showingErrors: false)

        Task {
            await cartStore.updateProducts(loadedProducts)
        }
    }

    private func updateProduct(_ product: Product) {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        products[index] = product
        persistCart(showingErrors: false)

        Task {
            await cartStore.updateProducts([product])
        }
    }

    @MainActor
    private func restoreAndSynchronizeCart() async {
        guard !didRestoreCart else { return }
        didRestoreCart = true
        isSynchronizingCart = true
        defer { isSynchronizingCart = false }

        do {
            let localSnapshot = try cartPersistence.load()
            let snapshot = await cartStore.restore(localSnapshot)
            applyCartSnapshot(snapshot)
        } catch {
            alert = .error(error, title: "Не удалось восстановить корзину")
        }

        do {
            let serverSnapshot = try await cartStore.synchronize()
            applyCartSnapshot(serverSnapshot)
        } catch {
            alert = .error(error, title: "Не удалось синхронизировать корзину")
        }
    }

    private func applyCartSnapshot(
        _ snapshot: CartSnapshot,
        shouldPersist: Bool = true
    ) {
        cart = snapshot.cart
        deliveryPrice = snapshot.deliveryPrice

        let snapshotProductIDs = Set(snapshot.products.map(\.id))
        products.removeAll { snapshotProductIDs.contains($0.id) }
        products.append(contentsOf: snapshot.products)

        if shouldPersist {
            persistCart(showingErrors: false)
        }
    }

    private func persistCart(showingErrors: Bool = true) {
        do {
            try cartPersistence.save(cart: cart, products: products)
        } catch where showingErrors {
            alert = .error(error, title: "Не удалось сохранить корзину")
        } catch {
            return
        }
    }
}
