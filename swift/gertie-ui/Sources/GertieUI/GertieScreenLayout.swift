import SwiftUI

#if os(iOS)
  import UIKit
#endif

public struct GertieFoldAwareScreen<Flat: View, Icon: View, Message: View, Actions: View>: View {
  private let configuration: GertieScreenLayoutConfiguration
  private let centersFlatContentOnPad: Bool
  private let flat: Flat
  private let icon: Icon
  private let message: Message
  private let actions: Actions

  public init(
    spacing: CGFloat = 24,
    alignment: HorizontalAlignment = .center,
    centersFlatContentOnPad: Bool = false,
    @ViewBuilder flat: () -> Flat,
    @ViewBuilder icon: () -> Icon,
    @ViewBuilder message: () -> Message,
    @ViewBuilder actions: () -> Actions,
  ) {
    self.configuration = GertieScreenLayoutConfiguration(spacing: spacing, alignment: alignment)
    self.centersFlatContentOnPad = centersFlatContentOnPad
    self.flat = flat()
    self.icon = icon()
    self.message = message()
    self.actions = actions()
  }

  public var body: some View {
    GertieScreenGeometryReader { proxy, geometry in
      self.content(
        containerSize: proxy.size,
        geometry: geometry,
        isPad: GertieScreenDevice.isPad,
      )
    }
    .gertieScreenBackground()
  }

  @ViewBuilder func content(
    containerSize: CGSize,
    geometry: FoldedContentGeometry?,
    isPad: Bool = false,
  ) -> some View {
    if geometry != nil || self.centersFlatContentOnPad && isPad {
      GertieScreenContentLayout(
        containerSize: containerSize,
        geometry: geometry,
        configuration: self.configuration,
        hasActions: true,
      ) {
        self.icon
      } message: {
        self.message
      } actions: {
        self.actions
      }
    } else {
      self.flat.frame(width: containerSize.width, height: containerSize.height)
    }
  }
}

enum GertieScreenDevice {
  @MainActor static var isPad: Bool {
    #if os(iOS)
      UIDevice.current.userInterfaceIdiom == .pad
    #else
      false
    #endif
  }
}

struct GertieScreenGeometryReader<Content: View>: View {
  private let resolveGeometry: (GeometryProxy) -> FoldedContentGeometry?
  private let resolveDivisionAxis: (GeometryProxy) -> Axis?
  private let content: (GeometryProxy, FoldedContentGeometry?) -> Content

  init(
    resolveGeometry: @escaping (GeometryProxy) -> FoldedContentGeometry? = {
      FoldedContentGeometry.resolve(in: $0)
    },
    resolveDivisionAxis: @escaping (GeometryProxy) -> Axis? = {
      FoldedContentGeometry.resolve(in: $0, includeInactive: true)?.axis
    },
    @ViewBuilder content: @escaping (GeometryProxy, FoldedContentGeometry?) -> Content,
  ) {
    self.resolveGeometry = resolveGeometry
    self.resolveDivisionAxis = resolveDivisionAxis
    self.content = content
  }

  var body: some View {
    GeometryReader { safeAreaProxy in
      let ignoredEdges: Edge.Set = switch self.resolveGeometry(safeAreaProxy)?.axis {
      case .horizontal: .trailing
      case .vertical: .top
      case nil: self.resolveDivisionAxis(safeAreaProxy) == .horizontal ? .trailing : []
      }

      GeometryReader { proxy in
        self.content(proxy, self.resolveGeometry(proxy))
      }
      .ignoresSafeArea(.container, edges: ignoredEdges)
    }
  }
}

struct GertieScreenContentLayout<Icon: View, Message: View, Actions: View>: View {
  @State private var iconHeight: CGFloat = 0
  @State private var messageHeight: CGFloat = 0
  @State private var spacerHeight: CGFloat = 0

  let containerSize: CGSize
  let geometry: FoldedContentGeometry?
  let configuration: GertieScreenLayoutConfiguration
  let hasActions: Bool
  @ViewBuilder let icon: Icon
  @ViewBuilder let message: Message
  @ViewBuilder let actions: Actions

