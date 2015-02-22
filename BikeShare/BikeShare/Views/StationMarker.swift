//
//  StationMarker.swift
//  BikeShare
//
//  Created by dzbarsky on 11/1/14.
//
//

class StationMarker: GMSMarker {

  let station: BikeStation
    
  init(station: BikeStation) {
    self.station = station
    super.init()
    
    position = station.coordinate
    icon = UIImage(named: "station")
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = kGMSMarkerAnimationPop
    
    if station.empty {
      disable()
    }
  }
  
  func highlight() {
    icon = UIImage(named: "station-gold")
  }
  
  func disable() {
    icon = UIImage(named: "station-grey")
  }
  
  func hasBikes() -> Bool {
    return !station.empty
  }
  
}
