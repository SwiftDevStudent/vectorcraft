import AppKit
import VectorCraftCore

enum ArtworkClipboard {
  static let nativeType = NSPasteboard.PasteboardType("com.swiftdev.vectorcraft.artwork")
  static let svgType = NSPasteboard.PasteboardType("public.svg-image")

  @MainActor static func write(_ fragment: VectorFragment, to pasteboard: NSPasteboard) throws {
    let item = NSPasteboardItem()
    guard item.setData(try fragment.encoded(), forType: nativeType) else {
      throw DrawingError.invalid("Could not prepare the copied artwork.")
    }
    if fragment.drawing.renderingWarnings.isEmpty, !fragment.bounds.isNull {
      let art = try fragment.exportDrawing()
      guard item.setData(try SVGExport.encode(art), forType: svgType),
        item.setData(try PDFExport.encode(art), forType: .pdf)
      else { throw DrawingError.invalid("Could not prepare the artwork's interchange formats.") }
    }
    if fragment.nodes.allSatisfy({ $0.type == "text" }) {
      let text = fragment.nodes.map {
        $0.raw["kind"]["runs"].array.map { $0["text"].string }.joined()
      }.joined(separator: "\n")
      item.setString(text, forType: .string)
    }
    // Finish every representation before changing the system pasteboard.
    pasteboard.clearContents()
    guard pasteboard.writeObjects([item]) else {
      throw DrawingError.invalid("The system clipboard could not accept the artwork.")
    }
  }
}

extension VectorCanvasView: NSUserInterfaceValidations {
  var artworkClipboardReady: Bool {
    textEditor == nil && !state.homePresented && (window == nil || window?.firstResponder === self)
  }
  private var copySelectionAvailable: Bool {
    !state.selection.isEmpty
      && state.selection.allSatisfy {
        drawing.isInside($0, isolation: state.isolationID) && drawing.node($0)?.type != "layer"
      }
  }
  func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
    switch item.action {
    case #selector(copy(_:)): return artworkClipboardReady && copySelectionAvailable
    case #selector(cut(_:)):
      return artworkClipboardReady && copySelectionAvailable
        && state.selection.allSatisfy(drawing.canEdit)
    case #selector(paste(_:)), #selector(pasteInPlace(_:)), #selector(pasteInFront(_:)),
      #selector(pasteInBack(_:)):
      return artworkClipboardReady && drawing.canInsert(on: state.insertionContainer(in: drawing))
        && artworkPasteboard.availableType(from: [
          ArtworkClipboard.nativeType, ArtworkClipboard.svgType, .string, .png, .tiff,
        ]) != nil
    default: return true
    }
  }

  @objc func copy(_ sender: Any?) { copyArtwork(cutting: false) }
  @objc func cut(_ sender: Any?) { copyArtwork(cutting: true) }
  private func copyArtwork(cutting: Bool) {
    guard artworkClipboardReady else { return }
    do {
      let fragment = try VectorFragment(
        copying: state.selection, from: drawing, artboard: state.selectedArtboard,
        within: state.isolationID)
      let copiedIDs = Set(fragment.nodes.map(\.id))
      if cutting {
        var candidate = drawing
        try candidate.perform(.cut(copiedIDs), within: state.isolationID)
      }
      try ArtworkClipboard.write(fragment, to: artworkPasteboard)
      if cutting { command(.cut(copiedIDs)) }
    } catch { state.error = error.localizedDescription }
  }

  @objc func paste(_ sender: Any?) {
    pasteArtwork(.center(toDocument(CGPoint(x: bounds.midX, y: bounds.midY))))
  }
  @objc func pasteInPlace(_ sender: Any?) {
    pasteArtwork(.inPlace(artboard: state.selectedArtboard))
  }
  @objc func pasteInFront(_ sender: Any?) { pasteArtwork(.front) }
  @objc func pasteInBack(_ sender: Any?) { pasteArtwork(.back) }

  func pasteArtwork(_ placement: PastePlacement) {
    guard artworkClipboardReady else { return }
    bitmapPaste.cancel()
    do {
      let edit: DrawingCommand
      if let data = artworkPasteboard.data(forType: ArtworkClipboard.nativeType) {
        edit = .paste(
          try VectorFragment(data: data), placement, container: state.insertionContainer(in: drawing),
          relativeTo: state.selection)
      } else if let data = artworkPasteboard.data(forType: ArtworkClipboard.svgType) {
        edit = .paste(
          try SVGImport.fragment(data), placement, container: state.insertionContainer(in: drawing),
          relativeTo: state.selection)
      } else if let text = artworkPasteboard.string(forType: .string),
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        if SVGImport.recognizes(text) {
          edit = .paste(
            try SVGImport.fragment(Data(text.utf8)), placement, container: state.insertionContainer(in: drawing),
            relativeTo: state.selection)
        } else {
          guard text.utf16.count <= 100_000 else {
            throw DrawingError.invalid("Clipboard text exceeds the 100,000 character limit.")
          }
          guard case .center(let point) = placement else {
            throw DrawingError.invalid(
              "Use Paste to insert plain text. This placement requires copied artwork.")
          }
          edit = .addText(
            text, point, font: state.textFont, size: state.textSize, fill: state.style.fill,
            layer: state.insertionContainer(in: drawing))
        }
      } else if let type = artworkPasteboard.availableType(from: [.png, .tiff]),
        let data = artworkPasteboard.data(forType: type) {
        bitmapPaste.start(data, placement: placement)
        return
      } else {
        throw DrawingError.invalid("The clipboard has no supported artwork, text, PNG or TIFF image.")
      }
      try applyClipboard(edit)
    } catch { state.error = error.localizedDescription }
  }

  func applyClipboard(_ edit: DrawingCommand) throws {
    var candidate = drawing
    try candidate.perform(edit, within: state.isolationID)
    command(edit)
    state.nodeSelection = nil
  }
}

@MainActor
enum ArtworkClipboardAction {
  static var canvas: VectorCanvasView? { NSApp.keyWindow?.firstResponder as? VectorCanvasView }
  static func perform(_ action: Selector) {
    guard let canvas else { return }
    NSApp.sendAction(action, to: canvas, from: nil)
  }
}
