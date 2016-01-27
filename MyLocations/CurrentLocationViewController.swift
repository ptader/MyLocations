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
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
    }
  }
  
  func configureGetButton() {
    if updatingLocation {
      getButton.setTitle("Stop", forState: .Normal)
    } else {
      getButton.setTitle("Get My Location", forState: .Normal)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    configureGetButton()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
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
      return
    }
    
    // Some locations might return a negative value. Ignore them.
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    // Short circuiting example. If location is nil, the second condition isn't looked at, 
    // if it is not nil, then we can be sure it contains SOMETHING so force unwrap.
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      lastLocationError = nil
      location = newLocation
      updateLabels()
    }
    
    if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
      print("** We're done!")
      stopLocationManager()
      configureGetButton()
    }
    
  }
  
  
  
  
}

