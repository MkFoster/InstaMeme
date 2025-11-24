//
//  Item.swift
//  InstaMeme
//
//  Created by Mark Foster on 11/24/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
