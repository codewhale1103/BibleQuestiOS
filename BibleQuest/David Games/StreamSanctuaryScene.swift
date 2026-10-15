import SpriteKit
import UIKit

final class StreamSanctuaryScene: SKScene {
    var onBirdTap: ((Int) -> Void)?
    var reduceMotion = false
    private let backdrop = SKSpriteNode(imageNamed: "StreamSanctuary")
    private let ground = SKNode()
    private let flock = SKNode()
    private let effects = SKNode()
    private let bag = SKSpriteNode(imageNamed: "StreamPouch")
    private let bagShadow = SKShapeNode(ellipseOf: CGSize(width: 150, height: 35))
    private var stones: [Int: SKSpriteNode] = [:]
    private var active: [Int: StreamBirdVisual] = [:]
    private var motes: [SKSpriteNode] = []
    private var mode: StreamGuardRound.Phase = .ready
    private var transitionTime: Double = 0
    private var lastVisualTime: Double = 0
    private var unit: CGFloat = 1
    private let flowTime = SKUniform(name: "u_flowTime", float: 0)
    private static let glow = makeGlow()

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        addChild(backdrop); addChild(ground); addChild(flock); addChild(effects)
        backdrop.zPosition = -100
        ground.zPosition = 0; flock.zPosition = 40; effects.zPosition = 80
        let shader = SKShader(source: """
        void main() {
            vec2 uv = v_tex_coord;
            vec4 base = texture2D(u_texture, uv);
            float water = smoothstep(0.015,0.16,min(base.g-base.r,base.b-base.r*0.84));
            float t = u_flowTime;
            vec2 drift = vec2(sin(uv.y*97.0+t*0.73),cos(uv.x*83.0-t*0.41))*0.0018*water;
            vec4 color = texture2D(u_texture,uv+drift);
            float ripple = sin((uv.x+uv.y*0.53)*440.0+t*1.4+sin(uv.y*91.0-t*0.45)*2.0);
            float light = pow(max(0.0,ripple),24.0)*0.023*water;
            color.rgb += vec3(0.68,0.96,0.88)*light;
            gl_FragColor = color * v_color_mix.a;
        }
        """)
        shader.addUniform(flowTime); backdrop.shader = shader
        bag.zPosition = 20; ground.addChild(bag)
        bagShadow.fillColor = UIColor.black.withAlphaComponent(0.28); bagShadow.strokeColor = .clear
        bagShadow.zPosition = 1; ground.addChild(bagShadow)
        for index in 0..<17 {
            let mote = SKSpriteNode(texture: Self.glow)
            mote.size = CGSize(width: index.isMultiple(of: 4) ? 9 : 4, height: index.isMultiple(of: 4) ? 9 : 4)
            mote.color = UIColor(red: 1, green: 0.87, blue: 0.51, alpha: 1); mote.colorBlendFactor = 0.75
            mote.blendMode = .add; mote.zPosition = 5
            ground.addChild(mote); motes.append(mote)
        }
        reset()
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didChangeSize(_ oldSize: CGSize) { layout() }
    private var pouchPoint: CGPoint { CGPoint(x: size.width * 0.5, y: size.height * 0.22) }
    private var heroPoint: CGPoint {
        size.width > size.height * 1.3 ? CGPoint(x: size.width * 0.76,y: size.height * 0.51)
            : CGPoint(x: size.width * 0.5,y: size.height * 0.61)
    }
    private func layout() {
        guard size.width > 0, size.height > 0 else { return }
        let source = backdrop.texture?.size() ?? CGSize(width: 1024,height: 1536)
        let fill = max(size.width / source.width,size.height / source.height)
        backdrop.size = CGSize(width: source.width * fill,height: source.height * fill)
        backdrop.position = CGPoint(x: size.width / 2,y: size.height / 2)
        unit = min(1.5,max(0.7,min(size.width / 390,size.height / 720)))
        bag.size = CGSize(width: 192 * unit,height: 192 * unit)
        bag.position = mode == .ready ? heroPoint : pouchPoint
        bagShadow.position = CGPoint(x: bag.position.x,y: bag.position.y - 42 * unit)
        bagShadow.setScale(unit)
        if mode != .ready {
            for (id,stone) in stones { stone.position = stoneSlot(id); stone.setScale(unit) }
        }
    }
    func reset() {
        mode = .ready; transitionTime = 0
        ground.isPaused = false; flock.isPaused = false; effects.isPaused = false
        bag.removeAllActions(); bagShadow.removeAllActions(); bag.zRotation = 0
        flock.removeAllChildren(); effects.removeAllChildren(); active.removeAll()
        stones.values.forEach { $0.removeFromParent() }; stones.removeAll()
        for index in 0..<5 {
            let stone = SKSpriteNode(imageNamed: "StreamRiverStone")
            stone.size = CGSize(width: 49,height: 41)
            stone.zPosition = CGFloat(26 + index)
            stone.color = [UIColor.white,UIColor(red: 0.78,green: 0.89,blue: 0.91,alpha: 1),UIColor(red: 0.9,green: 0.86,blue: 0.73,alpha: 1)][index % 3]
            stone.colorBlendFactor = 0.2
            let glow = SKSpriteNode(texture: Self.glow)
            glow.size = CGSize(width: 82,height: 70); glow.alpha = 0.28
            glow.zPosition = -1; glow.blendMode = .add; glow.name = "halo"
            stone.addChild(glow)
            ground.addChild(stone); stones[index] = stone
        }
        layout()
    }
    func setPhase(_ phase: StreamGuardRound.Phase) {
        let old = mode; mode = phase
        let paused = phase == .paused
        ground.isPaused = paused; flock.isPaused = paused; effects.isPaused = paused
        guard phase == .countdown, old == .ready else { return }
        transitionTime = lastVisualTime
        let duration = reduceMotion ? 0.15 : 0.85
        let move = SKAction.move(to: pouchPoint,duration: duration); move.timingMode = .easeInEaseOut
        bag.run(move)
        bagShadow.run(.move(to: CGPoint(x: pouchPoint.x,y: pouchPoint.y - 42 * unit),duration: duration))
        for (id,stone) in stones {
            let settle = SKAction.move(to: stoneSlot(id),duration: duration + 0.09 * Double(id))
            settle.timingMode = .easeInEaseOut
            stone.run(.group([settle,.scale(to: unit,duration: duration),.rotate(toAngle: CGFloat(id - 2) * 0.15,duration: duration)]))
            stone.childNode(withName: "halo")?.run(.fadeAlpha(to: 0,duration: duration))
        }
    }
    func render(round: StreamGuardRound, time: Double) {
        lastVisualTime = time
        guard mode != .paused else { return }
        flowTime.floatValue = Float(reduceMotion ? time * 0.16 : time)
        if mode == .ready {
            let hero = heroPoint
            bag.position = CGPoint(x: hero.x,y: hero.y + (reduceMotion ? 0 : sin(time * 1.7) * 3 * unit))
            bagShadow.position = CGPoint(x: hero.x,y: hero.y - 42 * unit)
            for (id,stone) in stones {
                let angle = Double(id) / 5 * .pi * 2 + (reduceMotion ? 0 : sin(time * 0.3) * 0.1)
                stone.position = CGPoint(x: hero.x + sin(angle) * 75 * unit,
                                         y: hero.y + 55 * unit + cos(angle) * 27 * unit + (reduceMotion ? 0 : sin(time * 2 + Double(id)) * 5 * unit))
                stone.setScale(unit * (0.9 + cos(angle) * 0.08)); stone.zRotation = CGFloat(sin(angle) * 0.22)
            }
        }
        for (index,mote) in motes.enumerated() {
            let seed = Double(index * 71 + 13)
            let drift = reduceMotion ? 0 : time * (3 + Double(index % 4))
            mote.position = CGPoint(x: (seed * 17 + sin(time * 0.3 + seed) * 16).truncatingRemainder(dividingBy: size.width),
                                    y: (seed * 23 + drift).truncatingRemainder(dividingBy: size.height))
            mote.alpha = CGFloat(0.12 + (sin(time * 0.7 + seed) + 1) * 0.16)
        }
        if round.phase == .playing {
            for bird in round.birds {
                let visual: StreamBirdVisual
                if let current = active[bird.id] { visual = current }
                else {
                    let created = StreamBirdVisual(id: bird.id,variant: bird.variant)
                    active[bird.id] = created; visual = created
                    ground.addChild(created.shadow); flock.addChild(created.node)
                }
                let p = point(bird.position)
                let scale = unit * CGFloat(0.54 + bird.progress * 0.51)
                visual.node.position = p; visual.node.setScale(scale)
                let direction = bird.direction
                visual.node.zRotation = CGFloat(atan2(direction.y * size.height,direction.x * size.width) + .pi / 2)
                visual.node.zPosition = CGFloat(bird.progress * 12)
                visual.shadow.position = CGPoint(x: p.x + 11 * unit,y: p.y - (28 + 25 * (1 - bird.progress)) * unit)
                visual.shadow.setScale(scale * 0.88)
                visual.shadow.alpha = CGFloat(0.11 + bird.progress * 0.10)
                visual.node.warning.alpha = bird.progress > 0.72 ? CGFloat(0.35 + sin(time * 7) * 0.18) : 0
            }
        }
        for case let bird as StreamBirdNode in flock.children { bird.flap(time: time, reduced: reduceMotion) }
    }
    func handle(_ event: StreamGuardRound.Event) {
        switch event {
        case let .shooed(bird,combo,fromCall):
            let p = point(bird.position)
            ripple(at: CGPoint(x: p.x,y: p.y - 25 * unit),gold: false)
            feathers(at: p,count: reduceMotion ? 3 : 7)
            flyAway(bird,stone: nil)
            if !fromCall { label(combo > 1 ? "\(combo) × STEADY" : "+100",at: p) }
        case let .stolen(bird,index):
            let stone = stones.removeValue(forKey: index)
            flyAway(bird,stone: stone)
            label("STONE TAKEN",at: CGPoint(x: pouchPoint.x,y: pouchPoint.y + 85 * unit),warning: true)
            if !reduceMotion {
                bag.run(.sequence([.rotate(byAngle: 0.07,duration: 0.07),.rotate(byAngle: -0.14,duration: 0.1),.rotate(toAngle: 0,duration: 0.12)]))
            }
        case .call:
            let ring = SKShapeNode(circleOfRadius: 22 * unit)
            ring.strokeColor = UIColor(red: 1,green: 0.9,blue: 0.61,alpha: 1)
            ring.lineWidth = 2; ring.glowWidth = 3; ring.fillColor = .clear
            ring.position = pouchPoint; effects.addChild(ring)
            let spread = max(size.width,size.height) / (22 * unit)
            ring.run(.sequence([.group([.scale(to: spread,duration: reduceMotion ? 0.2 : 0.9),.fadeOut(withDuration: 0.9)]),.removeFromParent()]))
        case .won:
            for visual in active.values { visual.shadow.removeFromParent(); visual.node.run(.sequence([.fadeOut(withDuration: 0.4),.removeFromParent()])) }
            active.removeAll()
            ripple(at: pouchPoint,gold: true)
            for (id,stone) in stones {
                let p = CGPoint(x: pouchPoint.x + CGFloat(id - 2) * 34 * unit,y: pouchPoint.y + 90 * unit)
                stone.run(.group([.move(to: p,duration: 0.7),.scale(to: unit * 1.12,duration: 0.7),.rotate(toAngle: 0,duration: 0.7)]))
                stone.childNode(withName: "halo")?.run(.fadeAlpha(to: 0.7,duration: 0.6))
            }
        case .lost:
            for visual in active.values { visual.shadow.removeFromParent(); visual.node.run(.sequence([.fadeOut(withDuration: 0.4),.removeFromParent()])) }
            active.removeAll()
        }
    }
    private func flyAway(_ bird: StreamGuardRound.Bird,stone: SKSpriteNode?) {
        guard let visual = active.removeValue(forKey: bird.id) else { stone?.removeFromParent(); return }
        let node = visual.node
        node.warning.alpha = 0; node.removeAllActions()
        visual.shadow.run(.sequence([.fadeOut(withDuration: 0.25),.removeFromParent()]))
        if let stone {
            let global = ground.convert(stone.position,to: node)
            stone.removeAllActions(); stone.removeFromParent(); node.addChild(stone)
            stone.position = global; stone.zPosition = 5
            stone.run(.group([.move(to: CGPoint(x: 0,y: -27),duration: 0.13),.scale(to: 0.63,duration: 0.13)]))
        }
        let path = CGMutablePath(); path.move(to: node.position)
        let right = bird.id.isMultiple(of: 2)
        let end = CGPoint(x: right ? size.width + 110 : -110,y: size.height + 90)
        path.addCurve(to: end,control1: CGPoint(x: node.position.x + (right ? 100 : -100),y: node.position.y + 65),
                      control2: CGPoint(x: end.x,y: size.height * 0.8))
        let flight = SKAction.follow(path,asOffset: false,orientToPath: false,duration: reduceMotion ? 0.4 : 1.05)
        flight.timingMode = .easeIn
        let rotation = SKAction.rotate(toAngle: right ? .pi * 0.8 : -.pi * 0.8,duration: 0.25,shortestUnitArc: true)
        node.run(.sequence([.group([flight,rotation,.scale(to: unit * 0.75,duration: 1.05)]),.removeFromParent()]))
    }
    private func stoneSlot(_ id: Int) -> CGPoint {
        let x: [CGFloat] = [-30,-11,12,30,5], y: [CGFloat] = [33,42,32,43,53]
        return CGPoint(x: pouchPoint.x + x[id] * unit,y: pouchPoint.y + y[id] * unit)
    }
    private func point(_ p: StreamPoint) -> CGPoint { CGPoint(x: p.x * size.width,y: p.y * size.height) }
    private func ripple(at point: CGPoint,gold: Bool) {
        for index in 0..<(reduceMotion ? 1 : 3) {
            let ring = SKShapeNode(ellipseOf: CGSize(width: 36,height: 13))
            ring.position = point; ring.lineWidth = 1.5
            ring.fillColor = .clear
            ring.strokeColor = gold ? UIColor(red: 1,green: 0.88,blue: 0.54,alpha: 0.8) : UIColor(red: 0.84,green: 1,blue: 0.97,alpha: 0.65)
            ring.alpha = 0; ground.addChild(ring); ring.zPosition = 4
            ring.run(.sequence([.wait(forDuration: Double(index) * 0.12),.fadeAlpha(to: 1,duration: 0.05),
                                .group([.scale(to: gold ? 9 : 3.7,duration: 0.95),.fadeOut(withDuration: 0.95)]),.removeFromParent()]))
        }
    }
    private func label(_ text: String,at point: CGPoint,warning: Bool = false) {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text; label.fontSize = warning ? 10 : 11
        label.fontColor = warning ? UIColor(red: 1,green: 0.83,blue: 0.64,alpha: 1) : UIColor(red: 1,green: 0.95,blue: 0.77,alpha: 1)
        label.position = CGPoint(x: point.x,y: point.y + 35 * unit)
        effects.addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0,y: reduceMotion ? 0 : 27,duration: 0.8),.sequence([.wait(forDuration: 0.35),.fadeOut(withDuration: 0.45)])]),.removeFromParent()]))
    }
    private func feathers(at point: CGPoint,count: Int) {
        for index in 0..<count {
            let feather = SKShapeNode(ellipseOf: CGSize(width: 3,height: 10))
            feather.fillColor = index.isMultiple(of: 2) ? UIColor(red: 0.81,green: 0.89,blue: 0.87,alpha: 0.8) : UIColor(red: 0.34,green: 0.5,blue: 0.57,alpha: 0.8)
            feather.strokeColor = .clear; feather.position = point; feather.zRotation = CGFloat(index)
            effects.addChild(feather)
            let angle = Double(index) / Double(count) * .pi * 2
            feather.run(.sequence([.group([.moveBy(x: sin(angle) * 38,y: cos(angle) * 28,duration: 0.65),.rotate(byAngle: 2,duration: 0.65),.fadeOut(withDuration: 0.65)]),.removeFromParent()]))
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>,with event: UIEvent?) {
        guard mode == .playing, let touch = touches.first else { return }
        let point = touch.location(in: self)
        if let visual = active.values.sorted(by: { $0.node.zPosition > $1.node.zPosition }).first(where: {
            hypot($0.node.position.x - point.x,$0.node.position.y - point.y) < 48 * unit
        }) { onBirdTap?(visual.node.birdID) }
        else { ripple(at: point,gold: false) }
    }
    private static func makeGlow() -> SKTexture {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 96,height: 96)).image { renderer in
            let colors = [UIColor(red: 1,green: 0.91,blue: 0.62,alpha: 0.8).cgColor,UIColor.clear.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),colors: colors,locations: [0,1])!
            renderer.cgContext.drawRadialGradient(gradient,startCenter: CGPoint(x: 48,y: 48),startRadius: 0,endCenter: CGPoint(x: 48,y: 48),endRadius: 48,options: [])
        }
        return SKTexture(image: image)
    }
}

