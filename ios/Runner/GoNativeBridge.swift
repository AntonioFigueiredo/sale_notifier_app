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
            if let args = call.arguments as? [String: Any],
               let namestr = args["url"] as? String {
                let newValue = AppactionsGetInformation(namestr)
                result(newValue)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Name string is missing", details: nil))
            }
        case "removeEntry":
            if let args = call.arguments as? [String: Any],
               let jsonFileName = args["jsonFileName"] as? String,
               let nsuid = args["nsuid"] as? String {
                AppactionsRemoveEntryFromJSON(jsonFileName, nsuid)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "JSON file name or NSUID is missing", details: nil))
            }
        case "updateEntry":
            if let args = call.arguments as? [String: Any],
               let jsonFileName = args["jsonFileName"] as? String,
               let url = args["url"] as? String {
                let success = AppactionsUpdateJSONEntry(jsonFileName, url)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "JSON file name or URL is missing", details: nil))
            }
        case "writeEntry":
            if let args = call.arguments as? [String: Any],
               let jsonFileName = args["jsonFileName"] as? String,
               let url = args["url"] as? String {
                let success = AppactionsWriteEntryToJSON(jsonFileName, url)
                if success {
                    result(nil)
                } else {
                    result(FlutterError(code: "WRITE_ENTRY_FAILED", message: "Failed to write entry to JSON", details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "JSON file name or URL is missing", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
