import SwiftUI
import SceneKit
import UIKit

/// An open, stylized teaching model, not a reconstruction of the ark.
final class ArkWorkshopScene {
    let scene = SCNScene()
    let camera = SCNNode()
    let ark = SCNNode()
    private var timberGroups: [SCNNode] = []
    private var deckNodes: [SCNNode] = []
    private var ghostNodes: [SCNNode] = []
    private var paintSurfaces: [SCNNode] = []
    private var paintImages: [UIImage] = []
    private var previousUV: CGPoint?
    private let roof = SCNNode()
    private var previousSignature = ""
    private let warmWood: SCNMaterial
    private let darkWood: SCNMaterial
    private let gold: SCNMaterial
    init() {
        warmWood = Self.wood(base: UIColor(red: 0.67,green: 0.38,blue: 0.17,alpha: 1))
        darkWood = Self.wood(base: UIColor(red: 0.31,green: 0.17,blue: 0.09,alpha: 1))
        gold = Self.material("#D7AD61",metal: 0.65)
        scene.rootNode.addChildNode(ark)
        camera.camera = SCNCamera(); camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 3.5; camera.camera?.zNear = 0.1; camera.camera?.zFar = 50
        camera.position = SCNVector3(5.6,4.2,7.6); camera.look(at: SCNVector3(0,0.9,0)); scene.rootNode.addChildNode(camera)
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient
        ambient.light?.color = UIColor(red: 0.82,green: 0.9,blue: 0.91,alpha: 1); ambient.light?.intensity = 360
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode(); sun.light = SCNLight(); sun.light?.type = .directional
        sun.light?.color = UIColor(red: 1,green: 0.9,blue: 0.75,alpha: 1); sun.light?.intensity = 850
        sun.light?.castsShadow = true; sun.light?.shadowRadius = 7; sun.light?.shadowSampleCount = 12
        sun.light?.shadowColor = UIColor.black.withAlphaComponent(0.25)
        sun.eulerAngles = SCNVector3(-0.7,-0.65,-0.2); scene.rootNode.addChildNode(sun)
        let fill = SCNNode(); fill.light = SCNLight(); fill.light?.type = .omni; fill.light?.intensity = 180
        fill.position = SCNVector3(-4,3,3); scene.rootNode.addChildNode(fill)
        let parchment = Self.material("#DCC59A")
        let platform = Self.box(scene.rootNode,size: SCNVector3(5.25,0.09,2.6),at: SCNVector3(0,-0.12,0),material: parchment,bevel: 0.1)
        platform.eulerAngles.y = -0.02
        // Brass inlay and engraved measurement marks make the miniature feel handcrafted.
        for z: Float in [-1.1,1.1] {
            Self.box(scene.rootNode,size: SCNVector3(4.85,0.012,0.018),at: SCNVector3(0,-0.065,z),material: gold,bevel: 0.004)
            for mark in 0..<25 {
                Self.box(scene.rootNode,size: SCNVector3(0.012,0.014,mark%5 == 0 ? 0.12 : 0.055),at: SCNVector3(-2.35+Float(mark)*0.195,-0.059,z),material: gold,bevel: 0)
            }
        }
        for section in 0..<3 {
            let group = SCNNode(); ark.addChildNode(group); timberGroups.append(group)
            // Planked curved hull; the front remains cut away above the low bulwark.
            for plank in 0..<5 {
                let y = Float(plank)*0.085+0.08,width = 0.44+Float(plank)*0.075
                for side: Float in [-1,1] {
                    Self.box(group,size: SCNVector3(1.37,0.075,0.075),at: SCNVector3(Float(section-1)*1.37,y,side*width),material: plank%2 == 0 ? warmWood : darkWood,bevel: 0.02)
                }
            }
            // The far side remains intact; the near side is open so children can see the floors.
            for plank in 5..<20 {
                Self.box(group,size: SCNVector3(1.37,0.075,0.065),at: SCNVector3(Float(section-1)*1.37,Float(plank)*0.085+0.08,-0.74),material: plank%3 == 0 ? darkWood : warmWood,bevel: 0.015)
            }
            for x in 0..<3 {
                let px = Float(section-1)*1.37+Float(x-1)*0.42
                Self.box(group,size: SCNVector3(0.075,1.75,0.08),at: SCNVector3(px,0.88,-0.73),material: darkWood,bevel: 0.018)
                Self.box(group,size: SCNVector3(0.075,0.45,0.08),at: SCNVector3(px,0.23,0.73),material: darkWood,bevel: 0.018)
                for z: Float in [-0.76,0.76] {
                    let peg = SCNSphere(radius: 0.026); peg.materials = [gold]
                    let node = SCNNode(geometry: peg); node.position = SCNVector3(px,0.34,z); group.addChildNode(node)
                }
            }
        }
        // Bow and stern have curved laminated end caps rather than a flat block.
        for side: Float in [-1,1] {
            let cap = SCNNode(); timberGroups[side < 0 ? 0 : 2].addChildNode(cap)
            for plank in 0..<5 {
                let y = CGFloat(plank)*0.085+0.08,width = CGFloat(0.44+Float(plank)*0.075)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0,y: -width)); path.addQuadCurve(to: CGPoint(x: 0,y: width),controlPoint: CGPoint(x: CGFloat(side)*0.7,y: 0))
                path.addLine(to: CGPoint(x: -CGFloat(side)*0.065,y: width)); path.addQuadCurve(to: CGPoint(x: -CGFloat(side)*0.065,y: -width),controlPoint: CGPoint(x: CGFloat(side)*0.63,y: 0)); path.close()
                let shape = SCNShape(path: path,extrusionDepth: 0.075); shape.chamferRadius = 0.018; shape.materials = [warmWood]
                let node = SCNNode(geometry: shape); node.position = SCNVector3(side*2.04,Float(y),0)
                node.eulerAngles.x = Float.pi/2; cap.addChildNode(node)
            }
        }
        let ghost = Self.material("#A7D5C2"); ghost.lightingModel = .constant; ghost.transparency = 0.35; ghost.isDoubleSided = true
        ghost.writesToDepthBuffer = false
        for level in 0..<3 {
            let y = Float(level)*0.56+0.42
            let deck = SCNNode(); deck.position.y = y; ark.addChildNode(deck); deckNodes.append(deck)
            for plank in 0..<11 {
                Self.box(deck,size: SCNVector3(4.08,0.065,0.126),at: SCNVector3(0,0,Float(plank-5)*0.128),material: warmWood,bevel: 0.015)
            }
            // Room dividers are visible at the back, leaving the teaching cutaway clear.
            if level < 2 {
                for x: Float in [-0.68,0.68] { Self.box(deck,size: SCNVector3(0.045,0.46,0.66),at: SCNVector3(x,0.26,-0.34),material: darkWood,bevel: 0.01) }
            }
            let silhouette = Self.box(ark,size: SCNVector3(4.06,0.025,1.4),at: SCNVector3(0,y,0),material: ghost,bevel: 0.04)
            ghostNodes.append(silhouette)
        }
        // Small pitched-roof shelter completes the plan only after all three discoveries.
        ark.addChildNode(roof)
        Self.box(roof,size: SCNVector3(1.1,0.38,0.65),at: SCNVector3(0,1.79,-0.22),material: warmWood,bevel: 0.035)
        for side: Float in [-1,1] {
            let node = Self.box(roof,size: SCNVector3(1.28,0.07,0.55),at: SCNVector3(0,2.05,-0.22+side*0.2),material: darkWood,bevel: 0.02)
            node.eulerAngles.x = side*0.45
        }
        let opening = Self.material("#162F32")
        for index in -2...2 { Self.box(roof,size: SCNVector3(0.12,0.16,0.015),at: SCNVector3(Float(index)*0.19,1.82,0.115),material: opening,bevel: 0.025) }
        for side in 0..<2 {
            let plane = SCNPlane(width: 4.12,height: 1.4)
            let material = Self.material("#D7A46C"); plane.materials = [material]
            let node = SCNNode(geometry: plane); node.name = "ark-paint-\(side)"; node.categoryBitMask = 4
            node.position = side == 0 ? SCNVector3(0,0.93,0.8) : SCNVector3(0,1.59,0)
            if side == 1 { node.eulerAngles.x = -.pi/2 }
            ark.addChildNode(node); paintSurfaces.append(node)
        }
        resetPaint()
        sync(ArkWorkshopRound(),animated: false)
    }
    func resize(_ size: CGSize) {
        guard size.width > 0,size.height > 0 else { return }
        camera.camera?.orthographicScale = max(2.25,3.05/Double(size.width/size.height))
    }
    func targets(in view: SCNView,step: ArkWorkshopStep,inside: Bool) -> [ArkWorkshopPoint] {
        let positions: [SCNVector3]
        if step == .decks { positions = (0..<3).map { SCNVector3(Float($0-1)*0.85,Float($0)*0.56+0.46,0.67) } }
        else { return [] }
        guard view.bounds.width > 0,view.bounds.height > 0 else { return [] }
        return positions.map { p in
            let screen = view.projectPoint(ark.convertPosition(p,to: nil))
            return ArkWorkshopPoint(x: Double(CGFloat(screen.x)/view.bounds.width),y: Double(CGFloat(screen.y)/view.bounds.height))
        }
    }
    func sync(_ round: ArkWorkshopRound,animated: Bool) {
        let signature = "\(round.phase == .intro)-\(round.wood.sorted())-\(round.decks.sorted())-\(round.inside)-\(round.step.rawValue)-\(round.discoveries)"
        guard signature != previousSignature else { return }; previousSignature = signature
        let preview = round.phase == .intro
        SCNTransaction.begin(); SCNTransaction.animationDuration = animated ? 0.55 : 0
        for index in 0..<3 {
            let placed = preview || round.wood.count*3 > index*ArkWorkshopRound.timberCount
            timberGroups[index].opacity = placed ? 1 : 0.07
            timberGroups[index].position.y = placed ? 0 : 0.28
            deckNodes[index].opacity = preview || round.decks.contains(index) ? 1 : 0
            deckNodes[index].position.y = Float(index)*0.56+0.42+(round.decks.contains(index) || preview ? 0 : 0.3)
            ghostNodes[index].opacity = round.step == .decks && !round.decks.contains(index) ? 0.45 : 0
        }
        let painting = round.step == .pitch
        paintSurfaces[0].isHidden = !(preview || painting) || (painting && round.inside && round.discoveries < 3)
        paintSurfaces[1].isHidden = !painting || !round.inside
        camera.position = painting && round.inside && round.discoveries < 3 ? SCNVector3(3.2,8,4.8) : painting ? SCNVector3(3.1,2.9,8.8) : SCNVector3(5.6,4.2,7.6)
        camera.look(at: SCNVector3(0,0.9,0))
        roof.opacity = preview || round.discoveries == 3 ? 1 : 0
        roof.position.y = preview || round.discoveries == 3 ? 0 : 0.4
        SCNTransaction.commit()
    }
    func resetPaint() {
        previousUV = nil
        let base = Self.wood(base: UIColor(red: 0.67,green: 0.40,blue: 0.22,alpha: 1)).diffuse.contents as! UIImage
        paintImages = (0..<2).map { _ in UIGraphicsImageRenderer(size: CGSize(width: 512,height: 256)).image { _ in base.draw(in: CGRect(x: 0,y: 0,width: 512,height: 256)) } }
        for side in 0..<paintSurfaces.count { paintSurfaces[side].geometry?.firstMaterial?.diffuse.contents = paintImages[side] }
    }
    func endPaintStroke() { previousUV = nil }
    func paintUV(at point: ArkWorkshopPoint,in view: SCNView,inside: Bool) -> CGPoint? {
        guard point.finite,(0...1).contains(point.x),(0...1).contains(point.y) else { return nil }
        let hits = view.hitTest(CGPoint(x: point.x*view.bounds.width,y: point.y*view.bounds.height),options: [.categoryBitMask: 4,.searchMode: SCNHitTestSearchMode.all.rawValue])
        return hits.first(where: { $0.node.name == "ark-paint-\(inside ? 1 : 0)" })?.textureCoordinates(withMappingChannel: 0)
    }
    func applyPaint(_ samples: [CGPoint?],inside: Bool,color: ArkPaintColor) {
        guard !samples.isEmpty else { return }
        let side = inside ? 1 : 0
        let image = UIGraphicsImageRenderer(size: CGSize(width: 512,height: 256)).image { renderer in
            paintImages[side].draw(at: .zero)
            let ctx = renderer.cgContext
            ctx.setLineCap(.round); ctx.setLineJoin(.round)
            for uv in samples {
                guard let uv else { previousUV = nil; continue }
                let to = CGPoint(x: uv.x*512,y: (1-uv.y)*256)
                let from = previousUV.map { CGPoint(x: $0.x*512,y: (1-$0.y)*256) } ?? to
                ctx.setStrokeColor(UIColor(Color(hex: color.hex)).withAlphaComponent(0.8).cgColor)
                ctx.setLineWidth(88); ctx.move(to: from); ctx.addLine(to: to); ctx.strokePath()
                if from == to { ctx.setFillColor(UIColor(Color(hex: color.hex)).withAlphaComponent(0.8).cgColor); ctx.fillEllipse(in: CGRect(x: to.x-44,y: to.y-44,width: 88,height: 88)) }
                // Fine translucent bristle marks keep strokes tactile rather than flat stickers.
                ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.08).cgColor); ctx.setLineWidth(0.7)
                for offset in stride(from: -36,through: 36,by: 6) { ctx.move(to: CGPoint(x: from.x,y: from.y+CGFloat(offset))); ctx.addLine(to: CGPoint(x: to.x,y: to.y+CGFloat(offset))); ctx.strokePath() }
                previousUV = uv
            }
        }
        paintImages[side] = image; paintSurfaces[side].geometry?.firstMaterial?.diffuse.contents = image
    }
    func animate(time: Double,celebrating: Bool,reduceMotion: Bool) {
        // Camera stays fixed during play so target positions never drift away from fingers.
        ark.eulerAngles.y = celebrating && !reduceMotion ? Float(sin(time*0.7)*0.08) : 0
    }
    private static func material(_ hex: String,metal: CGFloat = 0) -> SCNMaterial {
        let m = SCNMaterial(); m.diffuse.contents = UIColor(Color(hex: hex)); m.roughness.contents = metal > 0 ? 0.4 : 0.82; m.metalness.contents = metal; m.lightingModel = .physicallyBased; return m
    }
    @discardableResult private static func box(_ parent: SCNNode,size: SCNVector3,at: SCNVector3,material: SCNMaterial,bevel: CGFloat) -> SCNNode {
        let box = SCNBox(width: CGFloat(size.x),height: CGFloat(size.y),length: CGFloat(size.z),chamferRadius: bevel); box.materials = [material]
        let node = SCNNode(geometry: box); node.position = at; parent.addChildNode(node); return node
    }
    private static func wood(base: UIColor) -> SCNMaterial {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512,height: 128))
        let texture = renderer.image { ctx in
            base.setFill(); ctx.fill(CGRect(x: 0,y: 0,width: 512,height: 128))
            for grain in 0..<90 {
                let path = UIBezierPath(); let y = CGFloat(grain)*1.47
                path.move(to: CGPoint(x: 0,y: y))
                for x in stride(from: 0,through: 512,by: 8) { path.addLine(to: CGPoint(x: CGFloat(x),y: y+sin(CGFloat(x)*0.022+CGFloat(grain)*0.39)*1.8)) }
                UIColor.black.withAlphaComponent(grain%4 == 0 ? 0.13 : 0.055).setStroke(); path.lineWidth = grain%5 == 0 ? 1 : 0.5; path.stroke()
            }
        }
        let m = SCNMaterial(); m.diffuse.contents = texture; m.roughness.contents = 0.76; m.lightingModel = .physicallyBased
        m.diffuse.wrapS = .repeat; m.diffuse.wrapT = .repeat; return m
    }
}

