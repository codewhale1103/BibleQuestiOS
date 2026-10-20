import SceneKit
import simd

/// A continuous groomed ruff with longitudinal fur flow, rather than stacked rings of petals.
enum RoaringMane {
    static func build(on parent: SCNNode) {
        let dark = BeastArt.texturedMaterial("#BDA99A", image: "RoaringMane", scale: 1, roughness: 0.83)
        let mid = BeastArt.texturedMaterial("#D6B69A", image: "RoaringMane", scale: 1, roughness: 0.81)
        let light = BeastArt.texturedMaterial("#E5C6A8", image: "RoaringMane", scale: 1, roughness: 0.8)
        let rows = 42, columns = 160
        func surface(_ t: Float, _ angle: Float) -> SIMD3<Float> {
            let a = angle + sin(t * .pi) * 0.12
            let fullness = sin(t * .pi)
            let rx = 0.345 + fullness * 0.205 - t * 0.055
            let ry = 0.36 + fullness * 0.24 + t * 0.015
            let wave = sin(a * 17 + t * 5) * 0.011 + sin(a * 29 - t * 3) * 0.005
            let lower = max(0, -cos(a))
            let x = sin(a) * (rx + wave)
            let y = cos(a) * (ry + wave) - 0.035 - lower * fullness * 0.13 - t * 0.09
            let z = -0.27 + t * 0.86
            return SIMD3(x,y,z)
        }
        var vertices: [SIMD3<Float>] = [], indices: [Int32] = [], uv: [CGPoint] = []
        for row in 0...rows {
            let t = Float(row) / Float(rows)
            for col in 0...columns {
                let a = Float(col) / Float(columns) * 2 * .pi
                vertices.append(surface(t,a))
                uv.append(CGPoint(x: CGFloat(col) / CGFloat(columns) * 3, y: CGFloat(t) * 2))
            }
        }
        for row in 0..<rows { for col in 0..<columns {
            let a = Int32(row * (columns + 1) + col), b = a + 1, c = a + Int32(columns + 1), d = c + 1
            indices += [a,c,b,b,c,d]
        }}
        BeastArt.mesh(parent, vertices: vertices, indices: indices, material: dark, uv: uv)
        // Long fine locks lie along the shell; tapered ends gently break its outline.
        // Staggered roots and lengths prevent the repeated scallop pattern of the old mane.
        for index in 0..<120 {
            let angle = Float(index) * 2.399963
            let band = Float(index % 5) / 5
            let startT = 0.015 + band * 0.40
            let endT = min(0.98, startT + 0.34 + Float(index % 7) * 0.035)
            var controls: [SIMD3<Float>] = []
            for j in 0..<4 {
                let u = Float(j) / 3
                let t = startT + (endT - startT) * u
                var p = surface(t, angle + u * 0.06)
                let lift: Float = j == 3 ? 0.026 : 0.008
                p += SIMD3(sin(angle) * lift, cos(angle) * lift, 0)
                controls.append(p)
            }
            let mat = index % 7 == 0 ? light : (index.isMultiple(of: 3) ? dark : mid)
            BeastArt.sweep(parent, controls, radius: 0.005 + Float(index % 3) * 0.001,
                           depth: 0.62, pointed: true, material: mat, sides: 6, steps: 18)
        }
        // Airy silhouette wisps extend backward, never forming a second face-framing ring.
        for index in 0..<64 {
            let a = Float(index) / 64 * 2 * .pi
            let p = surface(0.47,a)
            let tip = surface(0.76,a + 0.025) + SIMD3(sin(a)*0.055,cos(a)*0.055-0.025,0.065)
            BeastArt.sweep(parent,[p,p + SIMD3(sin(a)*0.025,cos(a)*0.025,0.06),tip - SIMD3(0,0,0.06),tip],
                           radius:0.010,depth:0.55,pointed:true,material:index.isMultiple(of:3) ? mid:dark,sides:8,steps:16)
        }
    }
}
