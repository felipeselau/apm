//
//  Item.swift
//  text-ide
//
//  Created by Luiz Felipe Scheffer Selau on 06/07/26.
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
