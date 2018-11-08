/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Corner segments for the focus square UI.
*/

import SceneKit

extension FocusSquare {

    /*
    The focus square consists of eight segments as follows, which can be individually animated.

        s1  s2
        —‑  ‑‑
    s3 |      | s4

    s5 |      | s6
        --  --
        s7  s8
    */
    enum Corner {
        case topLeft            // Angle formed by segment 1 and segment 2
        case topRight           // Angle formed by segment 2 and segment 4
        case bottomRight        // Angle formed by segment 5 and segment 7
        case bottomLeft         // Angle formed by segment 6 and segment 8
    }
    enum Alignment {
        case horizontal         // Horizontal Lines: s1, s2, s7, s8
        case vertical           // Vertical Lines: s3, s4, s5, s6
    }
    enum Direction {
        case up                 // Animation Direction: Up
        case down               // Animation Direction: Down
        case left               // Animation Direction: Left
        case right              // Animation Direction: Right
        
        // reversed computed property of enum Direction
        var reversed: Direction {
            switch self {
                case .up:
                    return .down
                case .down:
                    return .up
                case .left:
                    return .right
                case .right:
                    return .left
            }
        }
    }

    class Segment: SCNNode {

        // MARK: - Configuration & Initialization

        /// Thickness of the focus square lines in meter
        // Attension this value have to equal to the value in FocusSquare object
        static let thickness: Float = 0.018

        /// Length of the focus square lines in m.
        static let length: Float = 0.5  // segment length

        /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
        static let openLength: Float = 0.2

        let corner: Corner
        let alignment: Alignment

        init(name: String, corner: Corner, alignment: Alignment) {
            self.corner = corner
            self.alignment = alignment
            super.init()
            self.name = name

            switch alignment {
            case .vertical:
                // if this segment is a vertical segment
                // -> then using thickness as width
                // -> using length as height
                geometry = SCNPlane(width: CGFloat(FocusSquare.Segment.thickness),
                                    height: CGFloat(FocusSquare.Segment.length))
            case .horizontal:
                // if this segment is a horizontal segment
                // -> then using thickness as height
                // -> using length as width
                geometry = SCNPlane(width: CGFloat(FocusSquare.Segment.length),
                                    height: CGFloat(FocusSquare.Segment.thickness))
            }
            // Set this segment's color as primaryColor
            let material = geometry!.firstMaterial!
            material.diffuse.contents = FocusSquare.primaryColor.darken(by: 0.1)
            // SceneKit by default only render one side of the SCNNode
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = FocusSquare.primaryColor
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Animating Open/Closed
        
        var openDirection: Direction {
            switch (corner, alignment) {
                case (.topLeft,     .horizontal),(.bottomLeft,  .horizontal): // When Focus Square Open Segments 1,7 go left
                    return .left
                case (.topLeft,     .vertical), (.topRight,    .vertical):    // When Focus Square Open Segments 3,4 go left
                    return .up
                case (.topRight,    .horizontal),(.bottomRight, .horizontal): // When Focus Square Open Segments 2,8 go left
                    return .right
                case (.bottomLeft,  .vertical),(.bottomRight, .vertical):     // When Focus Square Open Segments 5,6 go left
                    return .down
            }
        }

        func open() {
            guard let plane = self.geometry as? SCNPlane else { return }
            let direction = openDirection

            if alignment == .horizontal {
                plane.width = CGFloat(FocusSquare.Segment.openLength)
            } else {
                plane.height = CGFloat(FocusSquare.Segment.openLength)
            }

            let offset = FocusSquare.Segment.length / 2 - FocusSquare.Segment.openLength / 2
            switch direction {
                case .left:     self.position.x -= offset
                case .right:    self.position.x += offset
                case .up:       self.position.y -= offset
                case .down:     self.position.y += offset
            }
        }

        func close() {
            guard let plane = self.geometry as? SCNPlane else { return }
            // Close Animation's direction is the reverse direction of Open Animation's direction
            let direction = openDirection.reversed

            let oldLength: Float
            if alignment == .horizontal {
                oldLength = Float(plane.width)
                plane.width = CGFloat(FocusSquare.Segment.length)
            } else {
                oldLength = Float(plane.height)
                plane.height = CGFloat(FocusSquare.Segment.length)
            }

            let offset = FocusSquare.Segment.length / 2 - oldLength / 2
            switch direction {
                case .left:     self.position.x -= offset
                case .right:    self.position.x += offset
                case .up:       self.position.y -= offset
                case .down:     self.position.y += offset
            }
        }

    }
}