  var body: some View {
    let configuration = self.configuration.resolvingPlacement(
      isPad: GertieScreenDevice.isPad,
      geometry: self.geometry,
    )
    let tabletop = self.geometry?.axis == .vertical ? self.geometry : nil
    let book = self.geometry?.axis == .horizontal ? self.geometry : nil
    let size = book?.secondarySize ?? self.containerSize
    let placement = book == nil ? configuration.flatPlacement : configuration
      .bookPlacement
    let isDistributed = tabletop == nil && placement == .distributed
    let bookIconOffset = max(
      0,
      (self.iconHeight + configuration.iconBottomPadding + self.spacerHeight
        + configuration.spacing * 2) / 3
        - self.iconHeight / 2,
    )
    let insets = self.geometry == nil
      ? configuration.insets
      : EdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)

    ScrollView {
      VStack(
        alignment: configuration.alignment,
        spacing: tabletop?.spacing ?? configuration.spacing,
      ) {
        GertieScreenRegion(
          size: tabletop?.primarySize,
          fillsAvailableHeight: isDistributed,
          fadesBottom: tabletop != nil,
        ) {
          VStack(
            alignment: configuration.alignment,
            spacing: isDistributed ? configuration.spacing : tabletop == nil ? configuration
              .spacing / 2 : 12,
          ) {
            self.icon
              .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                self.iconHeight = $0
              }
              .padding(.bottom, configuration.iconBottomPadding)
              .offset(y: book != nil && isDistributed ? bookIconOffset : 0)

            Spacer(minLength: isDistributed ? configuration.spacerMinLength : 0)
              .frame(height: isDistributed ? nil : 0)
              .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                self.spacerHeight = $0
              }

            self.message
              .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                self.messageHeight = $0
              }
          }
        }
        .environment(\.gertieScreenIsTabletop, tabletop != nil)
        .frame(minHeight: isDistributed
          ? self.iconHeight + configuration.iconBottomPadding + self.messageHeight
          + configuration.spacing * 2
          + (configuration.spacerMinLength ?? 8)
          : nil)

        if self.hasActions {
          GertieScreenRegion(size: tabletop?.secondarySize, alignment: .bottom) {
            self.actions
              .padding(.top, tabletop == nil ? configuration.actionTopPadding : 0)
              .padding(
                .horizontal,
                self.geometry == nil ? configuration.flatActionHorizontalPadding : 0,
              )
          }
        }
      }
      .padding(
        .vertical,
        self.geometry == nil && placement == .centered ? configuration.spacing : 0,
      )
      .frame(
        minHeight: tabletop == nil ? max(0, size.height - insets.top - insets.bottom) : nil,
        alignment: isDistributed ? .top : .center,
      )
      .padding(tabletop == nil ? insets : EdgeInsets())
      .frame(maxWidth: tabletop == nil ? configuration.maxWidth : .infinity)
      .frame(maxWidth: .infinity)
    }
    .scrollBounceBehavior(.basedOnSize)
    .scrollIndicators(.hidden)
    .frame(width: size.width, height: size.height)
    .offset(x: book?.division.maxX ?? 0)
  }
}

struct GertieScreenLayoutConfiguration {
  enum Placement {
    case centered
    case distributed
  }

  let spacing: CGFloat
  var iconBottomPadding: CGFloat = 0
  var spacerMinLength: CGFloat? = 0
  var actionTopPadding: CGFloat = 0
  var insets = EdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)
  var alignment = HorizontalAlignment.center
  var flatPlacement = Placement.centered
  var bookPlacement = Placement.distributed
  var flatActionHorizontalPadding: CGFloat = 0
  var maxWidth: CGFloat = 500

  func resolvingPlacement(isPad: Bool, geometry: FoldedContentGeometry?) -> Self {
    guard isPad, geometry == nil, self.flatPlacement == .distributed else { return self }
    var configuration = self
    configuration.flatPlacement = .centered
    configuration.insets.top = configuration.insets.bottom
    return configuration
  }

  static var result: Self {
    Self(spacing: 24, flatActionHorizontalPadding: 30)
  }

  static var loading: Self {
    Self(spacing: 20, bookPlacement: .centered)
  }
}

