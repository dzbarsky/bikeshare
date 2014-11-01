import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  let googleMapsApiKey = "AIzaSyAYo6ipXI5RK02Z1XppYgdCs6KUHwJgpT8"
  
  func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
    GMSServices.provideAPIKey(googleMapsApiKey)
    return true
  }
}