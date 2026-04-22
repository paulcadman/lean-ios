import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let label = UILabel(frame: viewController.view.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = .label
        label.text = "Lean says: \(lean_ios_add_one(41))"

        viewController.view.addSubview(label)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
