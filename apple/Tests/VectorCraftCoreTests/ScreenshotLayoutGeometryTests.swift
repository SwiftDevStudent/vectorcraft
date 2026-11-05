import CoreGraphics
import Testing
@testable import VectorCraftCore

struct ScreenshotLayoutGeometryTests {
  @Test func chooserGeometryMatchesActualDevicePlacementAndEdgeCrops() throws {
    for preset in ["iphone-medium", "ipad-13"] {
      for landscape in [false, true] {
        var drawing = Drawing()
        try drawing.perform(.screenshot(ScreenshotCommand(.addRow, preset: preset)))
        let board = try #require(drawing.screenshotRows.first?.boards.first)
        if landscape { try drawing.perform(.screenshot(ScreenshotCommand(.rotateBoard, board: board.id))) }
        let source = try #require(drawing.node(board.device)?.bounds)
        for layout in ScreenshotTemplate.all {
          var result = drawing
          let expected = ScreenshotTemplate.deviceFrame(layout.id, source: source.size, in: drawing.artboard)
          try result.perform(.screenshot(ScreenshotCommand(.setTemplate, board: board.id, template: layout.id)))
          let actual = try #require(result.node(board.device)?.bounds)
          for (a, b) in zip([actual.minX, actual.minY, actual.width, actual.height],
            [expected.minX, expected.minY, expected.width, expected.height]) {
            #expect(abs(a - b) < 0.00001)
          }
          #expect(abs(actual.width / actual.height - source.width / source.height) < 0.00001)
          if layout.id == "top-crop" { #expect(actual.minY < drawing.artboard.minY) }
          else if layout.id == "bottom-crop" { #expect(actual.maxY > drawing.artboard.maxY) }
          else { #expect(drawing.artboard.insetBy(dx: -0.001, dy: -0.001).contains(actual)) }
        }
      }
    }
  }
}
