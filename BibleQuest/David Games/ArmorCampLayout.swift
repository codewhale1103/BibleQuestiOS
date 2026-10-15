import CoreGraphics

struct ArmorCampLayout {
    let size: CGSize
    var compact: Bool { size.width > size.height * 1.3 }
    var unit: CGFloat { min(1.45,max(0.7,min(size.width / 390,size.height / 800))) }
    func heroHeight(intro: Bool) -> CGFloat {
        compact ? size.height * (intro ? 0.87 : 0.68) : min(size.height * (intro ? 0.52 : 0.47),size.width * 1.2)
    }
    func heroCenter(intro: Bool) -> CGPoint {
        if compact { return CGPoint(x: size.width * (intro ? 0.76 : 0.56),y: size.height * (intro ? 0.52 : 0.585)) }
        return CGPoint(x: size.width * 0.5,y: size.height * (intro ? 0.39 : 0.465))
    }
    func wornPosition(_ piece: ArmorCampRound.Piece,intro: Bool) -> CGPoint {
        let h = heroHeight(intro: intro), center = heroCenter(intro: intro)
        switch piece {
        case .helmet: return CGPoint(x: center.x,y: center.y - h * 0.35)
        case .breastplate: return CGPoint(x: center.x,y: center.y + h * 0.025)
        case .sword: return CGPoint(x: center.x - h * 0.20,y: center.y + h * 0.06)
        }
    }
    func wornSize(_ piece: ArmorCampRound.Piece,intro: Bool) -> CGSize {
        let h = heroHeight(intro: intro)
        switch piece {
        case .helmet: return CGSize(width: h * 0.43,height: h * 0.32)
        case .breastplate: return CGSize(width: h * 0.49,height: h * 0.36)
        case .sword: return CGSize(width: h * 0.17,height: h * 0.49)
        }
    }
    var standSize: CGSize {
        compact ? CGSize(width: min(size.width * 0.15,145),height: size.height * 0.23)
            : CGSize(width: size.width * 0.285,height: size.height * 0.16)
    }
    func standPosition(_ piece: ArmorCampRound.Piece) -> CGPoint {
        let index = CGFloat(ArmorCampRound.Piece.allCases.firstIndex(of: piece)!)
        if compact { return CGPoint(x: size.width * 0.80,y: size.height * (0.34 + index * 0.235)) }
        return CGPoint(x: size.width * (0.19 + index * 0.31),y: size.height * 0.795)
    }
    func dockPosition(_ piece: ArmorCampRound.Piece) -> CGPoint {
        let p = standPosition(piece)
        return CGPoint(x: p.x,y: p.y - standSize.height * 0.08)
    }
    func dockSize(_ piece: ArmorCampRound.Piece) -> CGSize {
        let s = standSize
        switch piece {
        case .helmet: return CGSize(width: s.width * 0.68,height: s.height * 0.60)
        case .breastplate: return CGSize(width: s.width * 0.72,height: s.height * 0.66)
        case .sword: return CGSize(width: s.width * 0.31,height: s.height * 0.77)
        }
    }
    func stand(at point: CGPoint) -> ArmorCampRound.Piece? {
        ArmorCampRound.Piece.allCases.first { piece in
            let p = standPosition(piece), s = standSize
            return CGRect(x: p.x - s.width * 0.57,y: p.y - s.height * 0.58,width: s.width * 1.14,height: s.height * 1.16).contains(point)
        }
    }
}
