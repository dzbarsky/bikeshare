import UIKit

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet weak var pinImageVerticalConstraint: NSLayoutConstraint!
  //2
  let locationManager = CLLocationManager()
  
  var mapRadius: Double {
    get {
      let region = mapView.projection.visibleRegion()
      let center = mapView.camera.target
      
      let north = CLLocation(latitude: region.farLeft.latitude, longitude: center.longitude)
      let south = CLLocation(latitude: region.nearLeft.latitude, longitude: center.longitude)
      let west = CLLocation(latitude: center.latitude, longitude: region.farLeft.longitude)
      let east = CLLocation(latitude: center.latitude, longitude: region.farRight.longitude)
      
      let verticalDistance = north.distanceFromLocation(south)
      let horizontalDistance = west.distanceFromLocation(east)
      return max(horizontalDistance, verticalDistance)*0.5
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //3
    locationManager.delegate = self
    mapView.delegate = self
    locationManager.requestWhenInUseAuthorization()
  }
  
  func fetchStations(coordinate: CLLocationCoordinate2D) {
    
    mapView.clear()

    let dictionary = ["address" : "4043 Locust St", "lat" : 39.953362, "lng" : -75.204573]
    let station = BikeStation(dictionary: dictionary)
    let station1 = StationMarker(place: station)
    
    
    let dictionary1 = ["address" : "Huntsman", "lat" : 39.9529106, "lng" : -75.1982674]
    let station3 = BikeStation(dictionary: dictionary1)
    let station2 = StationMarker(place: station3)
    
    station1.map = self.mapView
    station2.map = self.mapView
    println("debug console")
    
  }
  
  func mapView(mapView: GMSMapView!, markerInfoContents marker: GMSMarker!) -> UIView! {

    println("marker clicked")
    let stationMarker = marker as StationMarker
    println(stationMarker)
    if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
      infoView.nameLabel.text = stationMarker.place.address
      return infoView
    } else {
      return nil
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "Types Segue" {
      /*let navigationController = segue.destinationViewController as UINavigationController
      let controller = segue.destinationViewController.topViewController as TypesTableViewController
      controller.selectedTypes = searchedTypes
      controller.delegate = self*/
    }
  }
  
  /*
  // MARK: - Types Controller Delegate
  func typesController(controller: TypesTableViewController, didSelectTypes types: [String]) {
    searchedTypes = sorted(controller.selectedTypes)
    dismissViewControllerAnimated(true, completion: nil)
  }*/
  
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    // 2
    if status == .AuthorizedWhenInUse {
      
      // 3
      locationManager.startUpdatingLocation()
      
      //4
      mapView.myLocationEnabled = true
      mapView.settings.myLocationButton = true
    }
  }
  
  // 5
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    if let location = locations.first as? CLLocation {
      
      // 6
      mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
      
      // 7
      locationManager.stopUpdatingLocation()
      
      fetchStations(location.coordinate)
    }
  }
}

