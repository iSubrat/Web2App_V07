import UIKit
import Flutter
//import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var strURL = "";

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let referralChannel = FlutterMethodChannel(name: "mightyweb/channel",binaryMessenger: controller.binaryMessenger)
    
    referralChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if(call.method == "mightyweb/events" && self.strURL != ""){
            print(self.strURL)
            result(self.strURL)
        }else {
            result("")
        }
    })
//    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    
        let newURL = URL(string: url.absoluteString)!
        self.strURL = newURL.absoluteString;
        print(newURL);
        if let range = self.strURL.range(of: "mightyweb:") {
            self.strURL.removeSubrange(range)
        }
        print(self.strURL)
        
        return false
    }
}

//private func registerPlugins(registry: FlutterPluginRegistry) {
//    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
//       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
//    }
//}

extension URL {
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}



