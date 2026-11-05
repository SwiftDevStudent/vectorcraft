import SwiftUI
import VectorCraftCore

enum TransformDialogKind: String, CaseIterable, Identifiable {
  case each = "Transform Each"
  case reflect = "Reflect"
  case shear = "Shear"
  var id: Self { self }
}

enum TransformAxis: String, CaseIterable, Identifiable {
  case horizontal = "Horizontal"
  case vertical = "Vertical"
  case angle = "Angle"
  var id: Self { self }
}

struct TransformDialogSettings: Equatable {
  var individual = IndividualTransform()
  var axis: TransformAxis = .horizontal
  var axisAngle = 45.0
  var shearAngle = 0.0
  var degrees: Double { axis == .horizontal ? 0 : axis == .vertical ? 90 : axisAngle }
}

@MainActor @Observable
final class TransformDialogSession: Identifiable {
  let id = UUID()
  let kind: TransformDialogKind
  let source: Drawing
  let selection: Set<Int64>
  let isolation: Int64?
  var settings = TransformDialogSettings()
  var previewEnabled = true
  private(set) var preview: (drawing: Drawing, selection: Set<Int64>)?
  private(set) var error: String?

  init(kind: TransformDialogKind, drawing: Drawing, selection: Set<Int64>, isolation: Int64?) {
    self.kind = kind
    source = drawing
    self.selection = selection
    self.isolation = isolation
    settings.axis = kind == .reflect ? .vertical : .horizontal
    settings.individual.seed = UInt64.random(in: UInt64.min...UInt64.max)
    refresh()
  }

  func refresh() {
    do {
      var next = source
      let selected = try next.perform(makeCommand(copy: false), within: isolation)
      preview = previewEnabled ? (next, selected) : nil
      error = nil
    } catch {
      preview = nil
      self.error = error.localizedDescription
    }
  }

  func command(copy: Bool, in current: Drawing) throws -> DrawingCommand {
    guard current == source else {
      throw DrawingError.invalid(
        "The artwork changed while this dialog was open. Reopen the transform dialog.")
    }
    return try makeCommand(copy: copy)
  }

  private func makeCommand(copy: Bool) throws -> DrawingCommand {
    if kind == .each { return .transformEach(selection, settings.individual, copy: copy) }
    let bounds = selection.compactMap(source.node).reduce(CGRect.null) { $0.union($1.bounds) }
    guard !bounds.isNull else { throw DrawingError.invalid("Select artwork with valid bounds.") }
    let origin = settings.individual.reference.point(in: bounds)
    let matrix =
      kind == .reflect
      ? try TransformGeometry.reflection(axis: settings.degrees, around: origin)
      : try TransformGeometry.shear(
        angle: settings.shearAngle, axis: settings.degrees, around: origin)
    return .transform(selection, matrix, copy: copy)
  }
}

extension EditorState {
  func transformPreview(in drawing: Drawing) -> (drawing: Drawing, selection: Set<Int64>)? {
    guard let session = transformDialog, session.source == drawing,
      session.isolation == isolationID
    else { return nil }
    return session.preview
  }

  func canTransform(in drawing: Drawing) -> Bool {
    tool != .pen && textEditingSession == nil && !selection.isEmpty
      && selection.allSatisfy {
        drawing.canEdit($0) && drawing.node($0)?.type != "layer"
          && drawing.isInside($0, isolation: isolationID)
      }
  }

  func presentTransform(_ kind: TransformDialogKind, in drawing: Drawing) {
    guard canTransform(in: drawing) else { return }
    canvasAction = .cancelPath
    transformDialog = TransformDialogSession(
      kind: kind, drawing: drawing, selection: selection, isolation: isolationID)
  }
}
