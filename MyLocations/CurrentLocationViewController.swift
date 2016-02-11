//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Paul Tader on 1/21/16.
//  Copyright © 2016 Paul Tader. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
  
  let locationManager = CLLocationManager()
  var location: CLLocation?
  var updatingLocation = false
  var lastLocationError: NSError?
  
  // CLGeocoder performs the geocoding and CLPlacemark contians the address, if there is one.
  let geocoder = CLGeocoder()
  var placemark: CLPlacemark?
  var performingReverseGeocoding = false
  var lastGeocodingError: NSError?
  
  var timer: NSTimer?
  
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!
  
  // Here we set setting for the LocationManager, ask for permission 
  // tell it we are the delegate, want accuracy to ten meters and then 
  // actually start the location manager.
  
  @IBAction func getLocation(){
    
    let authStatus = CLLocationManager.authorizationStatus()
    
    if authStatus == .NotDetermined {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    
    if authStatus == .Denied || authStatus == .Restricted {
      showLocationServicesDeniedAlert()
      return
    }
    
    if updatingLocation {
      stopLocationManager()
    } else {
      location = nil
      lastLocationError = nil
      placemark = nil
      lastGeocodingError = nil
      startLocationManager()
    }
    
    updateLabels()
    configureGetButton()
  }
  
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled",
      message:
    "Please enable location services for this app in Settings.",
      preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
    alert.addAction(okAction)
    
    presentViewController(alert, animated: true, completion: nil)
  }
  
  func updateLabels(){
    if let location = location {
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
      tagButton.hidden = false
      messageLabel.text = ""
      
      if let placemark = placemark {
        addressLabel.text = stringFromPlacemark(placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching for Address..."
      } else if lastGeocodingError != nil {
        addressLabel.text = "No Address Found"
      }
    
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.hidden = true
      
      let statusMessage: String
      if let error = lastLocationError {
        if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          statusMessage = "Error Getting Location"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = "Tap 'Get My Location' to Start"
      }
      
      messageLabel.text = statusMessage
    }
  }
  
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
      // ...just so we don't run forever. "didTimeOut" is my method
      timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      // Have to stop the time if it found a location.
      if let timer = timer {
        timer.invalidate()
      }
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
    }
  }
  
  func didTimeOut () {
  print("*** Timed out.")
  
  if location == nil {
    stopLocationManager()
    lastLocationError = NSError(domain:"MyLocationsErrorDomain", code: 1, userInfo: nil)
    updateLabels()
    configureGetButton()
    }
  }
  
  func configureGetButton() {
    if updatingLocation {
      getButton.setTitle("Stop", forState: .Normal)
    } else {
      getButton.setTitle("Get My Location", forState: .Normal)
    }
  }
  
  func stringFromPlacemark(placemark: CLPlacemark) -> String {
    var line1 = ""
    
    if let s = placemark.subThoroughfare {
      line1 += s + " "
    }
    
    if let s = placemark.thoroughfare {
      line1 += s
    }
    
    var line2 = ""
    
    if let s = placemark.locality {
      line2 += s + " "
    }
    
    if let s = placemark.administrativeArea {
      line2 += s + " "
    }
    if let s = placemark.postalCode {
      line2 += s
    }
    
    return line1 + "\n" + line2
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    configureGetButton()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "TagLocation"{
      let navigationController = segue.destinationViewController as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsViewController
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
    }
  }

  //MARK: - CLLocatioManagerDelegate
  // delegate methods for location manager
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print("didFailWithError, \(error)")
    
    // LocationUnknown is a temporary failure. It will continue.
    if error.code == CLError.LocationUnknown.rawValue {
      return
    }
    
    lastLocationError = error
    stopLocationManager()
    updateLabels()
    configureGetButton()
    
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      print("newLocation.timestamp is \(newLocation.timestamp.timeIntervalSinceNow)")
      return
    }
    
    // Some locations might return a negative value. Ignore them.
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    var distance = CLLocationDistance(DBL_MAX)
    if let location = location {
      distance = newLocation.distanceFromLocation(location)
      print("*** New location is \(distance) meters from the old location")
    }
    
    // Short circuiting example. If location is nil, the second condition isn't looked at, 
    // if it is not nil, then we can be sure it contains SOMETHING so force unwrap.
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      lastLocationError = nil
      location = newLocation
      updateLabels()
    
    if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
      print("*** We're done!")
      stopLocationManager()
      configureGetButton()

      if distance > 0 {
      performingReverseGeocoding = false
      }
    }
    
    if !performingReverseGeocoding {
      print("*** Going to geocode")
      
      performingReverseGeocoding = true
      
      // Clousure alert! This code will not run until geocoder has run.
      // It is given to the geocoder object, but not run.

      geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
        placemarks, error in
        //print("*** Found placemarks: \(placemarks), error: \(error)")
        
        self.lastGeocodingError = error
        // "if there's no error and the unwrapped placemarks array is not empty, continue."
        if error == nil, let p = placemarks where !p.isEmpty {
          self.placemark = p.last
        } else {
          self.placemark = nil
        }
        
        self.performingReverseGeocoding = false
        self.updateLabels()
        })
      }
    } else if distance < 1.0 {
      let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
      print("*** timeInterval is now \(timeInterval)")
      if timeInterval > 10 {
        print("*** Force done!")
        stopLocationManager()
        updateLabels()
        configureGetButton()
      }
    }
  }


}