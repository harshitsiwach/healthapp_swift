import SwiftUI
import TipKit

// MARK: - App Tips

struct LogMealTip: Tip {
    var title: Text {
        Text("Log Your First Meal")
    }
    
    var message: Text? {
        Text("Tap the + button to scan your food or type what you ate. Gemma 4 will estimate the calories for you.")
    }
    
    var image: Image? {
        Image(systemName: "camera.fill")
    }
}

struct CheckCaloriesTip: Tip {
    var title: Text {
        Text("Track Your Progress")
    }
    
    var message: Text? {
        Text("Your daily calorie target adjusts automatically based on your workouts from Apple Health.")
    }
    
    var image: Image? {
        Image(systemName: "flame.fill")
    }
}

struct UseSiriTip: Tip {
    var title: Text {
        Text("Try Siri Shortcuts")
    }
    
    var message: Text? {
        Text("Say 'Hey Siri, log my meal' to quickly open food logging without tapping through the app.")
    }
    
    var image: Image? {
        Image(systemName: "mic.fill")
    }
}

struct ScanReportTip: Tip {
    var title: Text {
        Text("Scan Medical Reports")
    }
    
    var message: Text? {
        Text("Take a photo of your lab reports and get instant AI-powered insights in simple language.")
    }
    
    var image: Image? {
        Image(systemName: "doc.text.viewfinder")
    }
}

struct WidgetTip: Tip {
    var title: Text {
        Text("Add a Widget")
    }
    
    var message: Text? {
        Text("Long-press your home screen and add the Daily Health widget to see your calories at a glance.")
    }
    
    var image: Image? {
        Image(systemName: "square.grid.2x2.fill")
    }
}

// MARK: - Tip Manager

final class TipManager {
    static let shared = TipManager()
    
    let logMealTip = LogMealTip()
    let checkCaloriesTip = CheckCaloriesTip()
    let useSiriTip = UseSiriTip()
    let scanReportTip = ScanReportTip()
    let widgetTip = WidgetTip()
    
    private init() {}
    
    static func configure() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
}
