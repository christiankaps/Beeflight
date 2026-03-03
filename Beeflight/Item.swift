//
//  Item.swift
//  Beeflight
//
//  Created by Christian Kaps on 03.03.26.
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
