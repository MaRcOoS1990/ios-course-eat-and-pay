//
//  Category.swift
//  EatAndPay
//
//  Created by Codex on 13.08.2026.
//

import Foundation

struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    let imageURL: URL?
}
