//
//  GameViewController.swift
//  tvOS
//
//  Created by John Saba on 4/29/17.
//  Copyright © 2017 John Saba. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

protocol PressHandler {
    func selectBegan(press: UIPress)
    func selectChanged(press: UIPress)
    func selectEnded(press: UIPress)
    func playPressed(press: UIPress)
}

class GameViewController: UIViewController {
    
    var gameScene: SKScene?
    var pressHandler: PressHandler?
    var musicAudioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startScene()
        startMusic()
    }
    
    func startScene() {
        guard
            let view = self.view as? SKView,
            let scene = SKScene(fileNamed: "SpaceScene") as? SpaceScene else {
                return
        }
        
        gameScene = scene
        scene.resetDelegate = self
        pressHandler = gameScene as? PressHandler
        scene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        view.presentScene(scene, transition: transition)
    }
    
    func startMusic() {
        // start speed up audio
        if let p = Bundle.main.path(forResource: "space", ofType: "mp3") {
            let url = URL(fileURLWithPath: p)
            do {
                musicAudioPlayer = try AVAudioPlayer(contentsOf: url)
            } catch {
                // error
            }
        }
        if let player = musicAudioPlayer {
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
        }
    }

    // MARK: - UIResponder

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard (presses.filter { $0.type == .menu }).count == 0 else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        for p in presses {
            switch p.type {
            case .select:
                pressHandler?.selectBegan(press: p)
            case .playPause:
                pressHandler?.playPressed(press: p)
            default:
                break
            }
        }
    }

    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard (presses.filter { $0.type == .menu }).count == 0 else {
            super.pressesChanged(presses, with: event)
            return
        }
        
        for p in presses {
            switch p.type {
            case .select:
                pressHandler?.selectChanged(press: p)
            default:
                break
            }
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard (presses.filter { $0.type == .menu }).count == 0 else {
            super.pressesEnded(presses, with: event)
            return
        }
        
        for p in presses {
            switch p.type {
            case .select:
                pressHandler?.selectEnded(press: p)
            default:
                break
            }
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard (presses.filter { $0.type == .menu }).count == 0 else {
            super.pressesEnded(presses, with: event)
            return
        }
        
        for p in presses {
            switch p.type {
            case .select:
                pressHandler?.selectEnded(press: p)
            default:
                break
            }
        }
    }
}

extension GameViewController: ResetDelegate {
    
    func handle() {
        startScene()
    }
}

