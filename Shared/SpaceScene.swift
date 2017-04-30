//
//  SpaceScene.swift
//  CatShipUniv
//
//  Created by John Saba on 4/30/17.
//  Copyright © 2017 John Saba. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

protocol ResetDelegate: class {
    func handle() -> Void
}

class SpaceScene: SKScene {
    
    static let blimpSpeedFactorDefault: CGFloat = 300.0
    
    static let bodyMinRadius: CGFloat = 70
    static let bodyRotateSpeed = 0.003
    
    static let headStartRadius: CGFloat = 30
    static let headCenterDistance: CGFloat = 85
    
    static let inflateUpAddScale: CGFloat = 0.15
    static let inflateUpDuration = 0.10
    static let inflateEaseBackSubScale: CGFloat = 0.05
    static let inflateEaseBackDuration = 0.07
    
    static let speedOfLight: Int = 186282
    var speedBump = speedOfLight / 4
    
    // MARK: - Vars
    var lastUpdateTime: TimeInterval = 0
    var lastTouchTime: Date?
    var gamePaused: Bool = false
    var pauseIndexSelected: Int = 0
    var isSelecting = false
    var isInflating = false
    var isDeflating = false
    var blimpSpeed = CGPoint(x: 0, y: 0)
    var accelaration: CGFloat = 1.0
    var mps: Int = 100
    
    weak var resetDelegate: ResetDelegate?
    
    var cheeseburgerMap = [CGPoint: Array<SKNode>]()
    var cheeseburgerMapDFO = CGPoint(x: 0, y: 0)
    var starMap = [CGPoint: Array<SKNode>]()
    var starMapDFO = CGPoint(x: 0, y: 0)
    var starMap2 = [CGPoint: Array<SKNode>]()
    var starMap2DFO = CGPoint(x: 0, y: 0)
    var steakMap = [CGPoint: Array<SKNode>]()
    var steakMapDFO = CGPoint(x: 0, y: 0)
    var cucumberMap = [CGPoint: Array<SKNode>]()
    var cucumberMapDFO = CGPoint(x: 0, y: 0)
    
    var movedToBackground = [String]()
    var transitionToMap: CellMaps?
    var fireballFlash = false
    var speedAudioPlayer: AVAudioPlayer?
    
    enum CellMaps: String {
        case cheeseburger
        case star
        case star2
        case steak
        case cucumber
        
        static func all() -> [CellMaps] {
            return [.cheeseburger, .star, .star2, .steak, .cucumber]
        }
    }
    
    func cellMap(t: CellMaps) -> [CGPoint: Array<SKNode>] {
        switch t {
        case .cheeseburger:
            return cheeseburgerMap
        case .star:
            return starMap
        case .star2:
            return starMap2
        case .steak:
            return steakMap
        case .cucumber:
            return cucumberMap
        }
    }
    
    func allCellMapNodes() -> [SKNode] {
        var allNodes = [SKNode]()
        for t in CellMaps.all() {
            let nodes = cellMap(t: t).flatMap { $0.value }
            allNodes.append(contentsOf: nodes)
        }
        return allNodes
    }
    
    func resetAllMapNodesAlpha() {
        for t in CellMaps.all() {
            let nodes = cellMap(t: t).flatMap { $0.value }
            if movedToBackground.contains(t.rawValue) == true {
                for n in nodes {
                    n.alpha = 0.3
                }
            } else {
                for n in nodes {
                    n.alpha = 1.0
                }
            }
        }
    }
    
    func nodes(forCellMap: CellMaps) -> [SKNode] {
        return cellMap(t: forCellMap).flatMap { $0.value }
    }
    
    func set(forMap: CellMaps, contents: [SKNode], cell: CGPoint) {
        switch forMap {
        case .cheeseburger:
            cheeseburgerMap[cell] = contents
        case .star:
            starMap[cell] = contents
        case .star2:
            starMap2[cell] = contents
        case .steak:
            steakMap[cell] = contents
        case .cucumber:
            cucumberMap[cell] = contents
        }
    }
    
    var bodyMaxRadius: CGFloat {
        guard let s = cellSize() else {
            return 0.0
        }
        let r = CGFloat.minimum(s.width, s.height) * 0.5
        #if os(iOS)
            return r - 5
        #endif
        #if os(tvOS)
            return r - 20
        #endif
    }
    
