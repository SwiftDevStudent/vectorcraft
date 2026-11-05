import AppKit
import VectorCraftCore

/// The cache stays on the main actor; only immutable requests/images cross the worker boundary.
@MainActor
final class CanvasImagePreviews {
  let cache = VectorImagePreviewCache(deferred: true)
  private weak var view: VectorCanvasView?
  private let decoder = CanvasImageDecoder()
  private var pending: [VectorImagePreviewRequest] = []
  private var current: VectorImagePreviewRequest?
  private var failed: [VectorImagePreviewRequest] = []
  private(set) var task: Task<Void, Never>?
  private var accessRevision: Int?

  init(view: VectorCanvasView) { self.view = view }

  func accessChanged(_ revision: Int) {
    guard accessRevision != revision else { return }
    accessRevision = revision
    failed.removeAll()
    Task { [weak self] in self?.publishStatus() }
  }

  func update(_ requests: [VectorImagePreviewRequest]) {
    let previousFailures = failed.count
    failed = failed.filter { requests.contains($0) }
    // A new draw replaces queued work with what this viewport currently needs.
    pending = requests.filter { $0 != current && !failed.contains($0) }.reversed()
    guard task == nil, !pending.isEmpty else {
      if task == nil, failed.count != previousFailures {
        // update() runs during draw(); publish presentation changes on the next turn.
        Task { [weak self] in self?.publishStatus() }
      }
      return
    }
    let decoder = decoder
    task = Task(priority: .utility) { [weak self] in
      guard !Task.isCancelled else { return }
      self?.publishStatus()
      while let request = self?.next() {
        do {
          let image = try await decoder.decode(request)
          guard !Task.isCancelled, let owner = self else { return }
          owner.current = nil
          if owner.cache.isCurrent(request) {
            if let image, owner.cache.store(image, for: request) {
              owner.view?.needsDisplay = true
            } else { owner.failed.append(request) }
          }
          owner.publishStatus()
        } catch {
          // The decoder throws only for cancellation; closing a canvas discards its work.
          return
        }
      }
      self?.task = nil
      self?.publishStatus()
    }
  }

  func cancel() {
    task?.cancel()
    task = nil
    current = nil
    pending.removeAll()
    failed.removeAll()
    publishStatus()
  }

  private func next() -> VectorImagePreviewRequest? {
    current = pending.popLast()
    return current
  }
  private func publishStatus() {
    guard let state = view?.state else { return }
    let loading = task != nil, unavailable = !failed.isEmpty
    if state.imagePreviewsLoading != loading { state.imagePreviewsLoading = loading }
    if state.imagePreviewsUnavailable != unavailable { state.imagePreviewsUnavailable = unavailable }
  }
}

private actor CanvasImageDecoder {
  func decode(_ request: VectorImagePreviewRequest) throws -> CGImage? {
    try request.decode()
  }
}
