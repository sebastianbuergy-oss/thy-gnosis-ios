import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = WebViewController()
        window.overrideUserInterfaceStyle = .dark
        window.backgroundColor = UIColor(red: 11 / 255, green: 11 / 255, blue: 13 / 255, alpha: 1)
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