    // MARK: - Setup
    
    override func didMove(to view: SKView) {
        addChild(blimp)
        
        cheeseburgerMapDFO = blimp.position
        starMapDFO = blimp.position
        starMap2DFO = blimp.position
        steakMapDFO = blimp.position
        cucumberMapDFO = blimp.position
        
        blimpSpeed = normalizedSpeed(radians: blimp.zRotation).multiply(factor: accelaration)
        
        addChild(speedLabel)
        renderSpeed()
    }
    
    // MARK: - UI Components
    
    func standardLabel(text: String) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        #if os(tvOS)
            label.fontSize = 80
            label.fontColor = UIColor.white
        #endif
        #if os(iOS)
            label.fontSize = 30
            label.fontColor = UIColor.white
        #endif
        return label
    }
    
    lazy var blimp: SKSpriteNode = { [weak self] in
        let sprite = SKSpriteNode(imageNamed: "bubblecat")
        sprite.zPosition = CGFloat.greatestFiniteMagnitude
        
        if let weakSelf = self {
            sprite.addChild(weakSelf.fireball)
        }
        return sprite
    }()
    
    lazy var fireball: SKSpriteNode = { [weak self] in
        let s = SKSpriteNode(imageNamed: "fireball")
        s.setScale(2.0)
        s.alpha = 0.0
        s.anchorPoint = CGPoint(x: 0.5, y: 0.85)
        return s
    }()
    
    lazy var speedLabel: SKLabelNode = {
        let label = self.standardLabel(text: "")
        label.fontColor = UIColor.white
        return label
    }()
    
    func renderSpeed() {
        speedLabel.text = "\(self.mps)  MPS"
        guard let cellSize = cellSize() else { return }
        let x = (-cellSize.width * 0.48) + (speedLabel.frame.size.width * 0.5)
        #if os(tvOS)
            let y = (cellSize.height * 0.40) - (speedLabel.frame.size.height * 0.5)
        #endif
        #if os(iOS)
            let y = (cellSize.height * 0.5) - (speedLabel.frame.size.height * 0.5 + 15)
        #endif
        speedLabel.position = CGPoint(x: x, y: y)
    }
    
    lazy var resumeLabel: SKLabelNode = {
        let label = self.standardLabel(text: "R E S U M E")
        label.position = label.position.add(point: CGPoint(x: 0, y: self.speedLabel.position.y - 100))
        self.addChild(label)
        return label
    }()
    
    lazy var restartLabel: SKLabelNode = {
        let label = self.standardLabel(text: "R E S T A R T")
        label.position = label.position.add(point: CGPoint(x: 0, y: self.resumeLabel.position.y - 100))
        self.addChild(label)
        return label
    }()
    
    lazy var selectBox: SKShapeNode = {
        let w: CGFloat = self.cellSize()?.width ?? 0
        let box = SKShapeNode(rectOf: CGSize(width: w + 20.0, height: 10.0))
        box.fillColor = .white
        box.lineWidth = 0.0
        box.alpha = 0.0
        self.addChild(box)
        return box
    }()
    
    func pauseBoxPos(index: Int) -> CGPoint {
        var label = self.resumeLabel
        if index == 1 {
            label = self.restartLabel
        }
        return label.position.add(point: CGPoint(x: 0.0, y: 30.0))
    }
    
    struct SpriteProperties {
        let scale: CGFloat
        let rotationSpeed: CGFloat
    }
    
    enum SpriteUserProperties: String {
        case rotationSpeed
        case collidable
        case scaleIn
        case scaleBack
    }
    
    func randomSpriteProperties() -> SpriteProperties {
        let rotationFactor: CGFloat = 0.1
        let rotationSpeed = Random.normalizedFloat() * rotationFactor * Random.positivityFactor()
        
        let scaleFactor: CGFloat = 0.5
        let scale = Random.normalizedFloat() * scaleFactor * Random.positivityFactor()
        
        return SpriteProperties(scale: scale, rotationSpeed: rotationSpeed)
    }
    
    // MARK: - Actions
    
    var inflateAction: SKAction {
        isInflating = true
        
        let scaleUp = SKAction.scale(by: 1 + SpaceScene.inflateUpAddScale, duration: SpaceScene.inflateUpDuration)
        scaleUp.timingMode = .easeIn
        
        let scaleDown = SKAction.scale(by: 1 - SpaceScene.inflateEaseBackSubScale, duration: SpaceScene.inflateEaseBackDuration)
        scaleDown.timingMode = .easeOut
        
        let finish = SKAction.customAction(withDuration: 0) { (_, _) in
            self.isInflating = false
        }
        return SKAction.sequence([scaleUp, scaleDown, finish])
    }
    
    var isDoingSpeedTransition = false
    func doSpeedTransition() {
        isDoingSpeedTransition = true
        fireballFlash = true
        
        backgroundColor = .white
        let finshedTransition = SKAction.customAction(withDuration: 0) { (_, _) in
            self.isDoingSpeedTransition = false
        }
        run(SKAction.sequence([SKAction.colorize(with: .black, colorBlendFactor: 1.0, duration: 1.2), finshedTransition]))
        run(SKAction.playSoundFileNamed("supermeow.wav", waitForCompletion: false))
        
        if transitionToMap == .cucumber {
            
            self.speedLabel.run(SKAction.fadeOut(withDuration: 0.3))
            
            let changeText1 = SKAction.customAction(withDuration: 0) { (_, _) in
                self.cucumberWarningLabel.text = "A V O I D"
            }
            
            let changeText2 = SKAction.customAction(withDuration: 0) { (_, _) in
                self.cucumberWarningLabel.text = "C U C U M B E R S"
            }
            
            let finish = SKAction.customAction(withDuration: 0) { (_, _) in
                self.cucumberWarningLabel.removeFromParent()
                self.speedLabel.run(SKAction.fadeIn(withDuration: 0.3))
            }
            
            let seq = SKAction.sequence([SKAction.fadeIn(withDuration: 0.3),
                                         SKAction.fadeOut(withDuration: 0.3),
                                         SKAction.fadeIn(withDuration: 0.3),
                                         SKAction.fadeOut(withDuration: 0.3),
                                         SKAction.fadeIn(withDuration: 0.3),
                                         SKAction.fadeOut(withDuration: 0.3),
                                         changeText1,
                                         SKAction.fadeIn(withDuration: 0.3),
                                         SKAction.fadeOut(withDuration: 0.3),
                                         SKAction.fadeIn(withDuration: 0.3),
                                         SKAction.fadeOut(withDuration: 0.3),
                                         changeText2,
                                         SKAction.fadeIn(withDuration: 0.3),
                                         SKAction.fadeOut(withDuration: 0.3),
                                         SKAction.fadeIn(withDuration: 0.3),
                                         SKAction.fadeOut(withDuration: 0.3),
                                         finish])
            
            cucumberWarningLabel.run(seq)
        }
    }
    
    lazy var cucumberWarningLabel: SKLabelNode = {
        let label = SKLabelNode(text: "W A R N I N G !")
        label.fontSize = 80
        label.fontColor = UIColor.white
        label.position = label.position.add(point: CGPoint(x: 0, y: self.speedLabel.position.y))
        self.addChild(label)
        return label
    }()
    
    // MARK: - Speed
    
    func normalized(radians: CGFloat) -> CGFloat {
        if radians > 2*CGFloat.pi {
            return radians - 2*CGFloat.pi
        } else if radians < 0 {
            return 2*CGFloat.pi + radians
        }
        return radians
    }
    
    func normalizedSpeed(radians: CGFloat) -> CGPoint {
        let normalizedRad = normalized(radians: radians)
        return CGPoint(x: sin(normalizedRad), y: cos(normalizedRad))
    }
    
    // MARK: - Cells
    
    func cells(forMap: CellMaps) -> Set<CGPoint> {
        return Set(cellMap(t: forMap).map { $0.key })
    }
    
    func cellSize() -> CGSize? {
        return frame.size
    }
    
    func distanceFromOrigin(forMap: CellMaps) -> CGPoint {
        switch forMap {
        case .cheeseburger:
            return cheeseburgerMapDFO
        case .star:
            return starMapDFO
        case .star2:
            return starMap2DFO
        case .steak:
            return steakMapDFO
        case .cucumber:
            return cucumberMapDFO
        }
    }
    
    func set(dfo: CGPoint, forMap: CellMaps) {
        switch forMap {
        case .cheeseburger:
            cheeseburgerMapDFO = dfo
        case .star:
            starMapDFO = dfo
        case .star2:
            starMap2DFO = dfo
        case .steak:
            steakMapDFO = dfo
        case .cucumber:
            cucumberMapDFO = dfo
        }
    }
    
    func currentCell(forMap: CellMaps) -> CGPoint? {
        guard let cellSize = cellSize() else { return nil }
        let dfo = distanceFromOrigin(forMap: forMap)
        return CGPoint(x: floor(dfo.x / cellSize.width),
                       y: floor(dfo.y / cellSize.height))
    }
    
    func absolutePosition(cell: CGPoint) -> CGPoint? {
        guard let sizeFactors = cellSize()?.point else { return nil }
        return cell.multiply(point: sizeFactors)
    }
    
    func randomRelativePosition(within cell: CGPoint) -> CGPoint? {
        return cellSize()?.multiply(size: Random.normalizedSize()).point
    }
    
    func renderGroup(forMap: CellMaps) -> Set<CGPoint> {
        return currentCell(forMap: forMap)?.surrounding(margin: 1) ?? Set<CGPoint>()
    }
    
    func removeFrom(cellMapType: CellMaps, node: SKNode, cell: CGPoint) -> SKNode? {
        var thisMap = cellMap(t: cellMapType)
        guard var nodes = thisMap[cell] else { return nil }
        guard let index = nodes.index(of: node) else { return nil }
        let removed = nodes.remove(at: index)
        set(forMap: cellMapType, contents: nodes, cell: cell)
        return removed
    }
    
    // create a single sprite
    func create(spriteNamed: String, cell: CGPoint, relativePosition: CGPoint, forMap: CellMaps, applying: ((SKSpriteNode) -> Void)?=nil) -> SKSpriteNode? {
        guard let absPosCell = absolutePosition(cell: cell) else { return nil }
        
        let sprite = SKSpriteNode(imageNamed: spriteNamed)
        let absPosSprite = absPosCell.add(point: relativePosition)
        sprite.position = absPosSprite.subtract(point: distanceFromOrigin(forMap: forMap))
        
        if let apply = applying {
            apply(sprite)
            if movedToBackground.contains(forMap.rawValue) == true {
                sprite.xScale = 0.5
                sprite.yScale = 0.5
                sprite.alpha = 0.5
                sprite.userData?[SpriteUserProperties.collidable.rawValue] = false
            }
        }
        
        addChild(sprite)
        
        return sprite
    }
    
    // create a set of sprites distributed randomly accross a cell
    func createSet(usingSpriteNamed: String, cell: CGPoint, volume: CGFloat, forMap: CellMaps, applying: ((SKSpriteNode) -> Void)?=nil) -> [SKSpriteNode] {
        
        let nodes: [SKSpriteNode] = Array(0..<Int(volume)).flatMap { volumeIndex in
            if let relPos = randomRelativePosition(within: cell) {
                return create(spriteNamed: usingSpriteNamed, cell: cell, relativePosition: relPos, forMap: forMap) { sprite in
                    applying?(sprite)
                }
            }
            return nil
            }.flatMap { $0 }
        
        return nodes
    }
    
    func createContents(cell: CGPoint, forMap: CellMaps) -> [SKNode] {
        switch forMap {
        case .cheeseburger:
            let v: CGFloat = movedToBackground.contains(forMap.rawValue) ? 2 : 4
            return createSet(usingSpriteNamed: "cheeseburger", cell: cell, volume: v, forMap: .cheeseburger) { sprite in
                let properties = self.randomSpriteProperties()
                sprite.setScale(0.8 + properties.scale)
                sprite.userData = [
                    SpriteUserProperties.rotationSpeed.rawValue: properties.rotationSpeed,
                    SpriteUserProperties.collidable.rawValue: true
                ]
            }
        case .star:
            return createSet(usingSpriteNamed: "flareRed", cell: cell, volume: 10, forMap: .star) { sprite in
                let properties = self.randomSpriteProperties()
                sprite.setScale((1 + properties.scale) * 0.8)
            }
        case .star2:
            return createSet(usingSpriteNamed: "flareBlue", cell: cell, volume: 15, forMap: .star2) { sprite in
                let properties = self.randomSpriteProperties()
                sprite.setScale((1 + properties.scale) * 0.3)
            }
        case .steak:
            let v: CGFloat = movedToBackground.contains(forMap.rawValue) ? 2 : 4
            return createSet(usingSpriteNamed: "ribeye", cell: cell, volume: v, forMap: .steak) { sprite in
                let properties = self.randomSpriteProperties()
                sprite.setScale(1.3 + properties.scale)
                sprite.userData = [
                    SpriteUserProperties.rotationSpeed.rawValue: properties.rotationSpeed,
                    SpriteUserProperties.collidable.rawValue: true
                ]
                if self.transitionToMap == .steak {
                    self.transitionToMap = nil
                    sprite.userData?.addEntries(from: [SpriteUserProperties.scaleIn.rawValue: sprite.xScale + 5,
                                                       SpriteUserProperties.scaleBack.rawValue: sprite.xScale])
                }
            }
        case .cucumber:
            return createSet(usingSpriteNamed: "cucumber", cell: cell, volume: 2, forMap: .cucumber) { sprite in
                let properties = self.randomSpriteProperties()
                sprite.setScale(1.3 + properties.scale)
                sprite.userData = [
                    SpriteUserProperties.rotationSpeed.rawValue: properties.rotationSpeed,
                    SpriteUserProperties.collidable.rawValue: true
                ]
                //                if self.transitionToMap == .steak {
                //                    self.transitionToMap = nil
                //                    sprite.userData?.addEntries(from: [SpriteUserProperties.scaleIn.rawValue: sprite.xScale + 5,
                //                                                       SpriteUserProperties.scaleBack.rawValue: sprite.xScale])
                //                }
            }
        }
        
    }
    
    func removeContents(cell: CGPoint, forMap: CellMaps) {
        var thisMap = cellMap(t: forMap)
        guard let contents = thisMap[cell] else { return }
        for node in contents {
            node.removeFromParent()
        }
        thisMap[cell] = nil
    }
    
    func cullCells(forMap: CellMaps) {
        // small break in between transitions
        if forMap == transitionToMap && isDoingSpeedTransition == true {
            return
        }
        
        let theseCells = cells(forMap: forMap)
        let thisRenderGroup = renderGroup(forMap: forMap)
        
        let stale = theseCells.subtracting(thisRenderGroup)
        for cell in stale {
            removeContents(cell: cell, forMap: forMap)
        }
        
        let new = thisRenderGroup.subtracting(theseCells)
        for cell in new {
            set(forMap: forMap, contents: createContents(cell: cell, forMap: forMap), cell: cell)
        }
    }
    
    // MARK: - Quads
    
    func quadSize() -> CGSize? {
        return cellSize()?.multiply(factor: 0.5)
    }
    
    func quadOffset(quad: Int) -> CGPoint? {
        guard let cellSize = cellSize() else { return nil }
        switch quad {
        case 1:
            return CGPoint(x: 0, y: cellSize.height * 0.5)
        case 2:
            return CGPoint(x: 0, y: 0)
        case 3:
            return CGPoint(x: cellSize.width, y: 0)
        case 4:
            return CGPoint(x: cellSize.width, y: cellSize.height)
        default:
            return nil
        }
    }
    
    func randomRelativePosition(quad: Int) -> CGPoint? {
        guard let quadOffset = quadOffset(quad: quad) else { return nil }
        let normPos = Random.normalizedPoint()
        let relPos = quadSize()?.point.multiply(point: normPos)
        return relPos?.add(point: quadOffset)
    }
    
    // MARK: - Updates
    
    override func update(_ currentTime: TimeInterval) {
        // Redirect to pause update cycle if needed
        guard gamePaused == false else {
            pauseUpdate(currentTime)
            lastUpdateTime = currentTime
            return
        }
        
        var deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Safety check in case last update time is over 1 second
        if deltaTime >= 1.0 {
            deltaTime = 1.0 / 60.0
        }
        
        // Handle cell maps
        for m in CellMaps.all() {
            update(deltaTime: deltaTime, forMap: m)
        }
        
        // Other
        if isDeflating {
            deflate(deltaTime: deltaTime)
        } else {
            if let player = speedAudioPlayer, player.volume > 0 {
                player.setVolume(player.volume - 0.05, fadeDuration: 0.0)
            }
        }
        
        // MPH
        renderSpeed()
    }
    
    func pauseUpdate(_ currentTime: TimeInterval) {
        
        if blimp.alpha > 0.15 {
            blimp.alpha -= 0.08
            if blimp.alpha > 0.1 {
                blimp.alpha = 0.1
            }
        }
        
        if speedLabel.position.x < 0.0 {
            speedLabel.position = speedLabel.position.add(point: CGPoint(x: 40, y: 0))
            if speedLabel.position.x > 0.0 {
                speedLabel.position = CGPoint(x: 0.0, y: speedLabel.position.y)
            }
        }
        
        for n in allCellMapNodes() {
            if n.alpha > 0.15 {
                n.alpha -= 0.07
            }
        }
        
        for n in [resumeLabel, restartLabel] {
            if n.alpha < 1.0 {
                n.alpha += 0.08
            }
        }
        
        if selectBox.alpha < 0.3 {
            selectBox.alpha += 0.065
        }
    }
    
    func pauseEnd() {
        
        blimp.alpha = 1.0
        
        renderSpeed()
        
        resetAllMapNodesAlpha()
        
        for n in [resumeLabel, restartLabel] {
            n.alpha = 0.0
        }
        
        selectBox.alpha = 0.0
    }
    
    func update(deltaTime: Double, forMap: CellMaps) {
        // only show steak after cheeseburger
        if forMap == .steak && movedToBackground.contains(CellMaps.cheeseburger.rawValue) == false {
            return
        }
        // only show cucumber after steak
        if forMap == .cucumber && movedToBackground.contains(CellMaps.steak.rawValue) == false {
            return
        }
        
        let deltaDistance = self.deltaDistance(deltaTime: deltaTime, forMap: forMap)
        
        updateDistanceFromOrigin(deltaDistance: deltaDistance, forMap: forMap)
        updateCellMapContents(deltaDistance: deltaDistance, forMap: forMap)
        cullCells(forMap: forMap)
        
        switch forMap {
        case .cheeseburger:
            if mps > speedBump && movedToBackground.contains(forMap.rawValue) == false {
                moveToBackground(forMap: forMap)
                transitionToMap = .steak
                doSpeedTransition()
            }
        case .steak:
            if mps > speedBump * 2 && movedToBackground.contains(forMap.rawValue) == false {
                moveToBackground(forMap: forMap)
                transitionToMap = .cucumber
                doSpeedTransition()
            }
        default:
            break
        }
    }
    
    func moveToBackground(forMap: CellMaps) {
        movedToBackground.append(forMap.rawValue)
        
        for n in nodes(forCellMap: forMap) {
            n.run(SKAction.scale(by: -0.7, duration: 0.3))
            n.run(SKAction.fadeAlpha(by: -0.7, duration: 0.3))
            n.userData?[SpriteUserProperties.collidable.rawValue] = false
        }
    }
    
    func deltaDistance(deltaTime: Double, forMap: CellMaps) -> CGPoint {
        let delta = CGPoint(x: -blimpSpeed.x * SpaceScene.blimpSpeedFactorDefault * accelaration * CGFloat(deltaTime),
                            y: blimpSpeed.y * SpaceScene.blimpSpeedFactorDefault * accelaration * CGFloat(deltaTime))
        
        var finalDelta = delta
        
        switch forMap {
        case .cheeseburger:
            finalDelta = delta
        case .star:
            finalDelta = delta.multiply(factor: 0.2)
        case .star2:
            finalDelta = delta.multiply(factor: 0.08)
        case .steak:
            finalDelta = delta.multiply(factor: 0.15)
        case .cucumber:
            finalDelta = delta.multiply(factor: 0.05)
        }
        
        // cap actual sprite speed to something reasonable
        if forMap == .cheeseburger || forMap == .steak || forMap == .cucumber {
            let maxDelta = CGPoint(x: 50, y: 50)
            
            if finalDelta.x > 0 && finalDelta.x > maxDelta.x {
                finalDelta.x = maxDelta.x
            }
            if finalDelta.y  > 0 && finalDelta.y > maxDelta.y {
                finalDelta.y = maxDelta.y
            }
            if finalDelta.x < 0 && finalDelta.x < -maxDelta.x {
                finalDelta.x = -maxDelta.x
            }
            if finalDelta.y < 0 && finalDelta.y < -maxDelta.y {
                finalDelta.y = -maxDelta.y
            }
        } else {
            let maxDelta = CGPoint(x: 25, y: 25)
            
            if finalDelta.x > 0 && finalDelta.x > maxDelta.x {
                finalDelta.x = maxDelta.x
            }
            if finalDelta.y  > 0 && finalDelta.y > maxDelta.y {
                finalDelta.y = maxDelta.y
            }
            if finalDelta.x < 0 && finalDelta.x < -maxDelta.x {
                finalDelta.x = -maxDelta.x
            }
            if finalDelta.y < 0 && finalDelta.y < -maxDelta.y {
                finalDelta.y = -maxDelta.y
            }
        }
        
        return finalDelta
    }
    
    func updateDistanceFromOrigin(deltaDistance: CGPoint, forMap: CellMaps) {
        let dfo = distanceFromOrigin(forMap: forMap)
        set(dfo: dfo.add(point: deltaDistance), forMap: forMap)
    }
    
    func updateCellMapContents(deltaDistance: CGPoint, forMap: CellMaps) {
        
        let thisMap = cellMap(t: forMap)
        var collisions = [(cell: CGPoint, node: SKNode)]()
        
        for (cell, nodes) in thisMap {
            for node in nodes {
                
                // update position
                node.position = node.position.subtract(point: deltaDistance)
                
                // rotation
                // TODO: fix delta adjust
                if let rotationSpeed = node.userData?[SpriteUserProperties.rotationSpeed.rawValue] as? CGFloat {
                    node.zRotation += rotationSpeed
                }
                
                if let scaleIn = node.userData?[SpriteUserProperties.scaleIn.rawValue] as? CGFloat {
                    node.setScale(node.xScale + 0.2)
                    if node.xScale > scaleIn {
                        node.userData?[SpriteUserProperties.scaleIn.rawValue] = nil
                    }
                } else if let scaleBack = node.userData?[SpriteUserProperties.scaleBack.rawValue] as? CGFloat {
                    node.setScale(node.xScale - 0.3)
                    if node.xScale < scaleBack {
                        node.userData?[SpriteUserProperties.scaleBack.rawValue] = nil
                        node.setScale(scaleBack)
                    }
                } else {
                    // collision
                    if let
                        collidable = node.userData?[SpriteUserProperties.collidable.rawValue] as? Bool,
                        collidable,
                        blimp.frame.contains(node.position) {
                        
                        collisions.append((cell, node))
                    }
                }
            }
        }
        
        for collision in collisions {
            if let node = removeFrom(cellMapType: forMap, node: collision.node, cell: collision.cell) {
                node.removeFromParent()
                
                if forMap == .cucumber {
                    if isHittingCuke == false {
                        hitCuke()
                    }
                } else {
                    run(SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false))
                    if blimp.frame.size.height < (bodyMaxRadius * 2.0) {
                        blimp.run(inflateAction)
                    }
                }
            }
        }
        
        if fireballFlash == true {
            fireball.alpha += 0.07
            if fireball.alpha >= 1 {
                fireballFlash = false
            }
        } else if fireball.alpha > 0 {
            fireball.alpha -= 0.02
        }
    }
    
    var isHittingCuke = false
    func hitCuke() {
        let finish = SKAction.customAction(withDuration: 0) { (_, _) in
            self.isHittingCuke = false
        }
        let seq = SKAction.sequence(
            [SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
             SKAction.colorize(with: .black, colorBlendFactor: 1.0, duration: 0.1),
             SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
             SKAction.colorize(with: .black, colorBlendFactor: 1.0, duration: 0.1),
             SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
             SKAction.colorize(with: .black, colorBlendFactor: 1.0, duration: 0.1),
             finish]
        )
        run(seq)
        
    }
    
    func deflate(deltaTime: Double) {
        guard (blimp.frame.size.height * 0.5) > SpaceScene.bodyMinRadius else {
            isDeflating = false
            return
        }
        
        let scaleFactor = blimp.xScale - CGFloat(deltaTime * 1.0)
        blimp.setScale(scaleFactor)
        accelaration += 0.010
        blimpSpeed = normalizedSpeed(radians: blimp.zRotation).multiply(factor: accelaration)
        
        mps += Int(90 * accelaration)
    }
    
    func rotateBlimp(deltaLocation: CGPoint) {
        #if os(iOS)
            let rotationFactor = (deltaLocation.x * 0.01) * -1.0
        #endif
        #if os(tvOS)
            let rotationFactor = (deltaLocation.x * 0.003) * -1.0
        #endif
        
        blimp.zRotation.add(rotationFactor)
        blimp.zRotation = normalized(radians: blimp.zRotation)
    }
    
    func render(cell: CGPoint) {
        
    }
    
    // MARK: - Touches
    
    func touchBegan(touch: UITouch) {
        #if os(iOS)
            let now = Date()
            if let last = lastTouchTime, now.timeIntervalSince(last) < 0.33 {
                self.handlePress()
            }
            lastTouchTime = now
        #endif
    }
    
    func touchMoved(touch: UITouch) {
        let location = touch.location(in: self)
        let prevLocation = touch.previousLocation(in: self)
        let deltaLocation = location.subtract(point: prevLocation)
        
        guard gamePaused == false else {
            pauseTouchMoved(deltaLocation: deltaLocation)
            return
        }
        
        rotateBlimp(deltaLocation: deltaLocation)
        blimpSpeed = normalizedSpeed(radians: blimp.zRotation).multiply(factor: accelaration)
    }
    
    func touchEnded(touch: UITouch) {
        #if os(iOS)
            handlePressEnded()
        #endif
    }
    
    func pauseTouchMoved(deltaLocation: CGPoint) {
        if deltaLocation.y < -0.3 {
            if pauseIndexSelected != 1 {
                pauseIndexSelected = 1
                selectBox.position = pauseBoxPos(index: pauseIndexSelected)
            }
        } else if deltaLocation.y > 0.3 {
            if pauseIndexSelected != 0 {
                pauseIndexSelected = 0
                selectBox.position = pauseBoxPos(index: pauseIndexSelected)
            }
        }
    }
}

