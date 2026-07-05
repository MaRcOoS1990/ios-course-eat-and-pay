//
//  CatalogState.swift
//  EatAndPay
//
//  Created by Чалов Алексей Вячеславович on 05.07.2026.
//

import Foundation

enum CatalogState {
    case loading
    case content([Product])
    case empty
    case error(String)
}
