import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        if let registrar = controller.registrar(forPlugin: "GoNativeBridge") {
            GoNativeBridge.register(with: registrar)
        } else {
            // Handle the case where the registrar is nil
            print("Failed to get registrar for GoNativeBridge")
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}