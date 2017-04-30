//
//  CGHelpers.swift
//  CatShip
//
//  Created by John Saba on 4/15/17.
//  Copyright © 2017 Cat Pants. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGPoint: Hashable {
    
    public var hashValue: Int {
        return "\(x)\(y)".hashValue
    }
}

extension CGPoint {
    
    // MARK: - Arithmetic
    
    func add(point: CGPoint) -> CGPoint {
        return CGPoint(x: x + point.x, y: y + point.y)
    }
    
    func subtract(point: CGPoint) -> CGPoint {
        return CGPoint(x: x - point.x, y: y - point.y)
    }
    
    func multiply(point: CGPoint) -> CGPoint {
        return CGPoint(x: x * point.x, y: y * point.y)
    }
    
    func multiply(factor: CGFloat) -> CGPoint {
        return multiply(point: CGPoint(x: factor, y: factor))
    }
    
    // MARK: - Collections
    
    static func matrix(min: CGPoint, max: CGPoint) -> Set<CGPoint> {
        var results = Set<CGPoint>()
        for x in Int(min.x)...Int(max.x) {
            for y in Int(min.y)...Int(max.y) {
                results.insert(CGPoint(x: x, y: y))
            }
        }
        return results
    }
    
    func surrounding(margin: Int) -> Set<CGPoint> {
        return CGPoint.matrix(min: CGPoint(x: Int(self.x) - margin, y: Int(self.y) - margin),
                              max: CGPoint(x: Int(self.x) + margin, y: Int(self.y) + margin))
    }
    
    // MARK: - Conversions
    
    var size: CGSize? {
        return CGSize(width: x, height: y)
    }
}

extension CGSize {
    
    // MARK: - Arithmetic
    
    func add(size: CGSize) -> CGSize {
        return CGSize(width: width + size.width, height: height + size.height)
    }
    
    func subtract(size: CGSize) -> CGSize {
        return CGSize(width: width - size.width, height: height - size.height)
    }
    
    func multiply(size: CGSize) -> CGSize {
        return CGSize(width: width * size.width, height: height * size.height)
    }
    
    func multiply(factor: CGFloat) -> CGSize {
        return multiply(size: CGSize(width: factor, height: factor))
    }
    
    // MARK: - Conversions
    
    var point: CGPoint {
        return CGPoint(x: width, y: height)
    }
}


