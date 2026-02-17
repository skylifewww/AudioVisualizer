import SwiftUI

@main
struct MusicVisualizerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(MainViewModel())
        }
    }
}
