//
//  GameViewController.swift
//  CatShipUniv
//
//  Created by John Saba on 4/29/17.
//  Copyright © 2017 John Saba. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    var gameScene: SKScene?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startScene()
    }
    
    func startScene() {
        guard
            let view = self.view as? SKView,
            let scene = SKScene(fileNamed: "SpaceScene") as? SpaceScene else {
                return
        }
        
        gameScene = scene
        //scene.resetDelegate = self
        //pressHandler = gameScene as? PressHandler
        scene.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 1.0)
        view.presentScene(scene, transition: transition)
    }
    
    // MARK: - Template
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
