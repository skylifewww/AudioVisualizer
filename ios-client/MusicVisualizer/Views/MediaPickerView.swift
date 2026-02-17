// import SwiftUI
// import MediaPlayer

// struct MediaPickerView: UIViewControllerRepresentable {
//     @Binding var selectedTrack: MPMediaItem?
//     @Environment(\.presentationMode) var presentationMode

//     func makeUIViewController(context: Context) -> UIViewController {
//         let picker = MPMediaPickerController(mediaTypes: .music)
//         picker.delegate = context.coordinator
//         picker.allowsPickingMultipleItems = false
        
//         let controller = UIViewController()
//         controller.addChild(picker)
//         controller.view.addSubview(picker.view)
//         picker.view.translatesAutoresizingMaskIntoConstraints = false
//         NSLayoutConstraint.activate([
//             picker.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
//             picker.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
//             picker.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
//             picker.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
//         ])
//         picker.didMove(toParent: controller)
        
//         return controller
//     }

//     func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

//     func makeCoordinator() -> Coordinator {
//         Coordinator(self)
//     }

//     class Coordinator: NSObject, MPMediaPickerControllerDelegate {
//         let parent: MediaPickerView

//         init(_ parent: MediaPickerView) {
//             self.parent = parent
//         }

//         func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
//             DispatchQueue.main.async {
//                 self.parent.selectedTrack = mediaItemCollection.items.first
//                 self.parent.presentationMode.wrappedValue.dismiss()
//             }
//         }

//         func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
//             DispatchQueue.main.async {
//                 self.parent.presentationMode.wrappedValue.dismiss()
//             }
//         }
//     }
// }
