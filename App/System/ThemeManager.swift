import SwiftUI

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @AppStorage("appColorScheme") var colorSchemeRaw: String = "dark" {
        didSet { objectWillChange.send() }
    }
    
    var colorScheme: ColorScheme {
        get { colorSchemeRaw == "light" ? .light : .dark }
        set { colorSchemeRaw = newValue == .light ? "light" : "dark" }
    }
    
    var isDark: Bool { colorScheme == .dark }
    
    func toggle() {
        withAnimation(.smooth) {
            colorScheme = isDark ? .light : .dark
        }
    }
}
