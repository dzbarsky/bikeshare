import AVFoundation
import Foundation
import Darwin

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, AVCaptureMetadataOutputObjectsDelegate {
  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet weak var pinImageVerticalConstraint: NSLayoutConstraint!

  let locationManager = CLLocationManager()
  let net = Net()
  let userId = "545fb828e4b0d65c29c4b567"
  var isUnlockingBike = false
  var previewLayer = CALayer()
  var reservationExpiration = NSTimeInterval()
  var timer = NSTimer()
  var label = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    locationManager.delegate = self
    mapView.delegate = self
    locationManager.requestWhenInUseAuthorization()
    println("setting up qr stuff")
    let session = AVCaptureSession()
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
    let input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: nil) as AVCaptureDeviceInput
    session.addInput(input)
    println("added input")
    let output = AVCaptureMetadataOutput()
    output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    session.addOutput(output)
    output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
    println("added output")
    
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    let bounds = self.view.layer.bounds
    println(bounds)
    //previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    previewLayer.bounds = bounds
    previewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
    previewLayer.hidden = true
    
    println("adding sublayer")
    self.view.layer.addSublayer(previewLayer)
    println("running")
    session.startRunning()
    println("started")
  }
  
  func fetchStations(coordinate: CLLocationCoordinate2D) {
    
    mapView.clear()

    let url = NSURL(string: "http://sd-bikeshare.herokuapp.com/stations")
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
      let stations = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as [NSDictionary]
      var closestMarker : StationMarker? = nil
      var minDistance : CLLocationDistance = 9999999
      for stationJSON in stations {
          let marker = StationMarker(station: BikeStation(dictionary: stationJSON))
          marker.map = self.mapView
          let currentDistance = GMSGeometryDistance(coordinate, marker.station.coordinate)
          if currentDistance < minDistance {
            minDistance = currentDistance
            closestMarker = marker
          }
      }
  
      closestMarker?.highlight()
      let bounds = GMSCoordinateBounds(coordinate: coordinate, coordinate: closestMarker!.station.coordinate)
      let insets = UIEdgeInsetsMake(20, 20, 20, 20)
      let camera = self.mapView.cameraForBounds(bounds, insets: insets)
      self.mapView.animateToCameraPosition(camera)
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
      label.removeFromSuperview()
      var alert = UIAlertController(title: "Reservation Expired!", message: "", preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
    }
    
    let seconds = Int(remaining / 1000) % 60
    let minutes = Int(remaining / 60000)
    
    dispatch_async(dispatch_get_main_queue()) {
      self.label.text = String(format:"%02d:%02d", minutes, seconds)
    }
  }
  
  func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
    let stationMarker = mapView.selectedMarker as StationMarker
    println(stationMarker)
    
    let url = "http://sd-bikeshare.herokuapp.com/stations/\(stationMarker.station.id)/reserve?user=\(userId)"
    println(url)
    
    label = UILabel(frame: CGRectMake(0, 0, 200, 21))
    label.center = CGPointMake(160, 284)
    label.textColor = UIColor.redColor()
    label.textAlignment = NSTextAlignment.Center
    label.text = "I'm a test label"
    self.view.addSubview(label)

    previewLayer.hidden = false
    
    println("viewing map")
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
    
    /*Utility.post([:], url: url) { (succeeded: Bool, msg: String) -> () in
      var alert = UIAlertView(title: "Success!", message: msg, delegate: nil, cancelButtonTitle: "Okay.")
      if(succeeded) {
        //self.captureQRCode()
        alert.title = "Success!"
        alert.message = msg
      } else {
        alert.title = "Failed : ("
        alert.message = msg
      }
      
      // Move to the UI thread
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        // Show the alert
        alert.show()
      })
    }*/
  }
  
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    println("capturing output")
    if isUnlockingBike {
      return
    }
    for item in metadataObjects {
      if let metadataObject = item as? AVMetadataMachineReadableCodeObject {
        if metadataObject.type == AVMetadataObjectTypeQRCode {
          previewLayer.hidden = true
          let url = "http://sd-bikeshare.herokuapp.com/bikes/\(metadataObject.stringValue)/unlock?user=\(userId)"
          isUnlockingBike = true
          net.POST(url, params: [:], successHandler: { responseData in
            let result = responseData.json(error: nil)
            NSLog("result: \(result)")
            }, failureHandler: { error in
              self.isUnlockingBike = true
              NSLog("Error")
          })
          
          /*Utility.post([:], url: url) { (succeeded: Bool, msg: String) -> () in
            var alert = UIAlertView(title: "Success!", message: msg, delegate: nil, cancelButtonTitle: "Okay.")
            if(succeeded) {
              alert.title = "Success!"
              alert.message = msg
            } else {
              alert.title = "Failed : ("
              alert.message = msg
            }
          }*/
        }
      }
    }
  }
  
  func mapView(mapView: GMSMapView!, markerInfoContents marker: GMSMarker!) -> UIView! {

    let stationMarker = marker as StationMarker
    if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
      infoView.nameLabel.text = stationMarker.station.name
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

