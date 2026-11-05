import AppKit
import CoreText

enum WorkspaceFonts {
  @MainActor static func register() {
    for name in ["SourceSans3-Regular", "SourceSans3-Semibold"] {
      guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
      // Registration failure only affects chrome fidelity; system fonts remain available.
      if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) {
        NSLog("VectorCraft: a workspace font could not be registered; using available fonts.")
      }
    }
  }
}
