// IconGen.swift — renderuje ikonę aplikacji (tarcza) do PNG 1024x1024.
// Użycie: swiftc IconGen.swift -o icongen && ./icongen /ścieżka/icon.png
import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let S = 1024.0

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Tło: zaokrąglony kwadrat z gradientem (granat -> morski)
let inset = S * 0.08
let bg = NSRect(x: inset, y: inset, width: S - 2*inset, height: S - 2*inset)
let path = NSBezierPath(roundedRect: bg, xRadius: S * 0.20, yRadius: S * 0.20)
let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.20, alpha: 1),
    NSColor(calibratedRed: 0.10, green: 0.42, blue: 0.45, alpha: 1)
])!
grad.draw(in: path, angle: -90)

// Tarcza (SF Symbol) na biało, wyśrodkowana
let cfg = NSImage.SymbolConfiguration(pointSize: S * 0.52, weight: .semibold)
if let symBase = NSImage(systemSymbolName: "checkmark.shield.fill", accessibilityDescription: nil),
   let sym = symBase.withSymbolConfiguration(cfg) {
    let tinted = NSImage(size: sym.size)
    tinted.lockFocus()
    sym.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: sym.size).fill(using: .sourceAtop)
    tinted.unlockFocus()
    let sz = sym.size
    tinted.draw(in: NSRect(x: (S - sz.width)/2, y: (S - sz.height)/2, width: sz.width, height: sz.height))
}

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("PNG encode failed\n".data(using: .utf8)!); exit(1)
}
try? data.write(to: URL(fileURLWithPath: outPath))
