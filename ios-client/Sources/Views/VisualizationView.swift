import SwiftUI

struct VisualizationView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VisualizationViewController {
        return VisualizationViewController()
    }

    func updateUIViewController(_ uiViewController: VisualizationViewController, context: Context) {}
}
