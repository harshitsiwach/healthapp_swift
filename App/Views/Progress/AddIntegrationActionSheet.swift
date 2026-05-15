import SwiftUI

/// Action sheet to allow creating native Calendar events or Reminders from the app
struct AddIntegrationActionSheet: View {
    @Environment(\.theme) var colors
    @Environment(\.dismiss) private var dismiss
    
    var onAddAppointment: () -> Void
    var onAddReminder: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Add to Apple")
                .font(.headline)
                .padding(.top, 24)
                .padding(.bottom, 16)
            
            Divider()
            
            // Options
            Button(action: {
                dismiss()
                onAddAppointment()
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title3)
                        .foregroundColor(colors.neonBlue)
                        .frame(width: 30)
                    Text("New Calendar Appointment")
                        .font(.body)
                        .foregroundColor(colors.textPrimary)
                    Spacer()
                }
                .padding()
            }
            
            Divider()
            
            Button(action: {
                dismiss()
                onAddReminder()
            }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.title3)
                        .foregroundColor(colors.neonOrange)
                        .frame(width: 30)
                    Text("New Apple Reminder")
                        .font(.body)
                        .foregroundColor(colors.textPrimary)
                    Spacer()
                }
                .padding()
            }
            
            Spacer()
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }
}
