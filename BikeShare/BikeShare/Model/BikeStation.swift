import UIKit
import Foundation
import CoreLocation

class BikeStation {
  
  let address: String
  let coordinate: CLLocationCoordinate2D
  
  init(dictionary:NSDictionary)
  {
    address = dictionary["address"] as String
    
    //let location = dictionary["geometry"]?["location"] as NSDictionary
    let lat = dictionary["lat"] as CLLocationDegrees
    let lng = dictionary["lng"] as CLLocationDegrees
    coordinate = CLLocationCoordinate2DMake(lat, lng)
  }
}
