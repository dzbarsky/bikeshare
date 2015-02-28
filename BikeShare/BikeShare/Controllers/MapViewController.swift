import AVFoundation
import Foundation
import Darwin

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, AVCaptureMetadataOutputObjectsDelegate {
  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet weak var pinImageVerticalConstraint: NSLayoutConstraint!
  @IBOutlet weak var returnBike: UIButton!
  @IBOutlet weak var elapsedTime: UILabel!

  let locationManager = CLLocationManager()
  let net = Net()
  let userId = "545fb828e4b0d65c29c4b567"
  var isUnlockingBike = false
  var previewLayer = CALayer()
  var reservationExpiration = NSTimeInterval()
  var timer = NSTimer()
  var timerLabel = UILabel(frame: CGRectMake(0, 0, 200, 21))
  var currentBikeId = ""
  var closestStationId = ""
  
  override func viewDidLoad() {
    self.returnBike.hidden = true
    self.elapsedTime.hidden = true
    super.viewDidLoad()
    locationManager.delegate = self
    mapView.delegate = self
    locationManager.requestWhenInUseAuthorization()
    let session = AVCaptureSession()
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
    let input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: nil) as AVCaptureDeviceInput
    session.addInput(input)
    let output = AVCaptureMetadataOutput()
    output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    session.addOutput(output)
    output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
    
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    let bounds = self.view.layer.bounds
    previewLayer.bounds = bounds
    previewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
    previewLayer.hidden = true
    
    self.view.layer.addSublayer(previewLayer)
    
    timerLabel.center = CGPointMake(160, 284)
    timerLabel.textColor = UIColor.redColor()
    timerLabel.textAlignment = NSTextAlignment.Center
    timerLabel.text = "Scan the bike's QR code"
    timerLabel.hidden = true
    self.view.addSubview(timerLabel)
    
    returnBike.addTarget(self, action: "returnBikeInUse", forControlEvents: .TouchUpInside)
    
    session.startRunning()
  }
  
  func returnBikeInUse() {
    
    self.returnBike.hidden = true
    //self.elapsedTime.hidden = true
    
    let url = "http://sd-bikeshare.herokuapp.com/bikes/\(self.currentBikeId)/return?station=\(self.closestStationId)"
    net.POST(url, params: [:],
      successHandler: { responseData in
        println("returned bike")
        let result = responseData.json(error: nil)! as NSDictionary
        
        let time = result["Time elapsed"]! as Double
        let alert = UIAlertController(title: "Bike Returned!", message: "Time elapsed: \(self.format(time))", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        println()
       
      },
      
      failureHandler: { error in
        println("error")
        NSLog("Error")
      }
    )
  }

  func fetchStations(coordinate: CLLocationCoordinate2D) {
    
    mapView.clear()

    let url = NSURL(string: "http://sd-bikeshare.herokuapp.com/stations")
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
      
      println("about to deserialize")
      let stations = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as [NSDictionary]
      
      println("deserialized")
      var closestMarker : StationMarker? = nil
      var minDistance = CLLocationDistance.infinity
      println("getting min distance")
      for stationJSON in stations {
        let marker = StationMarker(station: BikeStation(dictionary: stationJSON))
        marker.map = self.mapView
        let currentDistance = GMSGeometryDistance(coordinate, marker.station.coordinate)
        if (currentDistance < minDistance && marker.hasBikes()) {
          println("updating min")
          minDistance = currentDistance
          closestMarker = marker
        }
      }
      
      if let marker = closestMarker {
        marker.highlight()
        let bounds = GMSCoordinateBounds(coordinate: coordinate, coordinate: marker.station.coordinate)
        println("creating bounds")
        let insets = UIEdgeInsetsMake(80, 80, 80, 80)
        let camera = self.mapView.cameraForBounds(bounds, insets: insets)
        self.mapView.animateToCameraPosition(camera)
        self.closestStationId = marker.station.id
      }
    }
    task.resume()
  }
  
  func updateTimer() {
    let now = NSDate().timeIntervalSince1970 * 1000
    let remaining = reservationExpiration - now
    
    if remaining < 0 {
      previewLayer.hidden = true
      isUnlockingBike = false
      timer.invalidate()
      timerLabel.hidden = true
      let alert = UIAlertController(title: "Reservation Expired!", message: "", preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
    }
    
    dispatch_async(dispatch_get_main_queue()) {
      self.timerLabel.text = self.format(remaining)
    }
  }
  
  func format(time: Double) -> String {
    let seconds = Int(time / 1000) % 60
    let minutes = Int(time / 60000)
    
    return String(format:"%02d:%02d", minutes, seconds)
  }
  
  func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
    let stationMarker = mapView.selectedMarker as StationMarker
    if !stationMarker.hasBikes() {
      return
    }

    self.timerLabel.hidden = false
    previewLayer.hidden = false
    
    let url = "http://sd-bikeshare.herokuapp.com/stations/\(stationMarker.station.id)/reserve?user=\(userId)"
    net.POST(url, params: [:],
      successHandler: { responseData in
        println("post success handler")
        let result = responseData.json(error: nil)! as NSDictionary
        if let expiration = result["expiration"] as? NSTimeInterval {
          self.reservationExpiration = expiration
          dispatch_async(dispatch_get_main_queue()) {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: Selector("updateTimer"), userInfo: nil, repeats: true)
          }
        }
      },
      
      failureHandler: { error in
        println("error")
        NSLog("Error")
      }
    )
  }
  
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    if isUnlockingBike {
      return
    }
    for item in metadataObjects {
      if let metadataObject = item as? AVMetadataMachineReadableCodeObject {
        if metadataObject.type == AVMetadataObjectTypeQRCode {
          
          isUnlockingBike = true
          previewLayer.hidden = true
          timerLabel.hidden = true
          returnBike.hidden = false
          //elapsedTime.hidden = false
          
          let url = "http://sd-bikeshare.herokuapp.com/bikes/\(metadataObject.stringValue)/unlock?user=\(userId)"
          net.POST(url, params: [:], successHandler: { responseData in
            let result = responseData.json(error: nil)
          
            self.currentBikeId = result?["bike"] as String
            
            NSLog("result: \(result)")
            }, failureHandler: { error in
              self.isUnlockingBike = true
              NSLog("Error")
          })
        }
      }
    }
  }
  
  func mapView(mapView: GMSMapView!, markerInfoContents marker: GMSMarker!) -> UIView! {

    let stationMarker = marker as StationMarker
    if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
      infoView.nameLabel.text = stationMarker.station.name
      if !stationMarker.hasBikes() {
        let button = infoView.reserveButton
        button.setTitle("No bikes left!", forState: UIControlState.Normal)
        button.alpha = 0.5
      }
      return infoView
    }
    
    return nil
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "Types Segue" {
      /*let navigationController = segue.destinationViewController as UINavigationController
      let controller = segue.destinationViewController.topViewController as TypesTableViewController
      controller.selectedTypes = searchedTypes
      controller.delegate = self*/
    }
  }
  
  /*  func typesController(controller: TypesTableViewController, didSelectTypes types: [String]) {
    searchedTypes = sorted(controller.selectedTypes)
    dismissViewControllerAnimated(true, completion: nil)
  }*/
  
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    if status == .AuthorizedWhenInUse {
      locationManager.startUpdatingLocation()
      mapView.myLocationEnabled = true
      mapView.settings.myLocationButton = true
    }
  }
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    if let location = locations.first as? CLLocation {
      mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
      locationManager.stopUpdatingLocation()
      fetchStations(location.coordinate)
    }
  }
}

