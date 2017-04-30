//
//  Random.swift
//  CatShip
//
//  Created by John Saba on 4/23/17.
//  Copyright © 2017 Cat Pants. All rights reserved.
//

import Foundation
import CoreGraphics

struct Random {
    
    static func normalizedFloat() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
    
    static func normalizedPoint() -> CGPoint {
        return CGPoint(x: normalizedFloat(), y: normalizedFloat())
    }
    
    static func normalizedSize() -> CGSize {
        return CGSize(width: normalizedFloat(), height: normalizedFloat())
    }
    
    static func positivityFactor() -> CGFloat {
       return (Random.normalizedFloat() > 0.5) ? -1 : 1
    }
}
