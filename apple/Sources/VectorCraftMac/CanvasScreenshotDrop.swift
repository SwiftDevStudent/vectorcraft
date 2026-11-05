import AppKit
import VectorCraftCore

extension VectorCanvasView {
  override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
    draggingUpdated(sender)
  }
  override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
    let urls = screenshotURLs(sender.draggingPasteboard)
    let point = toDocument(convert(sender.draggingLocation, from: nil))
    screenshotDropTarget =
      urls.isEmpty ? nil : drawing.screenshotSlots.first { $0.rect.contains(point) }
    needsDisplay = true
    return screenshotDropTarget == nil ? [] : .copy
  }
  override func draggingExited(_ sender: (any NSDraggingInfo)?) {
    screenshotDropTarget = nil
    needsDisplay = true
  }
  override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
    let point = toDocument(convert(sender.draggingLocation, from: nil))
    defer {
      screenshotDropTarget = nil
      needsDisplay = true
    }
    return acceptScreenshotFiles(screenshotURLs(sender.draggingPasteboard), at: point)
  }
  func acceptScreenshotFiles(_ urls: [URL], at point: CGPoint) -> Bool {
    guard !urls.isEmpty, urls.count <= 10,
      let target = drawing.screenshotSlots.first(where: { $0.rect.contains(point) })
    else { return false }
    do {
      let items = try urls.map(ScreenshotDropItem.image)
      command(try ScreenshotDropItem.command(items, target: target))
      return true
    } catch {
      state.error = error.localizedDescription
      return false
    }
  }
  private func screenshotURLs(_ pasteboard: NSPasteboard) -> [URL] {
    let values =
      pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
      as? [URL] ?? []
    guard values.count <= 10,
      values.allSatisfy({ ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }) else { return [] }
    return values
  }
}
