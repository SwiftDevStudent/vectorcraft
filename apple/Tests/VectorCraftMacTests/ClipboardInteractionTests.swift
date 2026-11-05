import AppKit
import ImageIO
import Testing
import UniformTypeIdentifiers
import VectorCraftCore

@testable import VectorCraftMac

@MainActor
struct ClipboardInteractionTests {
  @Test func bitmapClipboardEnablesPasteAndUsesOneNativeUndoAction() async throws {
    let f = try Fixture()
    let original = f.document.drawing, bytes = try bitmapData()
    f.pasteboard.setData(bytes, forType: .png)
    let item = NSMenuItem(title: "Paste", action: #selector(VectorCanvasView.paste(_:)), keyEquivalent: "")
    #expect(f.canvas.validateUserInterfaceItem(item))
    f.canvas.paste(nil)
    #expect(f.document.drawing == original)
    await f.canvas.bitmapPaste.task?.value
    let id = try #require(f.state.selection.first)
    let node = try #require(f.document.drawing.node(id))
    #expect(node.type == "image" && node.bounds == CGRect(x: 398, y: 399, width: 4, height: 2))
    #expect(VectorImage.data(node, images: f.document.drawing.envelope["images"]) == bytes)
    #expect(f.undo.undoActionName == "Paste" && f.state.error == nil)
    let pasted = f.document.drawing
    f.undo.undo()
    #expect(f.document.drawing == original)
    f.undo.redo()
    #expect(f.document.drawing == pasted)
  }

  @Test func bitmapPasteKeepsIsolationAndRejectsChangedOrClosedTargets() async throws {
    let f = try Fixture(), bytes = try bitmapData()
    let group = try #require(try f.document.drawing.perform(.group([f.first, f.second])).first)
    f.sync()
    #expect(f.state.enterIsolation(group, in: f.document.drawing))
    f.pasteboard.setData(bytes, forType: .png)
    f.canvas.pasteInPlace(nil)
    await f.canvas.bitmapPaste.task?.value
    let id = try #require(f.state.selection.first)
    #expect(f.document.drawing.node(group)?.children.contains(where: { $0.id == id }) == true)
    #expect(f.document.drawing.node(id)?.bounds.origin == .zero)
    f.canvas.paste(nil)
    let work = f.canvas.bitmapPaste.task
    f.document.drawing.updateNode(group) { $0["name"] = .string("Changed while preparing") }
    f.sync()
    let changed = f.document.drawing
    await work?.value
    #expect(f.document.drawing == changed && f.state.error != nil)
    f.state.error = nil
    f.canvas.paste(nil)
    let closing = f.canvas.bitmapPaste.task
    CanvasRepresentable.dismantleNSView(f.canvas, coordinator: ())
    await closing?.value
    #expect(f.document.drawing == changed && f.state.error == nil)
  }

  @Test func bitmapReplacementAndPlainTextNeverReplayAnEarlierPendingPaste() async throws {
    let f = try Fixture(), original = f.document.drawing
    f.pasteboard.setData(try bitmapData(), forType: .png)
    f.canvas.paste(nil)
    let pending = f.canvas.bitmapPaste.task
    f.pasteboard.setString("Actual text wins", forType: .string)
    f.canvas.paste(nil)
    await pending?.value
    let id = try #require(f.state.selection.first)
    #expect(f.document.drawing.node(id)?.type == "text")
    #expect(f.document.drawing.layers.first?.children.count == 3)
    f.undo.undo()
    #expect(f.document.drawing == original)
    f.sync()
    f.pasteboard.clearContents()
    f.pasteboard.setData(Data("damaged bitmap".utf8), forType: .png)
    f.canvas.paste(nil)
    await f.canvas.bitmapPaste.task?.value
    #expect(f.document.drawing == original && f.state.error != nil)
  }

  private func bitmapData() throws -> Data {
    let context = try #require(CGContext(data: nil, width: 4, height: 2, bitsPerComponent: 8,
      bytesPerRow: 16, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 4, height: 2))
    let bytes = NSMutableData()
    let output = try #require(CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(output, try #require(context.makeImage()), nil)
    #expect(CGImageDestinationFinalize(output))
    return bytes as Data
  }

  @Test func svgTextPastePreservesIsolationAndMalformedSVGNeverFallsBack() throws {
    let f = try Fixture()
    let group = try #require(try f.document.drawing.perform(.group([f.first, f.second])).first)
    f.sync()
    #expect(f.state.enterIsolation(group, in: f.document.drawing))
    let original = f.document.drawing
    f.pasteboard.setString(
      "<?xml version='1.0'?><svg width='100pt' height='80pt' viewBox='0 0 100 80'><path d='M10 20h40v30z'/></svg>",
      forType: .string)
    f.canvas.pasteInPlace(nil)
    let id = try #require(f.state.selection.first)
    #expect(f.document.drawing.node(group)?.children.contains(where: { $0.id == id }) == true)
    #expect(abs((f.document.drawing.node(id)?.bounds.minX ?? -1) - 10) < 0.000001)
    f.undo.undo()
    f.sync()
    #expect(f.document.drawing == original)
    f.pasteboard.clearContents()
    f.pasteboard.setData(
      Data(
        "<svg><rect width='10' height='10'/><image href='https://example.com/not-loaded.png'/></svg>"
          .utf8), forType: ArtworkClipboard.svgType)
    f.pasteboard.setString("Do not use this fallback", forType: .string)
    f.canvas.paste(nil)
    #expect(f.document.drawing == original && f.state.error != nil && !f.undo.canUndo)
  }

  @Test func externalSVGClipboardImportsEditablePathsAndUndoIsAtomic() throws {
    let f = try Fixture()
    let original = f.document.drawing
    f.pasteboard.setData(
      Data(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100pt\" height=\"80pt\" viewBox=\"0 0 100 80\"><rect x=\"10\" y=\"20\" width=\"40\" height=\"30\" fill=\"#ff0000\"/></svg>"
          .utf8),
      forType: ArtworkClipboard.svgType)
    let item = NSMenuItem(
      title: "Paste", action: #selector(VectorCanvasView.paste(_:)), keyEquivalent: "")
    #expect(f.canvas.validateUserInterfaceItem(item))
    f.canvas.paste(nil)
    let id = try #require(f.state.selection.first)
    let node = try #require(f.document.drawing.node(id))
    #expect(node.type == "path" && node.bounds.width == 40 && node.bounds.height == 30)
    #expect(node.bounds.midX == 400 && node.bounds.midY == 400)
    #expect(node.raw["appearance"]["items"].array.first?["paint"] == VectorStyle.solid(1, 0, 0))
    #expect(f.state.error == nil && f.undo.undoActionName == "Paste")
    f.undo.undo()
    #expect(f.document.drawing == original)
  }

  @Test func nativeResponderCopyPasteAndCutUseLosslessFragmentsAndOneUndoAction() throws {
    let f = try Fixture()
    let original = f.document.drawing
    f.state.selection = [f.first]
    #expect(f.canvas.tryToPerform(NSSelectorFromString("copy:"), with: nil))
    #expect(f.document.drawing == original && !f.undo.canUndo)
    #expect(f.pasteboard.data(forType: ArtworkClipboard.nativeType) != nil)
    let svg = try #require(f.pasteboard.string(forType: ArtworkClipboard.svgType))
    #expect(svg.contains("<svg") && !svg.contains("400.0 30.0"))
    #expect(f.pasteboard.data(forType: .pdf)?.starts(with: Data("%PDF".utf8)) == true)
    #expect(f.canvas.tryToPerform(NSSelectorFromString("paste:"), with: nil))
    let pasted = try #require(f.state.selection.first)
    let bounds = try #require(f.document.drawing.node(pasted)?.bounds)
    #expect(abs(bounds.midX - 400) < 0.000001 && abs(bounds.midY - 400) < 0.000001)
    #expect(f.undo.undoActionName == "Paste")
    let saved = f.document.drawing
    f.undo.undo()
    #expect(f.document.drawing == original)
    f.undo.redo()
    #expect(f.document.drawing == saved)
    f.sync()
    f.state.selection = [f.first]
    #expect(f.canvas.tryToPerform(NSSelectorFromString("cut:"), with: nil))
    #expect(f.document.drawing.node(f.first) == nil)
    #expect(f.undo.undoActionName == "Cut")
    f.undo.undo()
    #expect(f.document.drawing == saved)
    #expect(f.state.error == nil)
  }

  @Test func clipboardReplacementPlainTextAndMalformedNativeNeverReuseStaleArtwork() throws {
    let f = try Fixture()
    f.state.selection = [f.first]
    f.canvas.copy(nil)
    f.pasteboard.clearContents()
    f.pasteboard.setString("שלום clipboard 👋", forType: .string)
    f.canvas.paste(nil)
    let id = try #require(f.state.selection.first)
    #expect(f.document.drawing.node(id)?.type == "text")
    #expect(
      f.document.drawing.node(id)?.raw["kind"]["runs"].array.first?["text"].string
        == "שלום clipboard 👋")
    let before = f.document.drawing
    f.pasteboard.clearContents()
    f.pasteboard.setData(Data("damaged".utf8), forType: ArtworkClipboard.nativeType)
    f.pasteboard.setString("Do not fall back", forType: .string)
    f.canvas.paste(nil)
    #expect(f.document.drawing == before && f.state.error != nil)
    f.pasteboard.clearContents()
    f.canvas.paste(nil)
    #expect(f.document.drawing == before)
  }

  @Test func cutFailureLeavesClipboardAndDocumentIntactAndPasteRespectsIsolation() throws {
    let f = try Fixture()
    f.pasteboard.setString("Keep this clipboard", forType: .string)
    f.document.drawing.updateNode(f.first) { $0["locked"] = .bool(true) }
    f.sync()
    f.state.selection = [f.first]
    let before = f.document.drawing
    f.canvas.cut(nil)
    #expect(f.pasteboard.string(forType: .string) == "Keep this clipboard")
    #expect(f.document.drawing == before && f.state.error != nil)
    f.document.drawing.updateNode(f.first) { $0["locked"] = .bool(false) }
    let group = try #require(try f.document.drawing.perform(.group([f.first, f.second])).first)
    f.sync()
    f.state.selection = [f.first]
    f.canvas.copy(nil)
    #expect(f.state.enterIsolation(group, in: f.document.drawing))
    f.canvas.pasteInPlace(nil)
    let pasted = try #require(f.state.selection.first)
    #expect(f.document.drawing.node(group)?.children.contains(where: { $0.id == pasted }) == true)
    #expect(f.document.drawing.layers.first?.children.count == 1)
  }

  @Test func textFirstResponderKeepsCharacterSelectionAndArtworkActionsAreDisabled() throws {
    let f = try Fixture()
    let window = NSWindow(
      contentRect: f.canvas.bounds, styleMask: [.titled], backing: .buffered, defer: false)
    window.contentView = f.canvas
    defer { window.contentView = nil }
    window.makeFirstResponder(f.canvas)
    #expect(f.state.canvasHasFocus)
    let textID = try #require(
      try f.document.drawing.perform(
        .addText(
          "Edit these characters", CGPoint(x: 100, y: 100), font: "Helvetica", size: 24,
          fill: VectorStyle.solid(0, 0, 0), layer: 1)
      ).first)
    f.sync()
    f.state.selection = [textID]
    f.canvas.beginTextEditing(id: textID)
    let textView = try #require(f.canvas.textEditor?.textView)
    window.makeFirstResponder(textView)
    textView.setSelectedRange(NSRange(location: 0, length: 4))
    #expect(window.firstResponder === textView)
    #expect(!f.state.canvasHasFocus)
    #expect(textView.responds(to: NSSelectorFromString("copy:")))
    #expect(textView.selectedRange() == NSRange(location: 0, length: 4))
    f.pasteboard.setString("Keep this clipboard", forType: .string)
    f.canvas.copy(nil)
    f.canvas.cut(nil)
    #expect(f.pasteboard.string(forType: .string) == "Keep this clipboard")
    #expect(f.pasteboard.data(forType: ArtworkClipboard.nativeType) == nil)
    let item = NSMenuItem(
      title: "Paste in Place", action: #selector(VectorCanvasView.pasteInPlace(_:)),
      keyEquivalent: "")
    #expect(!f.canvas.validateUserInterfaceItem(item))
    let before = f.document.drawing
    f.canvas.pasteInPlace(nil)
    #expect(f.document.drawing == before && f.state.selection == [textID])
    f.canvas.finishTextEditing()
    #expect(f.state.canvasHasFocus)
    let field = NSTextField(string: "Inspector text")
    f.canvas.addSubview(field)
    window.makeFirstResponder(field)
    #expect(!f.state.canvasHasFocus)
    #expect(!f.canvas.validateUserInterfaceItem(item))
    f.canvas.paste(nil)
    #expect(f.document.drawing == before)
  }

  @Test func twoDocumentsSharePasteboardWithFreshIDsAndCompoundCutPromotesWholeObject() throws {
    let f = try Fixture()
    let other = try Fixture(pasteboard: f.pasteboard)
    let compound = try #require(
      try f.document.drawing.perform(.makeCompound([f.first, f.second])).first)
    f.sync()
    f.state.selection = [f.first]
    f.canvas.cut(nil)
    #expect(f.document.drawing.node(compound) == nil)
    other.canvas.pasteInPlace(nil)
    let pasted = try #require(other.state.selection.first)
    #expect(other.document.drawing.node(pasted)?.type == "compound")
    #expect(other.document.drawing.node(pasted)?.children.count == 2)
    #expect(other.document.drawing.node(other.first) != nil)
    _ = try NativeFormat.decode(NativeFormat.encode(other.document.drawing))
  }

  @MainActor private final class Fixture {
    let document: CanvasDocument
    let state = EditorState()
    let canvas = VectorCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
    let pasteboard: NSPasteboard
    let undo = UndoManager()
    let first: Int64
    let second: Int64
    init(pasteboard: NSPasteboard? = nil) throws {
      self.pasteboard = pasteboard ?? NSPasteboard.withUniqueName()
      var drawing = Drawing()
      first = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 20, y: 30, width: 40, height: 20))], VectorStyle(),
            layer: 1)
        ).first)
      second = try #require(
        try drawing.perform(
          .addPath(
            [ShapePaths.rectangle(CGRect(x: 400, y: 30, width: 40, height: 20))], VectorStyle(),
            layer: 1)
        ).first)
      document = CanvasDocument(drawing: drawing)
      undo.groupsByEvent = false
      canvas.artworkPasteboard = self.pasteboard
      sync()
      canvas.layout()
    }
    func sync() {
      canvas.update(drawing: document.drawing, state: state) { [weak self] edit in
        guard let self else { return }
        do {
          undo.beginUndoGrouping()
          defer { undo.endUndoGrouping() }
          state.selection = try document.execute(edit, undoManager: undo, within: state.isolationID)
          sync()
        } catch { state.error = error.localizedDescription }
      }
    }
  }
}
