# EatAndPay — состояние проекта и точка продолжения

Этот файл нужен, чтобы можно было продолжить работу в новом чате без потери контекста.

## Общий контекст

Я делаю учебный iOS SwiftUI-проект `EatAndPay` для курса Wildberries & Russ.

Цель проекта: сделать приложение с каталогом товаров, корзиной и оформлением заказа, постепенно улучшая архитектуру и понимая, зачем добавляются отдельные слои: Models, DTO, Mappers, Services, Views.

Я хочу, чтобы объяснения были пошаговыми, простым языком, но с правильной архитектурной логикой. Мне важно понимать не только что вставить в код, но и зачем это делается.

## Текущая структура проекта

Проект называется:

```text
EatAndPay
```

Основные папки:

```text
EatAndPay
├── DesignSystem
│   ├── AppColors.swift
│   ├── AppRadius.swift
│   ├── AppShadow.swift
│   └── AppSpacing.swift
├── Models
│   ├── DTO
│   │   ├── ProductDTO.swift
│   │   └── ProductsResponseDTO.swift
│   ├── Mappers
│   │   └── ProductMapper.swift
│   ├── CatalogState.swift
│   └── Product.swift
├── Services
│   ├── CartService.swift
│   ├── CatalogService.swift
│   ├── NetworkCatalogService.swift
│   ├── NetworkError.swift
│   ├── PriceFormatter.swift
│   └── Secrets.swift
├── Views
│   ├── ProductListView.swift
│   ├── CartView.swift
│   └── ProductCard.swift
├── Assets.xcassets
└── EatAndPayApp.swift
```

Важно: `Secrets.swift` содержит реальный access token и не должен попадать в GitHub.

## Что уже реализовано

### 1. Каталог товаров

Есть экран:

```text
ProductListView
```

Он:
- показывает состояние загрузки;
- показывает список товаров;
- показывает пустое состояние;
- показывает ошибку;
- загружает реальные товары через `NetworkCatalogService`;
- использует `NavigationStack`;
- содержит toolbar с кнопкой корзины;
- хранит локальное состояние корзины.

Состояние каталога описано через enum:

```swift
enum CatalogState {
    case loading
    case content([Product])
    case empty
    case error(String)
}
```

Это сделано, чтобы экран находился только в одном состоянии одновременно.

### 2. Модель Product

Модель товара примерно такая:

```swift
struct Product: Identifiable {
    let id: String
    let name: String
    let price: Decimal
    let imageURL: URL?
    let weight: Int?
    let rating: Double?
    let reviewCount: Int?
    let isFavorite: Bool
    let discount: Int?
}
```

`imageURL` используется для загрузки сетевой картинки через `AsyncImage`.

### 3. DTO и Mapper

Созданы DTO:

```swift
ProductDTO
ProductsResponseDTO
```

`ProductDTO` отражает данные, которые приходят с backend.

`ProductMapper` преобразует `ProductDTO` в UI-модель `Product`.

В mapper есть логика создания `URL` для картинки. Если API отдаёт относительный путь, нужно использовать базовый URL:

```swift
https://eat-and-pay.t02.ru
```

### 4. NetworkCatalogService

Есть сетевой сервис:

```swift
NetworkCatalogService
```

Он:
- ходит на `https://eat-and-pay.t02.ru/products`;
- добавляет header Authorization;
- декодирует ответ в `ProductsResponseDTO`;
- преобразует DTO в `[Product]`.

Токен лежит в `Secrets.swift`:

```swift
enum Secrets {
    static let accessToken = "PASTE_YOUR_TOKEN_HERE"
}
```

В коде request используется примерно так:

```swift
request.setValue(
    "Bearer \(Secrets.accessToken)",
    forHTTPHeaderField: "Authorization"
)
```

В чат токен не отправлять и на скриншотах не показывать.

### 5. ProductCard

Был файл `CategoryCard.swift`, но его переименовали в:

