import SpriteKit
import UIKit

final class GoliathArenaScene: SKScene {
    var onResize: ((CGSize) -> Void)?
    var reduceMotion = false
    private let backdrop = SKSpriteNode(imageNamed: "GoliathArena")
    private let boss = SKSpriteNode(imageNamed: "GoliathChampion")
    private let fallen = SKSpriteNode(imageNamed: "GoliathFallen")
    private let david = SKSpriteNode(imageNamed: "GoliathDavidReady")
    private let stone = SKSpriteNode(imageNamed: "StreamRiverStone")
    private let sling = SKShapeNode()
    private let slingLight = SKShapeNode()
    private let cords = SKShapeNode()
    private let cordLight = SKShapeNode()
    private let pouch = SKShapeNode(ellipseOf: CGSize(width: 32,height: 15))
    private let trail = SKShapeNode()
    private let bossShadow = SKShapeNode(ellipseOf: CGSize(width: 230,height: 28))
    private let heroShadow = SKShapeNode(ellipseOf: CGSize(width: 100,height: 17))
    private let stoneGlow = SKSpriteNode(texture: GoliathArenaScene.glow)
    private let readyRing = SKShapeNode(circleOfRadius: 44)
    private let cameraRig = SKCameraNode()
    private var guards: [Int: SKSpriteNode] = [:]
    private var rings: [Int: SKShapeNode] = [:]
    private var dots: [SKSpriteNode] = []
    private var motes: [SKSpriteNode] = []
    private var trails: [CGPoint] = []
    private var impacts: [SlingImpactVisual] = []
    private var lastRound = GoliathSlingRound()
    private var time = 0.0
    private var flashTime = -10.0
    private var shotTime = -10.0
    private static let glow = makeGlow()
    private var unit: CGFloat { size.width / 1000 }

