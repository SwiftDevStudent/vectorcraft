import AppKit
import QuartzCore

struct CanvasZoomTransition {
  let from: CGFloat
  let to: CGFloat
  let start: TimeInterval
  static let duration = 0.09

  func value(at time: TimeInterval) -> CGFloat {
    let t = min(1, max(0, (time - start) / Self.duration))
    let eased = 1 - pow(1 - t, 3)
    return exp(log(from) + (log(to) - log(from)) * eased)
  }
  func finished(at time: TimeInterval) -> Bool { time >= start + Self.duration }
}

@MainActor
final class CanvasZoomAnimator: NSObject {
  private weak var view: NSView?
  private var link: CADisplayLink?
  private var transition: CanvasZoomTransition?
  private var anchor = CGPoint.zero
  private let apply: (CGFloat, CGPoint) -> Void
  var target: CGFloat? { transition?.to }

  init(view: NSView, apply: @escaping (CGFloat, CGPoint) -> Void) {
    self.view = view; self.apply = apply
  }
  func animate(from: CGFloat, to: CGFloat, at anchor: CGPoint) {
    guard to.isFinite else { return }
    self.anchor = anchor
    transition = CanvasZoomTransition(from: from, to: min(128, max(0.005, to)), start: CACurrentMediaTime())
    if link == nil {
      link = view?.displayLink(target: self, selector: #selector(tick))
      link?.add(to: .main, forMode: .common)
    }
  }
  func stop() {
    link?.invalidate(); link = nil; transition = nil
  }
  @objc private func tick(_ sender: CADisplayLink) {
    advance(at: CACurrentMediaTime())
  }
  func advance(at time: TimeInterval) {
    guard let transition else { stop(); return }
    apply(transition.value(at: time), anchor)
    if transition.finished(at: time) { stop() }
  }
}
