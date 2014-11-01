//
//  StationMarker.swift
//  BikeShare
//
//  Created by dzbarsky on 11/1/14.
//
//

class StationMarker: GMSMarker {

  let place: BikeStation
    
  init(place: BikeStation) {
    self.place = place
    super.init()
    
    position = place.coordinate
    icon = UIImage(named: "bar_pin")
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = kGMSMarkerAnimationPop
  }
  
}