    override init(size: CGSize) {
        super.init(size: size); scaleMode = .resizeFill; backgroundColor = .black
        addChild(backdrop); backdrop.zPosition = -100
        for shadow in [bossShadow,heroShadow] { shadow.fillColor = .black.withAlphaComponent(0.25); shadow.strokeColor = .clear; shadow.zPosition = 0; addChild(shadow) }
        boss.zPosition = 20; david.zPosition = 30; fallen.zPosition = 21
        addChild(boss); addChild(fallen); addChild(david); fallen.alpha = 0
        for id in 0..<3 {
            let shield = SKSpriteNode(imageNamed: "GoliathGuardShield"); shield.zPosition = 35; guards[id] = shield; addChild(shield)
            let ring = SKShapeNode(circleOfRadius: 56); ring.fillColor = .clear; ring.strokeColor = Self.gold
            ring.lineWidth = 2; ring.glowWidth = 4; ring.zPosition = 34; rings[id] = ring; addChild(ring)
        }
        sling.strokeColor = UIColor(red: 0.33,green: 0.18,blue: 0.10,alpha: 1); sling.lineCap = .round; sling.lineJoin = .round; sling.zPosition = 43
        slingLight.strokeColor = UIColor(red: 0.68,green: 0.44,blue: 0.24,alpha: 1); slingLight.lineCap = .round; slingLight.lineJoin = .round; slingLight.zPosition = 44
        cords.strokeColor = UIColor(red: 0.29,green: 0.16,blue: 0.10,alpha: 1); cords.lineCap = .round; cords.zPosition = 45
        cordLight.strokeColor = UIColor(red: 0.91,green: 0.72,blue: 0.43,alpha: 1); cordLight.lineCap = .round; cordLight.zPosition = 46
        pouch.fillColor = UIColor(red: 0.32,green: 0.15,blue: 0.08,alpha: 1); pouch.strokeColor = UIColor(red: 0.7,green: 0.48,blue: 0.27,alpha: 1); pouch.zPosition = 47
        for node in [sling,slingLight,cords,cordLight,pouch] { addChild(node) }
        stoneGlow.zPosition = 49; stoneGlow.color = Self.gold; stoneGlow.colorBlendFactor = 0.85; stoneGlow.blendMode = .add; addChild(stoneGlow)
        stone.zPosition = 60; addChild(stone)
        readyRing.fillColor = .clear; readyRing.strokeColor = Self.gold.withAlphaComponent(0.4); readyRing.lineWidth = 1.2; readyRing.zPosition = 40; addChild(readyRing)
        trail.strokeColor = Self.gold.withAlphaComponent(0.65); trail.lineCap = .round; trail.zPosition = 55; trail.glowWidth = 4; addChild(trail)
        for _ in 0..<44 { let dot = SKSpriteNode(texture: Self.glow); dot.zPosition = 50; addChild(dot); dots.append(dot) }
        for index in 0..<25 {
            let mote = SKSpriteNode(texture: Self.glow); mote.zPosition = index%3 == 0 ? 65 : -10; mote.color = Self.gold; mote.colorBlendFactor = 0.7
            addChild(mote); motes.append(mote)
        }
        addChild(cameraRig); camera = cameraRig
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didChangeSize(_ oldSize: CGSize) { guard size.width > 0,size.height > 0 else { return }; onResize?(size) }
    func reset() {
        impacts.forEach { $0.root.removeFromParent() }; impacts.removeAll(); trails.removeAll()
        boss.alpha = 1; fallen.alpha = 0; flashTime = -10; shotTime = -10; time = 0; cameraRig.setScale(1)
    }
    private func p(_ value: SlingPoint) -> CGPoint { CGPoint(x: value.x * unit,y: value.y * unit) }
    private func fit(_ node: SKSpriteNode,height: Double) {
        let source = node.texture?.size() ?? CGSize(width: 1024,height: 1536)
        node.size = CGSize(width: CGFloat(height) * source.width/source.height * unit,height: CGFloat(height)*unit)
    }
    func render(round: GoliathSlingRound,time: Double,dt: Double) {
        self.time = time; lastRound = round
        let arena = round.arena, h = arena.bossHeight
        let source = backdrop.texture?.size() ?? CGSize(width: 1024,height: 1536)
        let fill = max(size.width/source.width,size.height/source.height)
        backdrop.size = CGSize(width: source.width*fill,height: source.height*fill); backdrop.position = CGPoint(x: size.width/2,y: size.height/2)
        let intro = round.phase == .intro
        let bossCenter = arena.bossCenter + arena.sway(round.clock)
        fit(boss,height: intro ? h*1.13 : h)
        boss.position = intro ? CGPoint(x: size.width*(arena.wide ? 0.76 : 0.63),y: size.height*(arena.wide ? 0.52 : 0.61)) : p(bossCenter)
        let hitAge = time-flashTime
        boss.color = .white; boss.colorBlendFactor = hitAge < 0.14 ? CGFloat((1-hitAge/0.14)*0.65) : 0
        boss.zRotation = reduceMotion ? 0 : CGFloat(sin(hitAge*32)*exp(-hitAge*9)*0.05)
        let topple = round.phase == .toppling || round.phase == .won
        let toppleAge = round.phase == .won ? 2.7 : round.phaseTime
        let fall = topple ? min(1,max(0,(toppleAge-0.12)/0.85)) : 0
        if topple && !reduceMotion {
            boss.zRotation = CGFloat(-fall*0.85)
            boss.position.x += CGFloat(fall*h*0.10)*unit; boss.position.y -= CGFloat(fall*h*0.15)*unit
        }
        boss.alpha = CGFloat(1-min(1,max(0,(fall-0.5)*2)))
        fit(fallen,height: h*1.05)
        fallen.position = p(SlingPoint(x: arena.width*0.61,y: arena.ground+h*0.14))
        fallen.alpha = CGFloat(topple ? min(1,max(0,(fall-0.35)/0.65)) : 0)
        bossShadow.position = p(SlingPoint(x: bossCenter.x,y: arena.bossCenter.y-h*0.45)); bossShadow.setScale(unit*(intro ? 1.2 : 1))
        bossShadow.alpha = topple ? 0.12 : 0.24
        let heroHeight = max(100,min(h*0.66,(arena.anchor.y-arena.ground-25)/0.60))
        fit(david,height: heroHeight)
        david.position = p(SlingPoint(x: arena.anchor.x-heroHeight*0.27,y: arena.ground+heroHeight*0.45))
        david.isHidden = intro
        if !reduceMotion { david.zRotation = CGFloat(-exp(-max(0,time-shotTime)*7)*sin(max(0,time-shotTime)*24)*0.05) }
        heroShadow.position = p(SlingPoint(x: arena.anchor.x-heroHeight*0.27,y: arena.ground)); heroShadow.setScale(unit); heroShadow.isHidden = intro
        let prediction = round.prediction()
        for id in 0..<3 {
            let target = p(arena.target(id,clock: round.clock))
            guards[id]?.position = target; guards[id]?.size = CGSize(width: arena.guardRadius*2.2*unit,height: arena.guardRadius*2.2*unit)
            guards[id]?.isHidden = intro || round.broken.contains(id) || topple
            rings[id]?.position = target; rings[id]?.setScale(CGFloat(arena.guardRadius/52)*unit)
            rings[id]?.isHidden = intro || round.broken.contains(id) || topple
            rings[id]?.alpha = prediction.target == id ? 0.95 : 0.18
        }
        drawSling(round)
        for (index,dot) in dots.enumerated() {
            guard index < prediction.points.count,!intro else { dot.isHidden = true; continue }
            dot.isHidden = false; dot.position = p(prediction.points[index])
            let fade = 1-Double(index)/Double(max(1,prediction.points.count))
            dot.size = CGSize(width: (8+fade*10)*unit,height: (8+fade*10)*unit)
            dot.alpha = CGFloat(fade*0.62); dot.color = prediction.target == nil ? .white : Self.gold; dot.colorBlendFactor = 0.8
        }
        stone.isHidden = intro || (round.phase != .ready && round.flight == nil)
        let stoneUnit = unit * min(1,arena.bossHeight/700)
        stone.size = CGSize(width: 34*stoneUnit,height: 29*stoneUnit)
        stone.position = p(round.flight?.position ?? round.pouch)
        stone.zRotation = round.phase == .flight ? CGFloat(time*16) : 0
        if let flight = round.flight {
            trails.append(p(flight.position)); if trails.count > 18 { trails.removeFirst() }
            let path = CGMutablePath(); if let first = trails.first { path.move(to: first); trails.dropFirst().forEach { path.addLine(to: $0) } }
            trail.path = path; trail.lineWidth = 5*unit; trail.alpha = 0.7
        } else { trail.alpha = max(0,trail.alpha-CGFloat(dt*5)); if trail.alpha == 0 { trails.removeAll(); trail.path = nil } }
        for (index,mote) in motes.enumerated() {
            let i = Double(index), x = (i*71+time*(4+i.truncatingRemainder(dividingBy: 3))).truncatingRemainder(dividingBy: Double(size.width))
            let y = (i*97+time*3).truncatingRemainder(dividingBy: Double(size.height))
            mote.position = CGPoint(x: x,y: y); mote.size = CGSize(width: (index%4 == 0 ? 13 : 6)*unit,height: (index%4 == 0 ? 13 : 6)*unit)
            mote.alpha = reduceMotion ? 0 : CGFloat(0.18+sin(time+i)*0.1)
        }
        for impact in impacts { impact.update(age: time-impact.born,unit: unit,reduced: reduceMotion) }
        impacts.removeAll { impact in if time-impact.born > 1.8 { impact.root.removeFromParent(); return true }; return false }
        let shake = reduceMotion ? 0 : max(0,0.32-hitAge)*12
        cameraRig.position = CGPoint(x: size.width/2+sin(time*73)*shake,y: size.height/2+cos(time*61)*shake*0.6)
        let zoom: CGFloat = round.aiming && !reduceMotion ? 0.98 : 1
        cameraRig.setScale(cameraRig.xScale+(zoom-cameraRig.xScale)*CGFloat(min(1,dt*5)))
    }
    private func drawSling(_ round: GoliathSlingRound) {
        let anchor = p(round.arena.anchor), held = p(round.pouch)
        let u = unit * min(1,round.arena.bossHeight/700)
        let path = CGMutablePath(); path.move(to: CGPoint(x: anchor.x,y: anchor.y-62*u)); path.addLine(to: CGPoint(x: anchor.x,y: anchor.y-5*u))
        path.addLine(to: CGPoint(x: anchor.x-27*u,y: anchor.y+43*u)); path.move(to: CGPoint(x: anchor.x,y: anchor.y-5*u)); path.addLine(to: CGPoint(x: anchor.x+27*u,y: anchor.y+43*u))
        sling.path = path; sling.lineWidth = 16*u; slingLight.path = path; slingLight.lineWidth = 5*u
        let band = CGMutablePath(); band.move(to: CGPoint(x: anchor.x-27*u,y: anchor.y+41*u)); band.addLine(to: held); band.addLine(to: CGPoint(x: anchor.x+27*u,y: anchor.y+41*u))
        cords.path = band; cords.lineWidth = 7*u; cordLight.path = band; cordLight.lineWidth = 2*u
        pouch.position = held; pouch.setScale(u)
        stoneGlow.position = held; stoneGlow.size = CGSize(width: 150*u,height: 150*u)
        stoneGlow.alpha = round.phase == .ready ? (reduceMotion ? 0.32 : CGFloat(0.32+sin(time*3)*0.1)) : 0
        readyRing.position = anchor; readyRing.setScale(u * (reduceMotion ? 1 : 1+sin(time*3)*0.06))
        readyRing.alpha = round.phase == .ready ? 0.75 : 0
        for node in [sling,slingLight,cords,cordLight,pouch] { node.isHidden = round.phase == .intro || round.phase == .toppling || round.phase == .won }
    }
    func event(_ event: GoliathSlingRound.Event) {
        switch event {
        case .launched: shotTime = time; trails.removeAll()
        case let .hit(_,point,perfect,streak):
            flashTime = time
            addImpact(point: point,kind: .shield(perfect,streak))
        case let .missed(point): addImpact(point: point,kind: .dust)
        case .topple: addImpact(point: SlingPoint(x: lastRound.arena.bossCenter.x,y: lastRound.arena.ground+20),kind: .topple)
        default: break
        }
    }
    private func addImpact(point: SlingPoint,kind: SlingImpactVisual.Kind) {
        let effect = SlingImpactVisual(at: p(point),kind: kind,born: time,unit: unit,glow: Self.glow)
        effect.root.zPosition = 85; addChild(effect.root); impacts.append(effect)
    }
    static let gold = UIColor(red: 1,green: 0.80,blue: 0.43,alpha: 1)
    private static func makeGlow() -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 48,height: 48))
        return SKTexture(image: renderer.image { ctx in
            let colors = [UIColor.white.cgColor,UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),colors: colors,locations: [0,1]) {
                ctx.cgContext.drawRadialGradient(gradient,startCenter: CGPoint(x: 24,y: 24),startRadius: 0,endCenter: CGPoint(x: 24,y: 24),endRadius: 24,options: [])
            }
        })
    }
}

