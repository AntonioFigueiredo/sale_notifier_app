import Flutter
import UIKit
import Appactions

class GoNativeBridge: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "gonative_channel", binaryMessenger: registrar.messenger())
        let instance = GoNativeBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInformation":
            guard let args = call.arguments as? [String: Any],
            let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "URL is missing", details: nil))
                return
            }
    
            DispatchQueue.global(qos: .userInitiated).async {
                let newValue = AppactionsGetInformation(url)
                DispatchQueue.main.async {
                    result(newValue)
                }
            }
        case "removeEntry":
            guard let args = call.arguments as? [String: Any],
            let jsonFileName = args["jsonFileName"] as? String,
            let nsuid = args["nsuid"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing parameters", details: nil))
                return
            }
    
            DispatchQueue.global(qos: .userInitiated).async {
                AppactionsRemoveEntryFromJSON(jsonFileName, nsuid)
                DispatchQueue.main.async {
                    result(nil)
                }
            }
        case "updateEntry":
            guard let args = call.arguments as? [String: Any],
            let jsonFileName = args["jsonFileName"] as? String,
            let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing parameters", details: nil))
                return
            }
        
            DispatchQueue.global(qos: .userInitiated).async {
                let success = AppactionsUpdateJSONEntry(jsonFileName, url)
                DispatchQueue.main.async {
                    result(success)
                }
            }
        case "writeEntry":
            guard let args = call.arguments as? [String: Any],
            let jsonFileName = args["jsonFileName"] as? String,
            let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing parameters", details: nil))
                return
            }
        
            DispatchQueue.global(qos: .userInitiated).async {
                let success = AppactionsWriteEntryToJSON(jsonFileName, url)
                DispatchQueue.main.async {
                    if success {
                        result(nil)
                    } else {
                        result(FlutterError(code: "WRITE_FAILED", message: "Failed to write entry", details: nil))
                    }
                }
            }
        case "writeTestEntry":
            guard let args = call.arguments as? [String: Any],
            let jsonFileName = args["jsonFileName"] as? String,
            let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing parameters", details: nil))
                return
            }
        
            DispatchQueue.global(qos: .userInitiated).async {
                let success = AppactionsWriteTestEntryToJSON(jsonFileName, url)
                DispatchQueue.main.async {
                    if success {
                        result(nil)
                    } else {
                        result(FlutterError(code: "WRITE_TEST_FAILED", message: "Failed to write test entry", details: nil))
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
