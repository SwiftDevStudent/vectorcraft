import CoreGraphics

/// Derives a screen outline from the enclosed, four-connected transparent component of an
/// unchanged original bezel. Pixel-space geometry is converted to the existing native path.
enum ScreenCavity {
  private struct Edge: Hashable {
    let from: Int
    let to: Int
  }

  private static func alphaPlane(_ image: CGImage) throws -> [UInt8] {
    let width = image.width, height = image.height
    var rgba = [UInt8](repeating: 0, count: width * height * 4)
    try rgba.withUnsafeMutableBytes { bytes in
      guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
        throw DrawingError.invalid("Could not read the original frame transparency.")
      }
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    var alpha = [UInt8](repeating: 0, count: width * height)
    for index in alpha.indices { alpha[index] = rgba[index * 4 + 3] }
    return alpha
  }

  static func path(in image: CGImage, screen: CGRect) throws -> CGPath {
    let width = image.width, height = image.height
    guard width > 0, height > 0, width <= 16384, height <= 16384,
      width * height <= 32_000_000,
      let seedX = Int(exactly: floor(screen.midX)), let seedY = Int(exactly: floor(screen.midY)),
      (0..<width).contains(seedX), (0..<height).contains(seedY) else {
      throw DrawingError.invalid("The frame screen exceeds supported pixel bounds.")
    }
    let alpha = try alphaPlane(image)
    let seed = seedY * width + seedX
    guard alpha[seed] <= 1 else { throw DrawingError.invalid("The measured screen center is not transparent.") }
    var region = [UInt8](repeating: 0, count: alpha.count)
    var pending = [seed]
    var minX = width, maxX = 0, minY = height, maxY = 0
    // Scanline fill keeps work proportional to the cavity without a queue entry per pixel.
    while let seed = pending.popLast() {
      if region[seed] != 0 || alpha[seed] > 1 { continue }
      let y = seed / width, row = y * width
      var left = seed % width, right = left
      while left > 0 && region[row + left - 1] == 0 && alpha[row + left - 1] <= 1 { left -= 1 }
      while right + 1 < width && region[row + right + 1] == 0 && alpha[row + right + 1] <= 1 { right += 1 }
      guard left > 0, right < width - 1, y > 0, y < height - 1 else {
        throw DrawingError.invalid("The screen transparency connects to the frame exterior.")
      }
      for x in left...right { region[row + x] = 1 }
      minX = min(minX, left); maxX = max(maxX, right); minY = min(minY, y); maxY = max(maxY, y)
      for adjacentY in [y - 1, y + 1] {
        var x = left
        while x <= right {
          let index = adjacentY * width + x
          if region[index] == 0 && alpha[index] <= 1 {
            pending.append(index)
            repeat { x += 1 } while x <= right && region[adjacentY * width + x] == 0 && alpha[adjacentY * width + x] <= 1
          } else { x += 1 }
        }
      }
    }
    var frontier: [Int] = []
    for y in minY...maxY {
      for x in minX...maxX {
        let index = y * width + x
        if region[index] != 0 && (region[index - 1] == 0 || region[index + 1] == 0 || region[index - width] == 0 || region[index + width] == 0) {
          frontier.append(index)
        }
      }
    }
    // Cover the original interior antialias edge beneath opaque bezel pixels. Exterior
    // transparent pixels are never admitted, even where screen-bounds corners reach outside.
    for _ in 0..<2 {
      var next: [Int] = []
      for index in frontier {
        if alpha[index] == 255 { continue }
        let x = index % width, y = index / width
        let neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
        for (nx, ny) in neighbors where nx >= 0 && nx < width && ny >= 0 && ny < height {
          let neighbor = ny * width + nx
          if region[neighbor] == 0 && alpha[neighbor] > 1 {
            region[neighbor] = 1; next.append(neighbor)
          }
        }
      }
      frontier = next
    }
    let stride = width + 1
    var edges = Set<Edge>()
    func add(_ from: Int, _ to: Int) throws {
      edges.insert(Edge(from: from, to: to))
      guard edges.count <= 100_000 else { throw DrawingError.invalid("The screen contour is too complex.") }
    }
    for y in max(0, minY - 2)...min(height - 1, maxY + 2) {
      for x in max(0, minX - 2)...min(width - 1, maxX + 2) {
        let index = y * width + x
        guard region[index] != 0 else { continue }
        let topLeft = y * stride + x
        if y == 0 || region[index - width] == 0 { try add(topLeft, topLeft + 1) }
        if x == width - 1 || region[index + 1] == 0 { try add(topLeft + 1, topLeft + stride + 1) }
        if y == height - 1 || region[index + width] == 0 { try add(topLeft + stride + 1, topLeft + stride) }
        if x == 0 || region[index - 1] == 0 { try add(topLeft + stride, topLeft) }
      }
    }
    guard let start = edges.min(by: { ($0.from, $0.to) < ($1.from, $1.to) }) else {
      throw DrawingError.invalid("The frame has no enclosed screen outline.")
    }
    let steps = [1, stride, -1, -stride]
    var edge = start, direction = -1
    var vertices: [Int] = []
    repeat {
      guard edges.remove(edge) != nil, let nextDirection = steps.firstIndex(of: edge.to - edge.from) else {
        throw DrawingError.invalid("Could not trace the screen contour.")
      }
      // Only keep turns; long straight edges do not need one native anchor per pixel.
      if nextDirection != direction { vertices.append(edge.from) }
      direction = nextDirection
      if edge.to == start.from { break }
      let candidates = [(direction + 1) % 4, direction, (direction + 3) % 4, (direction + 2) % 4]
      guard let next = candidates.map({ Edge(from: edge.to, to: edge.to + steps[$0]) }).first(where: { edges.contains($0) }) else {
        throw DrawingError.invalid("The screen outline is not closed.")
      }
      edge = next
    } while true
    let path = CGMutablePath()
    for (index, vertex) in vertices.enumerated() {
      let point = CGPoint(x: vertex % stride, y: vertex / stride)
      if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}
