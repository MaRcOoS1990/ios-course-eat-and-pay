//
//  CategoryState.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

enum CategoryState {
    case loading
    case content([Category])
    case empty
    case error(String)
}
