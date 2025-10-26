import SwiftUI

struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = Anchor<CGRect>?
    static let defaultValue: Value = nil
    static func reduce(value: inout Value, nextValue: () -> Value) {
        guard let newValue = nextValue() else { return }
        value = newValue
    }
}

extension View {
    public func titleVisibilityAnchor() -> some View {
        self.anchorPreference(
            key: BoundsPreferenceKey.self,
            value: .bounds
        ) { anchor in
            anchor
        }
    }
}

private struct ScrollAwareVisibilityModifier: ViewModifier {
    @Binding var isShowNavigationTitle: Bool

    func body(content: Content) -> some View {
        content
            .backgroundPreferenceValue(BoundsPreferenceKey.self) { anchor in
                GeometryReader { proxy in
                    if let anchor = anchor {
                        let scrollFrame = proxy.frame(in: .local).minY
                        let itemFrame = proxy[anchor]
                        let isVisible = itemFrame.maxY > scrollFrame
                        let shouldShow = !isVisible
                        DispatchQueue.main.async {
                            if isShowNavigationTitle != shouldShow {
                                isShowNavigationTitle = shouldShow
                            }
                        }
                    }
                    return Color.clear
                }
            }
    }
}

#if os(iOS)
private struct ScrollAwareTitleModifier<V: View>: ViewModifier {
    @State private var isShowNavigationTitle = false
    let title: () -> V

    func body(content: Content) -> some View {
        content
            .modifier(ScrollAwareVisibilityModifier(isShowNavigationTitle: $isShowNavigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    title()
                        .bold()
                        .opacity(isShowNavigationTitle ? 1 : 0)
                        .animation(.easeIn(duration: 0.15), value: isShowNavigationTitle)
                }
            }
    }
}
#endif

#if os(macOS)
private enum ScrollAwareTitleStorage {
    case plain(String)
    case localized(LocalizedStringKey)
}

private struct ScrollAwareTextTitleModifier: ViewModifier {
    @State private var isShowNavigationTitle = false
    let storage: ScrollAwareTitleStorage

    func body(content: Content) -> some View {
        content
            .modifier(ScrollAwareVisibilityModifier(isShowNavigationTitle: $isShowNavigationTitle))
            .modifier(MacNavigationTitleModifier(storage: storage, isVisible: isShowNavigationTitle))
    }
}

private struct MacNavigationTitleModifier: ViewModifier {
    let storage: ScrollAwareTitleStorage
    let isVisible: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        switch storage {
        case .plain(let value):
            content.navigationTitle(isVisible ? value : "")
        case .localized(let key):
            let hidden: LocalizedStringKey = ""
            content.navigationTitle(isVisible ? key : hidden)
        }
    }
}
#endif

#if os(iOS)
extension View {
    public func scrollAwareTitle<V: View>(@ViewBuilder _ title: @escaping () -> V) -> some View {
        modifier(ScrollAwareTitleModifier(title: title))
    }
}
#endif

extension View {
    public func scrollAwareTitle<S: StringProtocol>(_ title: S) -> some View {
#if os(iOS)
        scrollAwareTitle {
            Text(title)
        }
#else
        modifier(ScrollAwareTextTitleModifier(storage: .plain(String(title))))
#endif
    }

    public func scrollAwareTitle(_ title: LocalizedStringKey) -> some View {
#if os(iOS)
        scrollAwareTitle {
            Text(title)
        }
#else
        modifier(ScrollAwareTextTitleModifier(storage: .localized(title)))
#endif
    }
}
