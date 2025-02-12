#if os(iOS)

import SwiftUI

struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = Anchor<CGRect>?
    static var defaultValue: Value = nil
    static func reduce(value: inout Value, nextValue: () -> Value) {
        guard let newValue = nextValue() else { return }
        value = newValue
    }
}

extension View {
    func titleVisibilityAnchor() -> some View {
        self.anchorPreference(
            key: BoundsPreferenceKey.self,
            value: .bounds
        ) { anchor in
            anchor
        }
    }
}

private struct ScrollAwareTitleModifier<V: View>: ViewModifier {
    @State private var isShowNavigationTitle = false
    let title: () -> V

    func body(content: Content) -> some View {
        content
            .backgroundPreferenceValue(BoundsPreferenceKey.self) { anchor in
                GeometryReader { proxy in
                    if let anchor = anchor {
                        let scrollFrame = proxy.frame(in: .local).minY
                        let itemFrame = proxy[anchor]
                        let isVisible = itemFrame.maxY > scrollFrame
                        if isVisible && isShowNavigationTitle {
                            isShowNavigationTitle = false
                        } else if !isVisible && !isShowNavigationTitle {
                            isShowNavigationTitle = true
                        }
                    }
                    return Color.clear
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    title()
                        .bold()
                        .opacity(isShowNavigationTitle ? 1 : 0)
                        .animation(.easeIn(duration: 0.10), value: isShowNavigationTitle)
                }
            }
    }
}

extension View {
    func scrollAwareTitle<V: View>(@ViewBuilder _ title: @escaping () -> V) -> some View {
        modifier(ScrollAwareTitleModifier(title: title))
    }
}

extension View {
    func scrollAwareTitle<S: StringProtocol>(_ title: S) -> some View {
        scrollAwareTitle{
            Text(title)
        }
    }
    func scrollAwareTitle(_ title: LocalizedStringKey) -> some View {
        scrollAwareTitle{
            Text(title)
        }
    }
}

#endif
