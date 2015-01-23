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
    icon = UIImage(named: "rsz_1bike")
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = kGMSMarkerAnimationPop
  }
  
}
