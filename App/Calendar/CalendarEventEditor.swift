import SwiftUI
import EventKitUI

/// A SwiftUI wrapper around Apple's native Calendar Event Editor UI
struct CalendarEventEditor: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.eventStore = eventStore
        vc.event = event
        vc.editViewDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: CalendarEventEditor
        
        init(_ parent: CalendarEventEditor) {
            self.parent = parent
        }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
