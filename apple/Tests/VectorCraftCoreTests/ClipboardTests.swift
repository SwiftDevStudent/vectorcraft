import CoreGraphics
import Foundation
import Testing

@testable import VectorCraftCore

struct ClipboardTests {
  @Test func pasteInPlaceRetainsTheExactNativeNodeApartFromItsFreshID() throws {
    var source = Drawing()
    let id = try add(&source, x: 20)
    source.updateNode(id) {
      $0["future"] = .object(["paint": .bool(true), "opaque": .string("retained")])
    }
    let fragment = try VectorFragment(copying: [id], from: source)
    var destination = Drawing()
    _ = try add(&destination, x: 400)
    let pasted = try #require(
      try destination.perform(.paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
        .first)
    var expected = try #require(source.node(id)?.raw)
    expected["id"] = .integer(pasted)
    #expect(destination.node(pasted)?.raw == expected)
  }

  @Test func crossDocumentPasteCentersRootsOnceAndPreservesOriginalsAndForeignFields() throws {
    var source = Drawing()
    let a = try add(&source, x: 20)
    let b = try add(&source, x: 120)
    let group = try #require(try source.perform(.group([a, b])).first)
    source.updateNode(a) {
      $0["unknown"] = .object(["swatch": .string("Not a resource"), "id": .integer(999)])
    }
    let before = source
    let fragment = try VectorFragment(
      data: VectorFragment(copying: [group, a], from: source).encoded())
    #expect(fragment.nodes.map(\.id) == [group])
    #expect(fragment.nodes.first?.children.map(\.id) == [a, b])
    var destination = Drawing()
    let old = try add(&destination, x: 400)
    let pasted = try #require(
      try destination.perform(
        .paste(fragment, .center(CGPoint(x: 300, y: 200)), container: 1, relativeTo: [])
      ).first)
    #expect(pasted != old && pasted != 1)
    let children = try #require(destination.node(pasted)?.children)
    #expect(children.map(\.bounds.minX) == [230, 330])
    #expect(children.map(\.bounds.minY) == [190, 190])
    #expect(children.first?.raw["unknown"] == before.node(a)?.raw["unknown"])
    #expect(source == before)
    #expect(destination.node(old)?.bounds.minX == 400)
    let reopened = try NativeFormat.decode(NativeFormat.encode(destination))
    #expect(reopened.envelope["document"] == destination.envelope["document"])
    _ = try SVGExport.encode(reopened)
    _ = try PDFExport.encode(reopened)
  }

  @Test func placementKeepsArtboardRelativePositionAndFrontBackUseSelectedSibling() throws {
    var source = Drawing()
    let a = try add(&source, x: 120)
    source.envelope["document"]["artboards"] = .array([
      .object([
        "id": .integer(1), "rect": CGRect(x: 100, y: 200, width: 800, height: 800).clipboardJSON,
      ])
    ])
    let fragment = try VectorFragment(copying: [a], from: source)
    var destination = Drawing()
    let b = try add(&destination, x: 400)
    let c = try add(&destination, x: 500)
    let group = try #require(try destination.perform(.group([b, c])).first)
    destination.envelope["document"]["artboards"] = .array([
      .object([
        "id": .integer(1), "rect": CGRect(x: 1000, y: 700, width: 800, height: 800).clipboardJSON,
      ])
    ])
    let inPlace = try #require(
      try destination.perform(.paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
        .first)
    #expect(destination.node(inPlace)?.bounds.origin == CGPoint(x: 1020, y: 530))
    let front = try #require(
      try destination.perform(.paste(fragment, .front, container: 1, relativeTo: [b])).first)
    let back = try #require(
      try destination.perform(.paste(fragment, .back, container: 1, relativeTo: [b])).first)
    #expect(destination.node(group)?.children.map(\.id) == [back, b, front, c])
    #expect(destination.node(front)?.bounds.origin == CGPoint(x: 120, y: 30))
    let bottom = try #require(
      try destination.perform(.paste(fragment, .back, container: 1, relativeTo: [])).first)
    #expect(destination.layers.first?.children.first?.id == bottom)
    let top = try #require(
      try destination.perform(.paste(fragment, .front, container: 1, relativeTo: [])).first)
    #expect(destination.layers.first?.children.last?.id == top)
  }

  @Test func referencedResourceClosureRenamesCollisionsAndRebindsEveryLink() throws {
    var source = Drawing()
    let a = try add(&source, x: 20)
    var art = try #require(source.node(a)?.raw)
    art["id"] = .integer(80)
    art["appearance"]["items"] = .array([.object(["kind": .string("fill"), "paint": brandedPaint])])
    source.envelope["document"]["swatch_groups"] = .array([
      .object([
        "name": .string("Private group"), "swatches": .array([swatch("Brand"), swatch("Unused")]),
      ])
    ])
    source.envelope["document"]["symbols"] = .array([
      .object(["name": .string("Mark"), "art": art])
    ])
    source.envelope["document"]["patterns"] = .array([
      .object([
        "name": .string("Dots"),
        "art": .array([
          .object([
            "id": .integer(81),
            "kind": .object([
              "type": .string("symbolinstance"), "symbol": .string("Mark"),
              "xf": CGAffineTransform.identity.json,
            ]),
          ])
        ]),
      ])
    ])
    source.envelope["document"]["graphic_styles"] = .array([
      .object([
        "id": .integer(9), "name": .string("Look"),
        "appearance": .object([
          "items": .array([
            .object([
              "kind": .string("fill"),
              "paint": .object(["type": .string("pattern"), "pattern": .string("Dots")]),
            ])
          ])
        ]),
      ])
    ])
    source.updateNode(a) { $0["graphic_style"] = .integer(9) }
    source.envelope["document"]["next_id"] = .integer(100)
    let fragment = try VectorFragment(data: VectorFragment(copying: [a], from: source).encoded())
    #expect(
      fragment.drawing.envelope["document"]["swatches"].array.map { $0["name"].string } == ["Brand"]
    )
    #expect(fragment.drawing.envelope["document"]["swatch_groups"] == .null)
    var destination = Drawing()
    destination.envelope["document"]["swatches"] = .array([
      swatch("Brand", paint: VectorStyle.solid(0, 1, 0))
    ])
    destination.envelope["document"]["symbols"] = .array([
      .object(["name": .string("Mark"), "art": art])
    ])
    destination.envelope["document"]["patterns"] = source.envelope["document"]["patterns"]
    destination.envelope["document"]["graphic_styles"] = .array([
      .object(["id": .integer(9), "name": .string("Destination"), "appearance": .object([:])])
    ])
    let before = destination
    let pasted = try #require(
      try destination.perform(.paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
        .first)
    let doc = destination.envelope["document"]
    #expect(doc["swatches"].array.first == before.envelope["document"]["swatches"].array.first)
    #expect(doc["swatches"].array.last?["name"].string == "Brand 2")
    #expect(doc["symbols"].array.last?["name"].string == "Mark 2")
    #expect(
      doc["symbols"].array.last?["art"]["appearance"]["items"].array.first?["paint"]["swatch"]
        .string == "Brand 2")
    #expect(doc["patterns"].array.last?["name"].string == "Dots 2")
    #expect(doc["patterns"].array.last?["art"].array.first?["kind"]["symbol"].string == "Mark 2")
    #expect(
      doc["graphic_styles"].array.last?["appearance"]["items"].array.first?["paint"]["pattern"]
        .string == "Dots 2")
    #expect(
      destination.node(pasted)?.raw["graphic_style"].int
        == doc["graphic_styles"].array.last?["id"].int)
    #expect((doc["symbols"].array.last?["art"]["id"].int ?? 0) > 81)
    #expect(pasted > 81)
    _ = try NativeFormat.decode(NativeFormat.encode(destination))
  }

  @Test func imagesMasksTextStylesAndBrushesKeepOnlyUsedDefinitionsAndFreshArtIDs() throws {
    var source = Drawing()
    let a = try add(&source, x: 20)
    let text = try #require(
      try source.perform(
        .addText("Hello", .zero, font: "Helvetica", size: 20, fill: brandedPaint, layer: 1)
      ).first)
    let originalArt = try #require(source.node(a)?.raw)
    source.envelope["document"]["swatches"] = .array([swatch("Brand")])
    source.envelope["document"]["char_styles"] = .array([
      .object(["name": .string("Body"), "attrs": .object(["fill": brandedPaint])])
    ])
    source.envelope["document"]["para_styles"] = .array([
      .object(["name": .string("Paragraph"), "attrs": .object(["stroke": brandedPaint])])
    ])
    source.envelope["document"]["unknown"]["brushes"] = .array([
      .object([
        "name": .string("Pen"), "type": .string("pattern"), "side": originalArt,
        "outer_corner": originalArt,
      ])
    ])
    source.updateNode(text) { value in
      var runs = value["kind"]["runs"].array
      runs[0]["style"]["style_name"] = .string("Body")
      value["kind"]["runs"] = .array(runs)
      value["kind"]["para"] = .object(["style_name": .string("Paragraph")])
    }
    source.updateNode(a) { value in
      value["mask"] = .object([
        "art": .object([
          "id": .integer(90),
          "kind": .object([
            "type": .string("image"), "key": .string("photo"),
            "xf": CGAffineTransform.identity.json,
          ]),
        ])
      ])
      var items = value["appearance"]["items"].array
      items[1]["brush"] = .string("Pen")
      value["appearance"]["items"] = .array(items)
    }
    source.envelope["images"] = .object([
      "photo": .object(["mime": .string("image/png"), "data": .string("cGhvdG8=")]),
      "unused": .object(["data": .string("secret")]),
    ])
    let fragment = try VectorFragment(
      data: VectorFragment(copying: [a, text], from: source).encoded())
    #expect(fragment.drawing.envelope["images"].object.keys.sorted() == ["photo"])
    var destination = Drawing()
    let ids = try destination.perform(
      .paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
    #expect(ids.count == 2)
    let mask = try #require(ids.compactMap { destination.node($0) }.first { $0.type == "path" })
    #expect(mask.raw["mask"]["art"]["id"].int != 90)
    #expect(destination.envelope["images"]["photo"] == source.envelope["images"]["photo"])
    #expect(destination.envelope["document"]["char_styles"].array.count == 1)
    #expect(destination.envelope["document"]["para_styles"].array.count == 1)
    #expect(destination.envelope["document"]["unknown"]["brushes"].array.count == 1)
    let snapshot = destination
    #expect(throws: DrawingError.self) {
      try destination.perform(
        .paste(fragment, .center(CGPoint(x: 400, y: 400)), container: 1, relativeTo: []))
    }
    #expect(destination == snapshot)
    #expect(throws: DrawingError.self) { try SVGExport.encode(destination) }
  }

  @Test func legacyAnchorsAndAreaFramesUseDestinationVersion() throws {
    for sourceVersion in [Int64(1), 3] {
      for destinationVersion in [Int64(1), 3] {
        var source = Drawing()
        source.envelope["version"] = .integer(sourceVersion)
        let a = try add(&source, x: 20)
        let text = try source.perform(
          .addAreaText(
            "Text", CGRect(x: 20, y: 80, width: 100, height: 60), font: "Helvetica", size: 20,
            fill: VectorStyle.solid(0, 0, 0), layer: 1))
        let fragment = try VectorFragment(copying: text.union([a]), from: source)
        var destination = Drawing()
        destination.envelope["version"] = .integer(destinationVersion)
        let ids = try destination.perform(
          .paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
        for id in ids {
          let node = try #require(destination.node(id))
          let path =
            node.type == "path" ? node.raw["kind"]["path"] : node.raw["kind"]["kind"]["frame"]
          let p = try #require(path["subpaths"].array.first?["anchors"].array.first?["p"])
          #expect(destinationVersion == 1 ? !p.object.isEmpty : p.array.count == 2)
        }
        _ = try NativeFormat.decode(NativeFormat.encode(destination))
      }
    }
  }

  @Test func symbolResourcePathsConvertToLegacyWithoutRebindingForeignMetadata() throws {
    var source = Drawing()
    let pathID = try add(&source, x: 20)
    var art = try #require(source.node(pathID)?.raw)
    art["unknown"] = .object(["id": .integer(734), "symbol": .string("foreign")])
    source.envelope["document"]["symbols"] = .array([
      .object(["name": .string("Mark"), "art": art])
    ])
    source.updateNode(pathID) {
      $0["kind"] = .object([
        "type": .string("symbolinstance"), "symbol": .string("Mark"),
        "xf": CGAffineTransform.identity.json,
      ])
    }
    let fragment = try VectorFragment(copying: [pathID], from: source)
    var destination = Drawing()
    destination.envelope["version"] = .integer(1)
    _ = try destination.perform(
      .paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
    let stored = try #require(destination.envelope["document"]["symbols"].array.first?["art"])
    #expect(
      stored["kind"]["path"]["subpaths"].array.first?["anchors"].array.first?["p"].object["x"]
        == .number(20))
    #expect(stored["unknown"] == art["unknown"])
    _ = try NativeFormat.decode(NativeFormat.encode(destination))
  }

  @Test func cyclicResourcesTerminateAndUntrustedClipboardLimitsAreEnforced() throws {
    var source = Drawing()
    let a = try add(&source, x: 20)
    source.updateNode(a) { value in
      var items = value["appearance"]["items"].array
      items[0]["paint"] = brandedPaint
      value["appearance"]["items"] = .array(items)
    }
    var cycle = brandedPaint
    cycle["swatch"] = .string("Other")
    source.envelope["document"]["swatches"] = .array([
      swatch("Brand", paint: cycle), swatch("Other", paint: brandedPaint),
    ])
    let fragment = try VectorFragment(data: VectorFragment(copying: [a], from: source).encoded())
    #expect(fragment.drawing.envelope["document"]["swatches"].array.count == 2)
    var destination = Drawing()
    _ = try destination.perform(
      .paste(fragment, .inPlace(artboard: 0), container: 1, relativeTo: []))
    #expect(destination.envelope["document"]["swatches"].array.count == 2)
    #expect(throws: DrawingError.self) {
      try VectorFragment(data: Data(repeating: 32, count: NativeFormat.maximumBytes + 1))
    }
    #expect(throws: DrawingError.self) {
      try VectorFragment(
        data: Data(
          (String(repeating: "[", count: 129) + "0" + String(repeating: "]", count: 129)).utf8))
    }
  }

  @Test func isolationLocksMissingResourcesThreadsAndMalformedFragmentsFailWithoutMutation() throws
  {
    var source = Drawing()
    let a = try add(&source, x: 20)
    let fragment = try VectorFragment(copying: [a], from: source)
    let b = try add(&source, x: 120)
    let group = try #require(try source.perform(.group([a, b])).first)
    let snapshot = source
    #expect(throws: DrawingError.self) {
      try source.perform(.paste(fragment, .front, container: 1, relativeTo: [a]), within: group)
    }
    #expect(source == snapshot)
    _ = try source.perform(
      .paste(fragment, .front, container: group, relativeTo: [a]), within: group)
    source.updateNode(group) { $0["locked"] = .bool(true) }
    let locked = source
    #expect(throws: DrawingError.self) {
      try source.perform(.paste(fragment, .front, container: group, relativeTo: [a]))
    }
    #expect(source == locked)
    #expect(throws: (any Error).self) { try VectorFragment(data: Data("invalid".utf8)) }
    #expect(throws: DrawingError.self) { try VectorFragment(data: NativeFormat.encode(Drawing())) }
    source.updateNode(a) { value in
      var items = value["appearance"]["items"].array
      items[0]["paint"] = brandedPaint
      value["appearance"]["items"] = .array(items)
    }
    #expect(throws: DrawingError.self) { try VectorFragment(copying: [a], from: source) }
    source.envelope["document"]["swatches"] = .array([swatch("Brand")])
    source.envelope["document"]["text_threads"] = .array([.array([.integer(a)])])
    #expect(throws: DrawingError.self) { try VectorFragment(copying: [a], from: source) }
  }

  private var brandedPaint: JSONValue {
    var paint = VectorStyle.solid(1, 0, 0)
    paint["swatch"] = .string("Brand")
    return paint
  }
  private func swatch(_ name: String, paint: JSONValue = VectorStyle.solid(1, 0, 0)) -> JSONValue {
    .object(["name": .string(name), "paint": paint, "global": .bool(true)])
  }
  private func add(_ drawing: inout Drawing, x: Double) throws -> Int64 {
    try #require(
      try drawing.perform(
        .addPath(
          [ShapePaths.rectangle(CGRect(x: x, y: 30, width: 40, height: 20))], VectorStyle(),
          layer: 1)
      ).first)
  }
}
