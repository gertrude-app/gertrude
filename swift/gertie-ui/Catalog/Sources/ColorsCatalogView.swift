import GertieUI
import SwiftUI

struct ColorsCatalogView: View {
  var body: some View {
    List {
      Section("Brand") {
        ColorSwatch(name: "gertrudeBrandAccent", color: .gertrudeBrandAccent)
      }

      ColorPaletteSection(name: "Violet", colors: Self.violet)
      ColorPaletteSection(name: "Fuchsia", colors: Self.fuchsia)
    }
    .navigationTitle("Colors")
    .navigationBarTitleDisplayMode(.inline)
  }

  private static let violet = [
    NamedColor(name: "violet100", hex: "#ede9fe", color: .violet100),
    NamedColor(name: "violet200", hex: "#ddd6fe", color: .violet200),
    NamedColor(name: "violet300", hex: "#c4b5fd", color: .violet300),
    NamedColor(name: "violet400", hex: "#a78bfa", color: .violet400),
    NamedColor(name: "violet500", hex: "#8b5cf6", color: .violet500),
    NamedColor(name: "violet600", hex: "#7c3aed", color: .violet600),
    NamedColor(name: "violet700", hex: "#6d28d9", color: .violet700),
    NamedColor(name: "violet800", hex: "#5b21b6", color: .violet800),
    NamedColor(name: "violet900", hex: "#4c1d95", color: .violet900),
    NamedColor(name: "violet950", hex: "#2e1065", color: .violet950),
  ]

  private static let fuchsia = [
    NamedColor(name: "fuchsia100", hex: "#fae8ff", color: .fuchsia100),
    NamedColor(name: "fuchsia200", hex: "#f5d0fe", color: .fuchsia200),
    NamedColor(name: "fuchsia300", hex: "#f0abfc", color: .fuchsia300),
    NamedColor(name: "fuchsia400", hex: "#e879f9", color: .fuchsia400),
    NamedColor(name: "fuchsia500", hex: "#d946ef", color: .fuchsia500),
    NamedColor(name: "fuchsia600", hex: "#c026d3", color: .fuchsia600),
    NamedColor(name: "fuchsia700", hex: "#a21caf", color: .fuchsia700),
    NamedColor(name: "fuchsia800", hex: "#86198f", color: .fuchsia800),
    NamedColor(name: "fuchsia900", hex: "#701a75", color: .fuchsia900),
    NamedColor(name: "fuchsia950", hex: "#4a044e", color: .fuchsia950),
  ]
}

private struct NamedColor: Identifiable {
  let name: String
  let hex: String
  let color: Color

  var id: String { self.name }
}

private struct ColorPaletteSection: View {
  let name: String
  let colors: [NamedColor]

  var body: some View {
    Section(self.name) {
      ForEach(self.colors) { color in
        ColorSwatch(name: color.name, hex: color.hex, color: color.color)
      }
    }
  }
}

private struct ColorSwatch: View {
  let name: String
  var hex: String?
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(self.color)
        .frame(width: 44, height: 44)
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(.primary.opacity(0.12))
        }

      VStack(alignment: .leading, spacing: 2) {
        Text(self.name)
          .font(.body.monospaced())

        if let hex = self.hex {
          Text(hex)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}