```text
ProductCard.swift
```

Внутри:

```swift
struct ProductCard: View
```

Карточка товара показывает:
- большую картинку товара;
- цену;
- название;
- вес;
- рейтинг;
- количество отзывов;
- кнопку добавления в корзину.

Картинка занимает верхний image-блок товара. Используется:

```swift
.resizable()
.scaledToFill()
.frame(maxWidth: .infinity, maxHeight: .infinity)
.clipped()
```

Чтобы картинка заполняла весь блок изображения, но не заходила на цену и текст.

### 6. Локальная корзина в ProductListView

В `ProductListView` есть локальное состояние:

```swift
@State private var cartQuantities: [String: Int] = [:]
```

Ключ — `product.id`, значение — количество товара.

Есть функции:

```swift
private func quantity(for product: Product) -> Int {
    cartQuantities[product.id, default: 0]
}

private func addToCart(_ product: Product) {
    cartQuantities[product.id, default: 0] += 1
}

private func removeFromCart(_ product: Product) {
    let currentQuantity = cartQuantities[product.id, default: 0]

    if currentQuantity <= 1 {
        cartQuantities[product.id] = nil
    } else {
        cartQuantities[product.id] = currentQuantity - 1
    }
}
```

### 7. Кнопка товара со счётчиком

В `ProductCard` кнопка работает так:

```text
если quantity == 0:
    [В корзину]

если quantity > 0:
    [-] quantity [+]
```

`ProductCard` не хранит количество сама. Она получает:
- `quantity`;
- `onAddToCart`;
- `onRemoveFromCart`.

Это сделано правильно: карточка только отображает данные и сообщает наверх о действиях пользователя, а состояние хранится в `ProductListView`.

### 8. Кнопка корзины в toolbar

В `ProductListView` есть кнопка корзины справа сверху.

Она прямоугольная:

```text
[ cart  4 ]
```

Слева иконка корзины, справа общий счётчик товаров.

Общее количество считается так:

```swift
private var cartItemsCount: Int {
    cartQuantities.values.reduce(0, +)
}
```

### 9. Экран CartView

Создан экран:

```text
CartView.swift
```

Он получает:
- все текущие продукты;
- словарь quantities;
- action на добавление;
- action на уменьшение.

Примерно:

```swift
CartView(
    products: currentProducts,
    quantities: cartQuantities,
    onAddToCart: { product in
        addToCart(product)
    },
    onRemoveFromCart: { product in
        removeFromCart(product)
    }
)
```

`CartView` показывает только те товары, у которых quantity > 0.

### 10. Навигация в корзину

В `ProductListView` есть:

```swift
@State private var isCartPresented = false
```

Кнопка корзины делает:

```swift
isCartPresented = true
```

Переход реализован через:

```swift
.navigationDestination(isPresented: $isCartPresented) {
    CartView(...)
}
```

Для передачи товаров в корзину есть computed property:

```swift
private var currentProducts: [Product] {
    if case let .content(products) = state {
        return products
    } else {
        return []
    }
}
```

### 11. Корзина показывает суммы

В `CartView` уже есть:
- список товаров;
- количество каждого товара;
- кнопки `-` и `+`;
- цена за единицу;
- сумма по конкретному товару;
- общий итог.

Сумма по одному товару считается так:

```swift
private func totalPrice(for product: Product) -> Decimal {
    let quantity = Decimal(quantities[product.id, default: 0])
    return product.price * quantity
}
```

Общий итог считается так:

```swift
private var totalPrice: Decimal {
    cartProducts.reduce(Decimal(0)) { result, product in
        let quantity = Decimal(quantities[product.id, default: 0])
        return result + product.price * quantity
    }
}
```

Строка товара в корзине должна показывать примерно:

```text
Яблоко                         180 ₽
45 ₽ × 4
[-] 4 [+]
```

Внизу корзины:

```text
Итого                          400 ₽
```

## Где мы остановились

Мы остановились перед шагом:

```text
Добавить кнопку "Оформить заказ" в CartView
```

План на следующий шаг:

1. В `CartView` добавить `onCheckout: () -> Void`.
2. Добавить кнопку `Оформить заказ`.
3. В `ProductListView` передать `onCheckout`.
4. В `ProductListView` сделать функцию `checkout()`.
5. Пока локально:
   - показать alert "Заказ оформлен";
   - очистить `cartQuantities`;
   - закрыть корзину.

После этого следующий архитектурный шаг:
- вынести корзину из `ProductListView` в отдельную модель состояния, например `CartStore`;
- затем сделать `OrderService`;
- позже подключить реальные API корзины/заказов.

## Важные технические замечания

### Secrets.swift

`Secrets.swift` содержит реальный токен и не должен попадать в GitHub.

Нужно сделать:

```text
Secrets.swift          — настоящий файл локально, не коммитить
Secrets.example.swift  — пример без токена, можно коммитить
.gitignore             — исключает Secrets.swift
```

В `.gitignore` добавить:

```gitignore
# Secrets
Secrets.swift
**/Secrets.swift
```

### Для сдачи домашки

Нужен отдельный GitHub-репозиторий под учебный проект `EatAndPay`.

Лучший безопасный вариант:
- не трогать рабочие проекты;
- создать отдельный репозиторий;
- подключить к нему только этот учебный проект;
- перед первым push проверить, что `Secrets.swift` не попадает в Git;
- сдавать ссылку на репозиторий или Pull Request.

## Формулировка для нового чата

Скопируй в новый чат:

```text
Я делаю учебный iOS SwiftUI-проект EatAndPay для курса Wildberries & Russ. Нужно продолжить с текущего состояния проекта.

Объясняй пошагово, простым языком, но с правильной архитектурной логикой. Мне важно понимать не только что вставить в код, но и зачем это делается.

Текущий статус:
- Проект iOS SwiftUI.
- Есть структура: DesignSystem, Models, DTO, Mappers, Services, Views.
- Есть ProductListView, ProductCard, CartView.
- Товары загружаются через NetworkCatalogService с API https://eat-and-pay.t02.ru/products.
- Авторизация идёт через Secrets.accessToken. Токен не просить, не показывать и не коммитить.
- Product содержит id, name, price, imageURL, weight, rating, reviewCount, isFavorite, discount.
- ProductDTO и ProductsResponseDTO уже созданы.
- ProductMapper преобразует ProductDTO в Product.
- ProductCard показывает картинку, цену, название, вес, рейтинг, отзывы.
- Картинка товара растянута на весь верхний image-блок через scaledToFill + clipped, но цена и текст находятся ниже картинки.
- Кнопка ProductCard работает как [В корзину], а после добавления как [-] quantity [+].
- ProductListView хранит локальную корзину через @State cartQuantities: [String: Int].
- В ProductListView есть addToCart, removeFromCart, quantity(for:).
- В toolbar есть прямоугольная кнопка корзины: слева иконка cart, справа общий счётчик товаров.
- CartView открывается через navigationDestination(isPresented:).
- CartView показывает только выбранные товары, количество, цену за единицу, сумму по каждому товару и общий итог.
- В корзине можно менять количество через - и +, изменения отражаются в ProductListView.
- Мы остановились перед добавлением кнопки "Оформить заказ" в CartView.

Следующий шаг:
Добавить кнопку "Оформить заказ" в CartView:
1. Добавить onCheckout: () -> Void.
2. Добавить checkoutButton.
3. Передать onCheckout из ProductListView.
4. В ProductListView сделать checkout(), который пока локально очищает cartQuantities, закрывает корзину и показывает alert "Заказ оформлен".
5. После этого обсудить вынос корзины в CartStore и дальнейшую архитектуру.
```
