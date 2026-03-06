import SwiftUI

/// A 4-digit PIN entry overlay for parent gate authentication.
struct PINEntryView: View {
    let title: String
    let onSubmit: (String) async -> Bool

    @State private var pin = ""
    @State private var showError = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.primary : Color.clear)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle().stroke(Color.primary, lineWidth: 2)
                        )
                }
            }

            if showError {
                Text("Incorrect PIN")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Hidden text field to capture keyboard input
            TextField("", text: $pin)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .focused($isFocused)
                .frame(width: 0, height: 0)
                .opacity(0)
                .onChange(of: pin) { _, newValue in
                    // Limit to 4 digits
                    if newValue.count > 4 {
                        pin = String(newValue.prefix(4))
                    }
                    // Filter non-digits
                    pin = pin.filter(\.isNumber)

                    if pin.count == 4 {
                        Task {
                            let success = await onSubmit(pin)
                            if !success {
                                showError = true
                                pin = ""
                            }
                        }
                    } else {
                        showError = false
                    }
                }
        }
        .padding(40)
        .onAppear { isFocused = true }
    }
}

#Preview {
    PINEntryView(title: "Enter Parent PIN") { pin in
        pin == "1234"
    }
}
