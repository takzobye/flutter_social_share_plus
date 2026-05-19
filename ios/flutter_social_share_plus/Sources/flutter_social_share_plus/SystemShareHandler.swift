import Flutter
import UIKit

class SystemShareHandler {

    func share(
        text: String?,
        filePaths: [String]?,
        subject: String?,
        result: @escaping FlutterResult
    ) {
        var activityItems: [Any] = []

        if let text, !text.isEmpty {
            activityItems.append(text)
        }

        if let filePaths {
            for path in filePaths {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: path) {
                    activityItems.append(url)
                }
            }
        }

        guard !activityItems.isEmpty else {
            result("ERROR:Nothing to share – provide text or files")
            return
        }

        guard let viewController = topViewController() else {
            result("ERROR:No view controller available")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        if let subject, !subject.isEmpty {
            activityVC.setValue(subject, forKey: "subject")
        }

        // iPad requires a popover anchor.
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        activityVC.completionWithItemsHandler = { _, completed, _, error in
            if let error {
                result("ERROR:\(error.localizedDescription)")
            } else if completed {
                result("SUCCESS")
            } else {
                result("CANCELLED")
            }
        }

        viewController.present(activityVC, animated: true)
    }

    // MARK: - Private

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController {
            vc = presented
        }
        return vc
    }
}
