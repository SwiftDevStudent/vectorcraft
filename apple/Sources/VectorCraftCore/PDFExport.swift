import CoreGraphics
import Foundation

public enum PDFExport {
  public static func encode(_ drawing: Drawing, artboard index: Int = 0) throws -> Data {
    guard drawing.renderingWarnings.isEmpty, drawing.artboards.indices.contains(index) else {
      throw DrawingError.invalid(
        "PDF export requires a valid artboard and fully supported artwork.")
    }
    let board = drawing.artboards[index]
    var mediaBox = CGRect(origin: .zero, size: board.size)
    let data = NSMutableData()
    guard let consumer = CGDataConsumer(data: data),
      let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
    else {
      throw DrawingError.invalid("Could not create the PDF.")
    }
    context.beginPDFPage(nil)
    context.translateBy(x: 0, y: board.height)
    context.scaleBy(x: 1, y: -1)
    context.translateBy(x: -board.minX, y: -board.minY)
    VectorRenderer.render(drawing, in: context)
    context.endPDFPage()
    context.closePDF()
    return data as Data
  }
}