private final class StreamBirdVisual {
    let node: StreamBirdNode
    let shadow = SKShapeNode(ellipseOf: CGSize(width: 71,height: 21))
    init(id: Int,variant: Int) {
        node = StreamBirdNode(id: id,variant: variant)
        shadow.fillColor = .black; shadow.strokeColor = .clear; shadow.zPosition = 6
    }
}

private final class StreamBirdNode: SKNode {
    let birdID: Int
    private let left = SKSpriteNode(imageNamed: "StreamBirdWing")
    private let right = SKSpriteNode(imageNamed: "StreamBirdWing")
    let warning = SKShapeNode(ellipseOf: CGSize(width: 71,height: 25))
    init(id: Int,variant: Int) {
        birdID = id
        super.init()
        let body = SKSpriteNode(imageNamed: "StreamBirdBody")
        body.size = CGSize(width: 59,height: 83); body.zPosition = 2
        body.colorBlendFactor = 0.12
        body.color = variant == 1 ? UIColor(red: 0.66,green: 0.80,blue: 0.87,alpha: 1) : .white
        addChild(body)
        for (index,wing) in [left,right].enumerated() {
            wing.size = CGSize(width: 79,height: 49); wing.anchorPoint = CGPoint(x: 0.90,y: 0.5)
            wing.position = CGPoint(x: index == 0 ? -11 : 11,y: 8); wing.zPosition = 1
            addChild(wing)
        }
        warning.strokeColor = UIColor(red: 1,green: 0.82,blue: 0.46,alpha: 1)
        warning.fillColor = .clear; warning.lineWidth = 1.5
        warning.position.y = -42; warning.alpha = 0; warning.zPosition = -1
        addChild(warning)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func flap(time: Double,reduced: Bool) {
        let phase = time * (reduced ? 4 : 16) + Double(birdID) * 1.7
        let reach = CGFloat(0.70 + sin(phase) * 0.29)
        left.xScale = reach; right.xScale = -reach
        left.yScale = CGFloat(0.95 + cos(phase) * 0.19); right.yScale = left.yScale
        left.zRotation = CGFloat(sin(phase + 0.3) * 0.17); right.zRotation = -left.zRotation
    }
}
