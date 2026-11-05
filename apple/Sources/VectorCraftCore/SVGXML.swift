import Foundation

final class SVGElement {
  let name: String
  let attributes: [String: String]
  let namespace: String
  weak var parent: SVGElement?
  var children: [SVGElement] = []
  var text = ""
  init(_ name: String, _ attributes: [String: String], namespace: String) {
    self.name = name
    self.attributes = attributes
    self.namespace = namespace
  }
}

final class SVGXML: NSObject, XMLParserDelegate {
  static let maximumBytes = 8 * 1024 * 1024
  var root: SVGElement?
  var stack: [SVGElement] = []
  var count = 0
  var textCount = 0
  var failure: DrawingError?
  static func read(_ data: Data) throws -> SVGElement {
    guard !data.isEmpty, data.count <= maximumBytes else {
      throw svgError("Input is empty or exceeds the 8 MB import limit.")
    }
    // With resolution disabled, XMLParser can silently skip declared entities without
    // reporting their declarations. Reject DTDs before parsing, including UTF-16/32 input.
    let head = Array(data.prefix(4))
    let encoding: String.Encoding?
    if head == [0xff, 0xfe, 0, 0] || head == [60, 0, 0, 0] {
      encoding = .utf32LittleEndian
    } else if head == [0, 0, 0xfe, 0xff] || head == [0, 0, 0, 60] {
      encoding = .utf32BigEndian
    } else if head.starts(with: [0xff, 0xfe]) || head.starts(with: [60, 0]) {
      encoding = .utf16LittleEndian
    } else if head.starts(with: [0xfe, 0xff]) || head.starts(with: [0, 60]) {
      encoding = .utf16BigEndian
    } else {
      encoding = nil
    }
    let text =
      encoding.flatMap { String(data: data, encoding: $0) } ?? String(decoding: data, as: UTF8.self)
    guard
      text.trimmingCharacters(
        in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{feff}"))
      ).hasPrefix("<")
    else { throw svgError("Unsupported XML encoding or invalid SVG input.") }
    var cursor = text.startIndex
    while let declaration = text.range(of: "<!", range: cursor..<text.endIndex) {
      let suffix = text[declaration.lowerBound...]
      let terminator =
        suffix.hasPrefix("<!--") ? "-->" : suffix.hasPrefix("<![CDATA[") ? "]]>" : nil
      if let terminator,
        let end = text.range(of: terminator, range: declaration.upperBound..<text.endIndex)
      {
        cursor = end.upperBound
      } else if suffix.hasPrefix("<!DOCTYPE") {
        throw svgError("XML DTDs and custom entities are not supported.")
      } else {
        cursor = declaration.upperBound
      }
    }
    let delegate = SVGXML()
    let parser = XMLParser(data: data)
    parser.delegate = delegate
    parser.shouldProcessNamespaces = true
    parser.shouldResolveExternalEntities = false
    parser.externalEntityResolvingPolicy = .never
    let valid = parser.parse()
    if let error = delegate.failure { throw error }
    guard valid, let root = delegate.root, root.name == "svg", delegate.stack.isEmpty else {
      throw svgError(
        "Invalid SVG XML. \(parser.parserError?.localizedDescription ?? "Expected an svg root.")")
    }
    return root
  }
  private func fail(_ parser: XMLParser, _ message: String) {
    failure = svgError(message)
    parser.abortParsing()
  }
  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes attributeDict: [String: String]
  ) {
    count += 1
    guard count <= 50_000, stack.count < 64 else {
      fail(parser, "XML exceeds the object or nesting limit.")
      return
    }
    let node = SVGElement(elementName, attributeDict, namespace: namespaceURI ?? "")
    if let parent = stack.last {
      node.parent = parent
      parent.children.append(node)
    } else if root == nil {
      root = node
    } else {
      fail(parser, "Multiple XML roots.")
      return
    }
    stack.append(node)
  }
  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?
  ) { _ = stack.popLast() }
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    textCount += string.utf8.count
    guard textCount <= 1_000_000 else {
      fail(parser, "XML text exceeds the import limit.")
      return
    }
    stack.last?.text += string
  }
  func parser(_ parser: XMLParser, foundCDATA block: Data) {
    guard let text = String(data: block, encoding: .utf8) else {
      fail(parser, "Invalid SVG text encoding.")
      return
    }
    self.parser(parser, foundCharacters: text)
  }
  func parser(
    _ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?
  ) { fail(parser, "Custom XML entities are not supported.") }
  func parser(
    _ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?,
    systemID: String?
  ) { fail(parser, "External XML entities are not supported.") }
  func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?)
    -> Data?
  {
    fail(parser, "External XML resources are not supported.")
    return nil
  }
  func parser(
    _ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?
  ) {
    if target == "xml-stylesheet" { fail(parser, "External stylesheets are not supported.") }
  }
}
