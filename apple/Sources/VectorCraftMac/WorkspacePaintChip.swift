import SwiftUI
import VectorCraftCore

struct WorkspacePaintChip: View {
  var paint: JSONValue
  var body: some View {
    if paint["type"].string == "gradient" {
      LinearGradient(
        stops: paint["gradient"]["stops"].array.sorted {
          ($0["offset"].double ?? 0) < ($1["offset"].double ?? 0)
        }.map {
          .init(
            color: Color(
              cgColor: VectorRenderer.color($0["color"], opacity: $0["opacity"].double ?? 1)),
            location: min(1, max(0, $0["offset"].double ?? 0)))
        }, startPoint: .leading, endPoint: .trailing)
    } else if paint["type"].string == "solid" {
      Color(cgColor: VectorRenderer.color(paint["color"]))
    } else {
      Color.clear
    }
  }
}