extension SpaceScene {
    // MARK: - Universal Press Handlers
    
    func handlePress() {
        if gamePaused {
            if pauseIndexSelected == 0 {
                pauseEnd()
                gamePaused = false
            } else {
                resetDelegate?.handle()
            }
        } else {
            isDeflating = true
            
            // start speed up audio
            if let p = Bundle.main.path(forResource: "speed", ofType: "wav") {
                let url = URL(fileURLWithPath: p)
                do {
                    speedAudioPlayer = try AVAudioPlayer(contentsOf: url)
                } catch {
                    // error
                }
            }
            if let player = speedAudioPlayer {
                player.prepareToPlay()
                player.play()
            }
        }
    }
    
    func handlePressEnded() {
        isDeflating = false
    }
}

#if os(tvOS)
extension SpaceScene: PressHandler {
    
    // MARK: - PressHandler Delegate
    
    func selectBegan(press: UIPress) {
        handlePress()
    }
    
    func selectEnded(press: UIPress) {
        handlePressEnded()
    }
    
    func selectChanged(press: UIPress) {}
    
    func playPressed(press: UIPress) {
        if gamePaused {
            pauseEnd()
        } else {
            selectBox.position = pauseBoxPos(index: pauseIndexSelected)
        }
        gamePaused = !gamePaused
    }
}
#endif

// MARK: UIResponder
extension SpaceScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Only process first
        guard let t = touches.first else { return }
        touchBegan(touch: t)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchMoved(touch: t)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchEnded(touch: t)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchEnded(touch: t)
        }
    }
    
    override func remoteControlReceived(with event: UIEvent?) {}
}

