import SwiftUI
import MetalKit

struct VisualizationView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: MainViewModel

    func makeUIViewController(context: Context) -> VisualizationViewController {
        let vc = VisualizationViewController()
        vc.viewModel = viewModel
        return vc
    }

    func updateUIViewController(_ uiViewController: VisualizationViewController, context: Context) {}
}