private final class SlingImpactVisual {
    enum Kind { case shield(Bool,Int),dust,topple }
    let root = SKNode()
    let born: Double
    private let kind: Kind
    private var particles: [SKSpriteNode] = []
    private let ring = SKShapeNode(circleOfRadius: 25)
    private let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    init(at point: CGPoint,kind: Kind,born: Double,unit: CGFloat,glow: SKTexture) {
        self.kind = kind; self.born = born; root.position = point
        ring.strokeColor = GoliathArenaScene.gold; ring.fillColor = .clear; ring.lineWidth = 2; root.addChild(ring)
        let shield = SKTexture(imageNamed: "GoliathGuardShield")
        for index in 0..<28 {
            let fragment: SKSpriteNode
            if case .shield = kind,index < 9 {
                fragment = SKSpriteNode(texture: SKTexture(rect: CGRect(x: Double(index%3)/3,y: Double(index/3)/3,width: 1.0/3,height: 1.0/3),in: shield))
                fragment.size = CGSize(width: 35,height: 35)
            } else {
                fragment = SKSpriteNode(texture: glow); fragment.color = kind.isDust ? UIColor(red: 0.91,green: 0.76,blue: 0.53,alpha: 1) : GoliathArenaScene.gold
                fragment.colorBlendFactor = 0.9; fragment.size = CGSize(width: kind.isDust ? 65 : 12,height: kind.isDust ? 40 : 12)
            }
            root.addChild(fragment); particles.append(fragment)
        }
        if case let .shield(perfect,streak) = kind { label.text = perfect ? "PERFECT" : streak > 1 ? "\(streak) HIT STREAK" : "GUARD BROKEN" }
        if case .dust = kind { label.text = "SO CLOSE · AIM AGAIN" }
        if case .topple = kind { label.text = "COURAGE WINS" }
        label.fontSize = 39; label.fontColor = .white; label.verticalAlignmentMode = .center; label.zPosition = 10; root.addChild(label)
    }
    func update(age: Double,unit: CGFloat,reduced: Bool) {
        root.setScale(unit)
        let p = min(1,max(0,age/1.5))
        ring.setScale(CGFloat(1+p*3.5)); ring.alpha = CGFloat(max(0,1-age*1.5))
        for (index,node) in particles.enumerated() {
            let angle = Double(index)*2.39996
            let speed = 45+Double(index%7)*24
            let travel = reduced ? 0 : age*speed
            node.position = CGPoint(x: cos(angle)*travel,y: sin(angle)*travel-age*age*(kind.isDust ? -12 : 125))
            node.zRotation = reduced ? 0 : CGFloat(age*Double(index%5-2)*3)
            node.alpha = CGFloat((1-p)*(kind.isDust ? 0.28 : 1))
            if kind.isDust { node.setScale(CGFloat(0.5+p*1.6)) }
        }
        label.position.y = CGFloat(75+(reduced ? 0 : age*28)); label.alpha = CGFloat(min(1,age*10)*max(0,1-(age-0.9)*2))
    }
}
private extension SlingImpactVisual.Kind {
    var isDust: Bool { switch self { case .dust,.topple: return true; default: return false } }
}
