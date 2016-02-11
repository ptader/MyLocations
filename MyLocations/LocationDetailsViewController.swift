//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Paul Tader on 2/3/16.
//  Copyright © 2016 Paul Tader. All rights reserved.
//

import UIKit
import CoreLocation

// Global constant, lives outside class but only by LocationDetailsViewController.
// Needs to use a closure to init all its values.
private let dateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateStyle = .MediumStyle
  formatter.timeStyle = .ShortStyle
  print("*** Created a dateFormatter object.")
  return formatter
}()

class LocationDetailsViewController: UITableViewController {
  var coordinate = CLLocationCoordinate2D(latitude: 0, longitude:0 )
  var placemark: CLPlacemark?
  
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  
  @IBAction func done() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func cancel() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad () {
    super.viewDidLoad()
    
    descriptionTextView.text = ""
    categoryLabel.text = ""
   
    latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
    longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
    
    if let placemark = placemark {
      addressLabel.text = stringFromPlacemark(placemark)
    } else {
      addressLabel.text = "No Address Found"
    }
    
    dateLabel.text = formatDate(NSDate())
  }
  
  func formatDate(date: NSDate) -> String {
    return dateFormatter.stringFromDate(date)
  }

  
  func stringFromPlacemark(placemark: CLPlacemark) -> String {
    var text = ""
    
    if let s = placemark.subThoroughfare {
      text += s + " "
    }
    if let s = placemark.thoroughfare {
      text += s + " "
    }
    if let s = placemark.locality {
      text += s + ", "
    }
    if let s = placemark.administrativeArea {
      text += s + " "
    }
    if let s = placemark.postalCode {
      text += s + ", "
    }
    if let s = placemark.country {
      text += s
    }
    return text
  }
  
  
}
