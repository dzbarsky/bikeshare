import UIKit
import Foundation
import CoreLocation

class BikeStation {
  
  let name: String
  let coordinate: CLLocationCoordinate2D
  let id: String
  
  init(dictionary:NSDictionary)
  {
    name = dictionary["name"] as String
    id = dictionary["_id"] as String
    let lat = dictionary["lat"] as CLLocationDegrees
    let lng = dictionary["lng"] as CLLocationDegrees
    coordinate = CLLocationCoordinate2DMake(lat, lng)
  }
}