final class ArkWorkshopSurface: SCNView {
    var onLayout: (() -> Void)?
    override func layoutSubviews() { super.layoutSubviews(); onLayout?() }
}
struct ArkWorkshopView: UIViewRepresentable {
    @ObservedObject var controller: ArkWorkshopController
    func makeUIView(context: Context) -> ArkWorkshopSurface {
        let view = ArkWorkshopSurface(); view.scene = controller.art.scene; view.pointOfView = controller.art.camera
        view.backgroundColor = .clear; view.isOpaque = false; view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 30; view.rendersContinuously = true; view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        view.onLayout = { [weak view,weak controller] in
            guard let view,let controller else { return }; controller.art.resize(view.bounds.size)
            controller.projectTargets(in: view)
        }
        controller.surface = view
        return view
    }
    func updateUIView(_ view: ArkWorkshopSurface,context: Context) {
        view.isPlaying = controller.round.phase != .paused
        view.rendersContinuously = controller.round.phase != .paused
        controller.art.scene.isPaused = controller.round.phase == .paused
        controller.art.sync(controller.round,animated: !controller.reduceMotion)
        controller.projectTargets(in: view)
    }
    static func dismantleUIView(_ view: ArkWorkshopSurface,coordinator: ()) { view.onLayout = nil; view.scene = nil }
}
