import SwiftUI

@main
struct SayItRightApp: App {
    @State private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
        }
    }
}

struct ContentView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image("barbara-attentive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())

                Text("Hello, Barbara")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Say it right! / Sag's richtig!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings.shared)
}
