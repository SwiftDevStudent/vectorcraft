import AppKit
import Testing

@testable import VectorCraftMac

@MainActor
struct NativeDocumentSaveTests {
  @Test func saveWaitsForPendingActivityWithoutBlockingTheMainActor() async throws {
    let doc = SaveRecordingDocument()
    let saver = NativeDocumentSave()
    saver.saveOperation = { _, asNewFile, finished in
      #expect(!asNewFile)
      doc.saves += 1
      finished()
      doc.didSave?()
    }
    var finish: (() -> Void)?
    await withCheckedContinuation { continuation in
      doc.performActivity(withSynchronousWaiting: false) {
        finish = $0
        continuation.resume()
      }
    }
    let finishPending = try #require(finish)
    await withCheckedContinuation { continuation in
      doc.didSave = { continuation.resume() }
      saver.save(doc)
      #expect(doc.saves == 0)
      // This main-actor work must remain runnable while Save waits for an earlier activity.
      finishPending()
    }
    #expect(doc.saves == 1)
  }

  @Test func saveAndSaveAsRequestsRemainSerializedUntilTheirCallbacksComplete() async throws {
    let doc = SaveRecordingDocument()
    let saver = NativeDocumentSave()
    var kinds: [Bool] = []
    var completions: [() -> Void] = []
    var started: (() -> Void)?
    saver.saveOperation = { _, asNewFile, finished in
      kinds.append(asNewFile)
      completions.append(finished)
      let callback = started
      started = nil
      callback?()
    }
    await withCheckedContinuation { continuation in
      started = { continuation.resume() }
      saver.save(doc)
    }
    saver.save(doc, asNewFile: true)
    #expect(kinds == [false])
    let finishFirst = try #require(completions.first)
    await withCheckedContinuation { continuation in
      started = { continuation.resume() }
      finishFirst()
    }
    #expect(kinds == [false, true])
    let finishSecond = try #require(completions.last)
    finishSecond()
  }

  @MainActor private final class SaveRecordingDocument: NSDocument {
    var saves = 0
    var didSave: (() -> Void)?
  }
}
