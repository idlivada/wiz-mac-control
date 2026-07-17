import SwiftUI

enum ColorMath {
    /// h in 0..<1, s and v in 0...1
    static func hsvToRGB(h: Double, s: Double, v: Double) -> RGB {
        let i = Int(h * 6) % 6
        let f = h * 6 - Double(Int(h * 6))
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)
        let (r, g, b): (Double, Double, Double)
        switch i {
        case 0: (r, g, b) = (v, t, p)
        case 1: (r, g, b) = (q, v, p)
        case 2: (r, g, b) = (p, v, t)
        case 3: (r, g, b) = (p, q, v)
        case 4: (r, g, b) = (t, p, v)
        default: (r, g, b) = (v, p, q)
        }
        return RGB(r: Int(round(r * 255)), g: Int(round(g * 255)), b: Int(round(b * 255)))
    }

    static func rgbToHS(_ rgb: RGB) -> (h: Double, s: Double) {
        let r = Double(rgb.r) / 255, g = Double(rgb.g) / 255, b = Double(rgb.b) / 255
        let maxC = max(r, g, b), minC = min(r, g, b)
        let delta = maxC - minC
        guard delta > 0, maxC > 0 else { return (0, 0) }
        var h: Double
        if maxC == r {
            h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxC == g {
            h = (b - r) / delta + 2
        } else {
            h = (r - g) / delta + 4
        }
        h /= 6
        if h < 0 { h += 1 }
        return (h, delta / maxC)
    }
}

struct ColorWheelView: View {
    var rgb: RGB
    var isActive: Bool
    var onChange: (RGB) -> Void

    private let size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .fill(AngularGradient(colors: hueColors, center: .center))
            Circle()
                .fill(RadialGradient(
                    colors: [.white, .white.opacity(0)],
                    center: .center, startRadius: 0, endRadius: size / 2
                ))
            Circle()
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            indicator
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { handle($0.location) }
        )
        .saturation(isActive ? 1 : 0.55)
        .overlay(alignment: .bottomTrailing) {
            if !isActive {
                Text("White mode")
                    .font(.system(size: 9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.thinMaterial, in: Capsule())
                    .offset(x: 6, y: 2)
            }
        }
    }

    private var hueColors: [Color] {
        stride(from: 0.0, through: 1.0, by: 1.0 / 12).map {
            Color(hue: $0, saturation: 1, brightness: 1)
        }
    }

    private var indicator: some View {
        let (h, s) = ColorMath.rgbToHS(rgb)
        let radius = s * (size / 2 - 8)
        let angle = h * 2 * .pi
        return Circle()
            .fill(Color(red: Double(rgb.r) / 255, green: Double(rgb.g) / 255, blue: Double(rgb.b) / 255))
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            .frame(width: 16, height: 16)
            .shadow(radius: 1)
            .offset(x: cos(angle) * radius, y: sin(angle) * radius)
            .opacity(isActive ? 1 : 0)
    }

    private func handle(_ location: CGPoint) {
        let dx = location.x - size / 2
        let dy = location.y - size / 2
        var h = atan2(dy, dx) / (2 * .pi)
        if h < 0 { h += 1 }
        let s = min(1, sqrt(dx * dx + dy * dy) / (size / 2 - 8))
        onChange(ColorMath.hsvToRGB(h: h, s: s, v: 1))
    }
}
