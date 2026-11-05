#if os(macOS)
  import SwiftUI
  import Testing

  @testable import GertieUI

  @MainActor
  struct GertieScreenGeometryReaderTests {
    @Test
    func bookCentersWithinTheFullRightPaneWithoutDiscardingOtherSafeAreas() throws {
      let size = CGSize(width: 1200, height: 800)
      let division = CGRect(x: 540, y: -40, width: 24, height: 880)
      let regions = try self.renderScreen(
        containerSize: size,
        division: division,
        insets: EdgeInsets(top: 32, leading: 44, bottom: 24, trailing: 120),
      )
      let expected = try self.renderScreen(
        containerSize: size,
        division: division,
        insets: EdgeInsets(top: 32, leading: 44, bottom: 24, trailing: 0),
        usesFoldAwareReader: false,
      )

      #expect(regions.red.midX == 882)
      #expect(regions.blue.midX == 882)
      #expect(regions.red == expected.red)
      #expect(regions.green == expected.green)
      #expect(regions.blue == expected.blue)
    }

    @Test
    func tabletopCentersAboveTheFoldIncludingTheStatusBarWhilePreservingOtherInsets() throws {
      let size = CGSize(width: 800, height: 1000)
      let division = CGRect(x: -100, y: 420, width: 1000, height: 24)
      let regions = try self.renderScreen(
        containerSize: size,
        division: division,
        insets: EdgeInsets(top: 80, leading: 20, bottom: 34, trailing: 40),
      )
      let expected = try self.renderScreen(
        containerSize: size,
        division: division,
        insets: EdgeInsets(top: 0, leading: 20, bottom: 34, trailing: 40),
        usesFoldAwareReader: false,
      )
      let introduction = regions.red.union(regions.green)

      #expect(introduction.midY == 210)
      #expect(introduction.midX == 390)
      #expect(regions.blue.maxY == 936)
      #expect(regions.red == expected.red)
      #expect(regions.green == expected.green)
      #expect(regions.blue == expected.blue)
    }

    @Test
    func fullyOpenLandscapeIncludesTheRightStatusStripWithoutActivatingBookLayout() throws {
      let size = CGSize(width: 1200, height: 800)
      let division = CGRect(x: 600, y: -40, width: 0, height: 880)
      let regions = try self.renderScreen(
        containerSize: size,
        division: division,
        insets: EdgeInsets(top: 32, leading: 0, bottom: 24, trailing: 120),
      )
      let expected = try self.renderScreen(
        containerSize: size,
        division: division,
        insets: EdgeInsets(top: 32, leading: 0, bottom: 24, trailing: 0),
        usesFoldAwareReader: false,
      )

      #expect(regions.red.midX == 600)
      #expect(regions.red == expected.red)
      #expect(regions.green == expected.green)
      #expect(regions.blue == expected.blue)
    }

    private func renderScreen(
      containerSize: CGSize,
      division: CGRect?,
      insets: EdgeInsets,
      usesFoldAwareReader: Bool = true,
    ) throws -> RenderedScreenRegions {
      try RenderedScreenRegions(containerSize: containerSize) {
        Group {
          if usesFoldAwareReader {
            GertieScreenGeometryReader(
              resolveGeometry: { self.geometry(in: $0, division: division) },
              resolveDivisionAxis: {
                self.geometry(in: $0, division: division, includeInactive: true)?.axis
              },
            ) { proxy, geometry in
              self.content(proxy: proxy, geometry: geometry)
            }
          } else {
            GeometryReader { proxy in
              self.content(
                proxy: proxy,
                geometry: self.geometry(in: proxy, division: division),
              )
            }
          }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
          Color.clear.frame(height: insets.top)
        }
        .safeAreaInset(edge: .leading, spacing: 0) {
          Color.clear.frame(width: insets.leading)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
          Color.clear.frame(height: insets.bottom)
        }
        .safeAreaInset(edge: .trailing, spacing: 0) {
          Color.clear.frame(width: insets.trailing)
        }
      }
    }

    private func geometry(
      in proxy: GeometryProxy,
      division: CGRect?,
      includeInactive: Bool = false,
    ) -> FoldedContentGeometry? {
      let frame = proxy.frame(in: .global)
      return FoldedContentGeometry.resolve(
        containerSize: proxy.size,
        divisions: division.map {
          [$0.offsetBy(dx: -frame.minX, dy: -frame.minY)]
        } ?? [],
        includeInactive: includeInactive,
      )
    }

    private func content(proxy: GeometryProxy, geometry: FoldedContentGeometry?) -> some View {
      let metrics = GertieActionScreenMetrics.resolve(
        containerSize: proxy.size,
        geometry: geometry,
        usesAccessibilitySize: false,
      )
      return GertieScreenContentLayout(
        containerSize: proxy.size,
        geometry: geometry,
        configuration: metrics.layoutConfiguration,
        hasActions: true,
      ) {
        Color(red: 1, green: 0, blue: 0).frame(height: metrics.iconSize)
      } message: {
        Color(red: 0, green: 1, blue: 0).frame(height: 100)
      } actions: {
        Color(red: 0, green: 0, blue: 1).frame(height: 52)
      }
    }
  }
#endif
