import AppKit
import QuartzCore
import Testing

@testable import VectorCraftMac

@MainActor
struct CanvasZoomTests {
  @Test func zoomMovesThroughIntermediateFramesAndStopsAtItsTarget() {
    let view = NSView()
    var values: [CGFloat] = []
    let anchor = CGPoint(x: 120, y: 80)
    let animator = CanvasZoomAnimator(view: view) { value, point in
      values.append(value)
      #expect(point == anchor)
    }
    let start = CACurrentMediaTime()
    animator.animate(from: 1, to: 2, at: anchor)
    animator.advance(at: start + 0.03)
    animator.advance(at: start + 0.06)
    animator.advance(at: start + 1)
    #expect(values.count == 3)
    #expect(values[0] > 1 && values[0] < values[1] && values[1] < 2)
    #expect(values[2] == 2)
    #expect(animator.target == nil)
    animator.animate(from: 2, to: 4, at: anchor)
    animator.stop()
    animator.advance(at: start + 2)
    #expect(values.count == 3)
  }
}
