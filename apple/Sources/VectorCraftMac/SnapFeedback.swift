import AppKit

/// Let AppKit suppress feedback based on the actual input device and drag history.
@MainActor
final class SnapFeedback {
  private var filter = NSAlignmentFeedbackFilter()
  private var previous: CGPoint?

  func begin(at point: CGPoint, event: NSEvent?) {
    filter = NSAlignmentFeedbackFilter()
    previous = point
    update(event)
  }

  func move(raw: CGPoint, aligned: CGPoint, in view: NSView?, event: NSEvent?, enabled: Bool) {
    update(event)
    defer { previous = aligned }
    guard enabled, let previous, raw != aligned,
      let token = filter.alignmentFeedbackTokenForMovement(
        in: view, previousPoint: previous, alignedPoint: aligned, defaultPoint: raw)
    else { return }
    filter.performFeedback([token], performanceTime: .drawCompleted)
  }

  func end() { previous = nil }

  private func update(_ event: NSEvent?) {
    if let event,
      NSAlignmentFeedbackFilter.inputEventMask.contains(
        NSEvent.EventTypeMask(rawValue: 1 << event.type.rawValue))
    {
      filter.update(with: event)
    }
  }
}
