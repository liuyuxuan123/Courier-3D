//
//  ModelDisplayViewController.swift
//  Courier 3D
//
//  Created by 刘宇轩 on 2018/10/26.
//  Copyright © 2018 yuxuanliu. All rights reserved.
//

import UIKit
import SceneKit

class ModelDisplayViewController: UIViewController {
    
    enum ShapeType:Int {
        
        case box = 0
        case sphere
        case pyramid
        case torus
        case capsule
        case cylinder
        case cone
        case tube
        
        static func random() -> ShapeType {
            let maxValue = tube.rawValue + 1
            return ShapeType(rawValue: maxValue.random())!
        }
        
    }
    
    
    
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    var modelURL: URL? {
        didSet {
            //image = nil
            if view.window != nil {
                fetch3DModel()
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        setupCamera()
        
        //        for _ in 0..<10{
        //            spawnShape()
        //        }
        
        fetch3DModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    
    func setupView(){
        
        scnView.showsStatistics = true
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        
        
        // Debug Options
        //scnView.debugOptions = SCNDebugOptions.showWorldOrigin
        //scnView.debugOptions = SCNDebugOptions.showWireframe
        //scnView.debugOptions = SCNDebugOptions.showCameras
        //scnView.debugOptions = SCNDebugOptions.showSkeletons
    }
    
    
    func setupScene(){
        self.scnScene = SCNScene()
        self.scnView.scene = self.scnScene
    }
    
    func setupCamera() {
        
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
        
    }
    
    func spawnShape() {
        
        var geometry:SCNGeometry
        switch ShapeType.random() {
        case .box:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.3)
        case .cone:
            geometry = SCNCone(topRadius: 0.5, bottomRadius: 1.0, height: 2)
        case .cylinder:
            geometry = SCNCylinder(radius: 1.0, height: 2.0)
        case .capsule:
            geometry = SCNCapsule(capRadius: 1.0, height: 1.0)
        case .pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .tube:
            geometry = SCNTube(innerRadius: 0.5, outerRadius: 1.0, height: 1.0)
        case .sphere:
            geometry = SCNSphere(radius: 1.0)
        case .torus:
            geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 1.0)
        }
        
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3.random()
        scnScene.rootNode.addChildNode(geometryNode)
        
    }
    func fetch3DModel(){
        self.spinner.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let chairScene = SCNScene(named: "art.scnassets/model.dae")!
            
            DispatchQueue.main.async {
                self.scnView.scene = chairScene
                self.spinner.stopAnimating()
            }
        }
        
    }
}

extension Int {
    func random() -> Int{
        if self > 0 {
            return Int(arc4random_uniform(UInt32(self)))
        }else if self < 0 {
            return -Int(arc4random_uniform(UInt32(-self)))
        }else{
            return 0
        }
    }
}


extension Double {
    func random() -> Double {
        return Double(arc4random()) / 0xFFFFFFFF * self
    }
}

extension SCNVector3 {
    static func random() -> SCNVector3 {
        return SCNVector3(10.0.random() - 5.0, 10.0.random() - 5.0, 0)
    }
}
