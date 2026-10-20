import Foundation
import CoreGraphics

enum NoahVoyageChapter: Int, CaseIterable, Identifiable {
    case call, build, animals, flood, waiting, dove, promise
    var id: Int { rawValue }
    var title: String { ["God’s Call","Build the Ark","Gather Animals","Flood Begins","40 Days & Nights","The Dove Returns","Rainbow Promise"][rawValue] }
    var subtitle: String { ["A quiet beginning","Faith takes shape","Every kind, together","Safe through the storm","Hope on the horizon","A sign of new life","A world made new"][rawValue] }
    var symbol: String { ["sun.max.fill","hammer.fill","pawprint.fill","water.waves","cloud.rain.fill","bird.fill","rainbow"][rawValue] }
    var passage: String { ["GENESIS 6:9–22","GENESIS 6:14–22","GENESIS 7:1–9","GENESIS 7:10–24","GENESIS 7:12 · 8:1–5","GENESIS 8:6–12","GENESIS 9:8–17"][rawValue] }
    var story: String {
        ["Noah listened when God called him to build an ark. His journey began with trust, long before the first drop of rain.",
         "Piece by piece, Noah and his family built a great wooden ark. Every beam was a step of faith toward a future they could not yet see.",
         "Animals of every kind came into the ark. A place of shelter was ready for Noah’s family and the creatures in their care.",
         "The rain came, and the waters rose. The ark lifted above the land, carrying its precious passengers safely into the great unknown.",
         "Rain fell for forty days and forty nights. Noah and his family stayed in the ark much longer, waiting and trusting God. God remembered Noah, and the waters began to go down.",
         "Noah sent a dove over the water. When it returned with a fresh olive leaf, he knew that new life was growing beyond the ark.",
         "On dry ground again, Noah and his family stepped into a renewed world. God set a rainbow in the clouds as a sign of His covenant with every living creature."][rawValue]
    }
    var landmark: String { rawValue < 3 ? "NoahVoyageShore" : rawValue < 5 ? "NoahVoyageReef" : "NoahVoyageArarat" }
}

/// One source of geometry for the painted route, ark heading, wake, stop positions and scrolling.
struct NoahVoyageRoute {
    static let height: CGFloat = 3500
    static let ys: [CGFloat] = [340,780,1230,1700,2180,2660,3140]
    static let offsets: [CGFloat] = [-70,66,-74,70,-66,62,-20]
    let width: CGFloat
    init(width: CGFloat) { self.width = width.isFinite ? max(1,width) : 390 }
    func stop(_ index: Int) -> CGPoint {
        let i = min(6,max(0,index))
        return CGPoint(x: width/2+Self.offsets[i]*min(1,width/430),y: Self.ys[i])
    }
    func point(_ progress: CGFloat) -> CGPoint {
        let p = (progress.isFinite ? progress : 0).clamped(to: 0...1)*6
        let index = min(5,Int(p)),t = p-CGFloat(index),u = 1-t
        let a = stop(index),b = stop(index+1),mid = (a.y+b.y)/2
        let x = a.x*(u*u*u+3*u*u*t)+b.x*(3*u*t*t+t*t*t)
        let y = a.y*u*u*u+3*mid*u*u*t+3*mid*u*t*t+b.y*t*t*t
        return CGPoint(x: x,y: y)
    }
    func tangent(_ progress: CGFloat) -> CGVector {
        let p = (progress.isFinite ? progress : 0).clamped(to: 0...1)*6
        let index = min(5,Int(p)),t = p-CGFloat(index),u = 1-t
        let a = stop(index),b = stop(index+1),mid = (a.y+b.y)/2
        let dx = 6*u*t*(b.x-a.x)
        let dy = 3*u*u*(mid-a.y)+3*t*t*(b.y-mid)
        let length = max(0.0001,hypot(dx,dy))
        return CGVector(dx: dx/length,dy: dy/length)
    }
    /// Berth a little before each beacon so the ship never hides the chapter button.
    func arkPoint(_ progress: CGFloat) -> CGPoint {
        let p = point(progress),v = tangent(progress)
        return CGPoint(x: p.x-v.dx*108,y: p.y-v.dy*108)
    }
    func heading(_ progress: CGFloat) -> Double {
        let v = tangent(progress)
        return atan2(v.dy,v.dx)-Double.pi/2
    }
    func index(at progress: CGFloat) -> Int {
        Int(((progress.isFinite ? progress : 0).clamped(to: 0...1)*6).rounded()).clamped(to: 0...6)
    }
    static func progress(for index: Int) -> CGFloat { CGFloat(index.clamped(to: 0...6))/6 }
}