struct GertieScreenRegion<Content: View>: View {
  let size: CGSize?
  var alignment: Alignment = .center
  var fillsAvailableHeight = false
  var fadesBottom = false
  @ViewBuilder let content: Content

  var body: some View {
    let fillsHeight = self.size == nil && self.fillsAvailableHeight
    let fadeHeight = self.fadesBottom ? min(24, self.size?.height ?? 0) : 0

    ScrollView(fillsHeight ? [] : .vertical) {
      self.content
        .frame(
          minHeight: self.size.map { max(0, $0.height - 60) },
          alignment: self.alignment,
        )
        .padding(self.size == nil ? 0 : 30)
        .frame(maxWidth: self.size == nil ? .infinity : 500)
        .frame(maxWidth: .infinity)
    }
    .scrollDisabled(self.size == nil)
    .scrollBounceBehavior(.basedOnSize)
    .scrollIndicators(.hidden)
    .scrollClipDisabled(self.size == nil)
    .fixedSize(horizontal: false, vertical: self.size == nil && !fillsHeight)
    .frame(height: self.size?.height)
    .frame(maxHeight: fillsHeight ? .infinity : nil)
    .overlay(alignment: .bottom) {
      LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
        .frame(height: fadeHeight)
        .blendMode(.destinationOut)
        .allowsHitTesting(false)
    }
    .compositingGroup()
  }
}

extension EnvironmentValues {
  @Entry var gertieScreenIsTabletop = false
}

public extension View {
  @MainActor func gertieScreenTextAlignment() -> some View {
    self.modifier(GertieScreenTextAlignmentModifier(isPad: GertieScreenDevice.isPad))
  }
}

struct GertieScreenTextAlignmentModifier: ViewModifier {
  @Environment(\.gertieScreenIsTabletop) private var isTabletop

  let isPad: Bool
  var hasList = false

  @ViewBuilder func body(content: Content) -> some View {
    if self.isPad || self.isTabletop, !self.hasList {
      content
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
    } else {
      content
    }
  }
}

struct GertieOptionalAccessibilityIdentifier: ViewModifier {
  let identifier: String?

  @ViewBuilder func body(content: Content) -> some View {
    if let identifier {
      content.accessibilityIdentifier(identifier)
    } else {
      content
    }
  }
}

struct GertieActionScreenMetrics {
  let layout: GertieActionScreenLayout
  let spacing: CGFloat
  let iconSize: CGFloat
  let spacerMinLength: CGFloat?
  let listPadBottom: CGFloat
  let buttonPadTop: CGFloat
  let insets: EdgeInsets

  var layoutConfiguration: GertieScreenLayoutConfiguration {
    GertieScreenLayoutConfiguration(
      spacing: self.spacing,
      iconBottomPadding: 16,
      spacerMinLength: self.spacerMinLength,
      actionTopPadding: self.buttonPadTop,
      insets: self.insets,
      alignment: .leading,
      flatPlacement: .distributed,
    )
  }

  static var regular: Self {
    Self(
      layout: .regular,
      spacing: 16,
      iconSize: 40,
      spacerMinLength: nil,
      listPadBottom: 20,
      buttonPadTop: 12,
      insets: EdgeInsets(top: 80, leading: 30, bottom: 30, trailing: 30),
    )
  }

  static var compact: Self {
    Self(
      layout: .compact,
      spacing: 12,
      iconSize: 34,
      spacerMinLength: 10,
      listPadBottom: 8,
      buttonPadTop: 8,
      insets: EdgeInsets(top: 42, leading: 22, bottom: 22, trailing: 22),
    )
  }

  static func resolve(
    containerSize: CGSize,
    geometry: FoldedContentGeometry?,
    usesAccessibilitySize: Bool,
  ) -> Self {
    let height = geometry.map {
      $0.axis == .vertical ? $0.primarySize.height : $0.secondarySize.height
    } ?? containerSize.height
    return height <= 700 || usesAccessibilitySize ? .compact : .regular
  }
}
