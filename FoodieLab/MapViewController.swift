//
//  MapViewController.swift
//  FoodieLab
//
//  Created by Huy Le on 5/29/15.
//  Copyright (c) 2015 Huy Le. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
import CoreFoundation
import CoreGraphics

private let myMapX : CGFloat = 0
private let myMapY : CGFloat = 0
private let myMapWidth : CGFloat = CGSize.screenWidth()
private let myMapHeight : CGFloat = CGSize.screenHeight() - myMapY

private let searchTableViewX : CGFloat = 0
private let searchTableViewY : CGFloat = segmentedControlY + segmentedControlHeight
private let searchTableViewWidth : CGFloat = CGSize.screenWidth()
private let searchTableViewHeight : CGFloat = 0

private let segmentedControlX : CGFloat = 2
private let segmentedControlY : CGFloat = 64
private let segmentedControlWidth : CGFloat = CGSize.screenWidth() - 2*segmentedControlX
private let segmentedControlHeight : CGFloat = 35

enum SearchType {
    case relevance
    case nearby
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    private var searchBar: UISearchBar!
    private var searchTableView: UITableView!
    private var autoCompleteTimer: NSTimer?
    private var subString: String = ""
    private var pastSearchWords: [String]!
    private var pastSearchResult: [NSDictionary]!
    private var placeSearchQueries : [NSDictionary]!
    private var segmentedControl: UISegmentedControl!
    private var searchType: SearchType!
    private var placeIdArray: String!
    
    private var locationManager = CLLocationManager()
    private var mapView: MKMapView!
    private var currentLocation: CLLocation!
    private var locationArray: [CLLocation]!
    
    private var route1:MKRoute = MKRoute()
    private var route2:MKRoute = MKRoute()
    private var route3:MKRoute = MKRoute()
    private var polyLine: MKPolyline = MKPolyline()

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required init() {
        super.init(nibName: nil, bundle: nil);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Foodie Lab"
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.pastSearchResult = []
        self.pastSearchWords = []
        self.placeSearchQueries = []
        self.locationArray = []
        self.placeIdArray = ""
        
        //Search bar
        searchBar = UISearchBar()
        searchBar.frame = CGRectMake(5, 5, CGSize.screenWidth() - 50 , 50)
        searchBar.delegate = self
        searchBar.placeholder = "Enter your point of interest here"
        searchBar.autocapitalizationType = UITextAutocapitalizationType.Words
        self.navigationItem.titleView = searchBar
        
        //Map view
        mapView = MKMapView(frame: CGRect(x: myMapX, y: myMapY, width: myMapWidth, height: myMapHeight))
        mapView.delegate = self
        self.view.addSubview(mapView)
        
        //Location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //Search Table View
        searchTableView = UITableView()
        self.searchTableView = UITableView(frame: CGRect(x :searchTableViewX, y: searchTableViewY, width :searchTableViewWidth, height: searchTableViewHeight), style: UITableViewStyle.Plain)
        self.view.addSubview(searchTableView)
        self.searchTableView.hidden = true
        self.searchTableView.delegate = self
        self.searchTableView.dataSource = self
        self.searchTableView.alpha = 0
        
        //Segmented Control
        var optionArray = ["By Relevance","Nearby"]
        self.segmentedControl = UISegmentedControl(items: optionArray)
        segmentedControl.frame = CGRectMake(segmentedControlX, segmentedControlY, segmentedControlWidth, segmentedControlHeight)
        self.segmentedControl.addTarget(self, action: "segmentChanged", forControlEvents: UIControlEvents.ValueChanged)
        self.segmentedControl.enabled = true
        self.segmentedControl.hidden = true
        self.segmentedControl.backgroundColor = UIColor.whiteColor()
        self.segmentedControl.selectedSegmentIndex = 0
        self.searchType = SearchType.relevance
        self.view.addSubview(segmentedControl)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)

    }
    
    func keyboardWillHide(notification: NSNotification){
        let dictionary = notification.userInfo!
        let keyboardSize = (dictionary[UIKeyboardFrameEndUserInfoKey])?.CGRectValue().size
        var frame = self.searchTableView.frame
        frame.size.height = 0
        self.searchTableView.hidden = true
        self.segmentedControl.hidden = true
        self.searchTableView.frame = frame
        self.searchTableView.alpha = 0
        UIView.commitAnimations()
    }
    
    func keyboardWillShow(notification: NSNotification){
        let dictionary = notification.userInfo!
        let keyboardSize = (dictionary[UIKeyboardFrameEndUserInfoKey])?.CGRectValue().size
        var frame = self.searchTableView.frame
        frame.size.height = CGSize.screenHeight() - 64 - keyboardSize!.height
        self.searchTableView.hidden = false
        self.segmentedControl.hidden = false
        self.searchTableView.frame = frame
        self.searchTableView.alpha = 1
        UIView.commitAnimations()
    }
    
    // MARK: Location manager delegate
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
        println("Errors happen")
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var userLocation: CLLocation = locations[0] as! CLLocation
        locationManager.stopUpdatingLocation()
        self.currentLocation = userLocation
        let location = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)
        let region = MKCoordinateRegion(center: location, span: span)
        var currentLocationPin = MKPointAnnotation()
        currentLocationPin.coordinate = userLocation.coordinate
        currentLocationPin.title = "Current location"
        
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(currentLocationPin)
        
    }
    
    // MARK: search bar delegate
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.becomeFirstResponder()
        searchTableView.reloadData()
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: false)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        self.placeSearchQueries.removeAll(keepCapacity: false)
        self.searchTableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        var searchWordProtection = searchText.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        if count(searchWordProtection) > 1 {
            runAutocompleteWithTimer()
        }
    }
    
    func runAutocompleteWithTimer(){
        self.autoCompleteTimer?.invalidate()
        self.autoCompleteTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("searchAutocompleteLocationsWithSubstring:"), userInfo: nil, repeats: false)
    }

    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        self.subString = searchBar.text
        return true
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.autoCompleteTimer?.invalidate()
        self.searchAutocompleteLocationsWithSubstring(self.subString)
    }
    
    func searchAutocompleteLocationsWithSubstring(asdfaf : AnyObject){
        self.searchTableView.reloadData()
        if let found = find(self.pastSearchWords, self.subString) {
            for result in self.pastSearchResult {
                if result["keyword"] as? String == self.subString{
                    self.placeSearchQueries?.removeAll(keepCapacity: false)
                    let places = result["results"] as! [NSDictionary]
                    for place in places {
                        self.placeSearchQueries?.append(place)
                    }
                    self.searchTableView.reloadData()
                }
            }
        }
        else{
            self.pastSearchWords.append(self.subString)
            self.retrieveGooglePlaceInformation(self.subString, completion: { (results) -> () in
                if let places = results {
                    self.placeSearchQueries?.removeAll(keepCapacity: false)
                    for place in places {
                        
                        self.placeSearchQueries?.append(place)
                        if (self.searchType == SearchType.relevance){
                        }
                        else{
                            
                        }
                        let searchResult = ["keyword": self.subString, "results" : places]
                        self.pastSearchResult.append(searchResult)
                        self.searchTableView.reloadData()
                    }
                }
            })
        }
    }
    
    func retrieveGooglePlaceInformation(searchWord : String!, completion: ([NSDictionary]?) -> ()){
        var searchWordProtection = searchWord.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        var urlString: String = ""
        if count(searchWordProtection) > 0 {
            if (self.searchType == SearchType.relevance){
                urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(searchWord)&key=AIzaSyDZeZ2BweGVdUli7hSMfljgtAYQp4RAV5U"
            }
            else {
                println(self.currentLocation.coordinate.longitude)
                urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(searchWord)&types=establishment&location=\(self.currentLocation.coordinate.latitude),\(self.currentLocation.coordinate.longitude)&radius=50000&key=AIzaSyDZeZ2BweGVdUli7hSMfljgtAYQp4RAV5U"
            }
            let url = NSURL(string: urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
            let defaultConfigObject = NSURLSessionConfiguration.defaultSessionConfiguration()
            
            let delegateFreeSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: nil)
            
            let request = NSURLRequest(URL: url!)
            let task = delegateFreeSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSDictionary
                if dictionary != nil {
                    let results = dictionary!["predictions"] as? [NSDictionary]
                    let status : String! = (dictionary!["status"] as? String) ?? ""
                    if (status == "NOT_FOUND" || status == "REQUEST_DENIED" || error != nil){
                        completion(nil)
                    }
                    else{
                        completion(results)
                    }
                }
            })
            task.resume()
        }
    }
    
    
    // MARK: tableView delegate and datasource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "PlaceCellIdentifier"
        var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: identifier)
        }
        let place = self.placeSearchQueries![indexPath.row]
        
        cell!.textLabel?.text = place["description"] as? String
        return cell!
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.placeSearchQueries?.count ?? 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.searchBar.resignFirstResponder()
        let place = self.placeSearchQueries[indexPath.row]
        println(place)
        if let reference = place["reference"] as? String {
            self.placeIdArray = reference
        }
        
        if let placeName = place["description"] as? String{
            self.searchBar.text = ""
            
            SVGeocoder.geocode(placeName, completion: { placemarks, urlResponse, error in
                if nil == error {
                    let placeMarks = placemarks as NSArray
                    if placeMarks.count > 0{
                        var firstResult : SVPlacemark = placeMarks.firstObject as! SVPlacemark
                        
                        var aLocation = CLLocation(latitude: firstResult.coordinate.latitude, longitude: firstResult.coordinate.longitude)
                       
                        var nextLocationPin = MKPointAnnotation()
                        nextLocationPin.coordinate = firstResult.coordinate
                        nextLocationPin.title = placeName
                        nextLocationPin.subtitle = "Distance: " + (NSString(format: "%.1f", self.currentLocation.distanceFromLocation(aLocation)/1000) as String) + " Km"

                        if self.locationArray.count < 3 {
                            self.locationArray.append(aLocation)
                            
                            //self.distance1 = self.firstLocation.distanceFromLocation(self.currentLocation)
                            //println("HERE ____\(self.distance1)")
                        }
                        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                        let region = MKCoordinateRegionMake(firstResult.coordinate, span)
                        self.mapView.setRegion(region, animated: true)
                        self.mapView.addAnnotation(nextLocationPin)
                    }
                }
                
                if self.locationArray.count == 3{
                    self.findShortestRouteWithLocations()

                }
            })
        }
    }
    
    // MARK: mapView delegate
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.redColor()
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        } 
        return nil
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:"loc")
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.InfoDark) as! UIView
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        var photoVC = PhotoDetailViewController()
        photoVC.placeId = self.placeIdArray
        self.navigationController?.pushViewController(photoVC, animated: true)
    }

    func findShortestRouteWithLocations(){
        var distance1 = self.currentLocation.distanceFromLocation(self.locationArray[0])
        var distance2 = self.currentLocation.distanceFromLocation(self.locationArray[1])
        var distance3 = self.currentLocation.distanceFromLocation(self.locationArray[2])
        if distance1 < distance2 && distance1 < distance3 {
            var distance4 = self.locationArray[0].distanceFromLocation(self.locationArray[1])
            var distance5 = self.locationArray[0].distanceFromLocation(self.locationArray[2])
            if distance4 < distance5{
                drawRouteWithPlacemarks(self.currentLocation, firstLocation: locationArray[0], secondLocation: locationArray[1], thirdLocation: locationArray[2])
                println("Best route OABC")
            }
            else {
                println("Best route OACB")
                drawRouteWithPlacemarks(self.currentLocation, firstLocation: locationArray[0], secondLocation: locationArray[2], thirdLocation: locationArray[1])
            }
        }
        else if distance2 < distance3 && distance2 < distance1 {
            var distance4 = self.locationArray[1].distanceFromLocation(self.locationArray[0])
            var distance5 = self.locationArray[1].distanceFromLocation(self.locationArray[2])
            if distance4 < distance5{
                println("Best route OBAC")
                drawRouteWithPlacemarks(self.currentLocation, firstLocation: locationArray[1], secondLocation: locationArray[0], thirdLocation: locationArray[2])

            }
            else {
                println("Best route OBCA")
                drawRouteWithPlacemarks(self.currentLocation, firstLocation: locationArray[1], secondLocation: locationArray[2], thirdLocation: locationArray[0])

            }
        }
        else{
            var distance4 = self.locationArray[2].distanceFromLocation(self.locationArray[0])
            var distance5 = self.locationArray[2].distanceFromLocation(self.locationArray[1])
            if distance4 < distance5{
                println("Best route OCAB")
                drawRouteWithPlacemarks(self.currentLocation, firstLocation: locationArray[2], secondLocation: locationArray[0], thirdLocation: locationArray[1])

            }
            else {
                println("Best route OCBA")
                drawRouteWithPlacemarks(self.currentLocation, firstLocation: locationArray[2], secondLocation: locationArray[1], thirdLocation: locationArray[0])

            }
        }
    }

    func drawRouteWithPlacemarks(origin: CLLocation,firstLocation: CLLocation, secondLocation: CLLocation,thirdLocation: CLLocation){
        
        var currentLocationMark = MKPlacemark(coordinate: origin.coordinate, addressDictionary: nil)
        var firstLocationMark = MKPlacemark(coordinate: firstLocation.coordinate, addressDictionary: nil)
        var secondLocationMark = MKPlacemark(coordinate: origin.coordinate, addressDictionary: nil)
        var thirdLocationMark = MKPlacemark(coordinate: origin.coordinate, addressDictionary: nil)

        var sourceItem = MKMapItem(placemark: currentLocationMark)
        var firstDestinationItem = MKMapItem(placemark: firstLocationMark)
        var secondDestinationItem = MKMapItem(placemark: secondLocationMark)
        var thirdDestinationItem = MKMapItem(placemark: thirdLocationMark)
        
        var location2DCoordinateArray:[CLLocationCoordinate2D]
        location2DCoordinateArray = []
        location2DCoordinateArray.append(CLLocationCoordinate2D(latitude: origin.coordinate.latitude, longitude: origin.coordinate.longitude))
        location2DCoordinateArray.append(CLLocationCoordinate2D(latitude: firstLocation.coordinate.latitude, longitude: firstLocation.coordinate.longitude))
        location2DCoordinateArray.append(CLLocationCoordinate2D(latitude: secondLocation.coordinate.latitude, longitude: secondLocation.coordinate.longitude))
        location2DCoordinateArray.append(CLLocationCoordinate2D(latitude: thirdLocation.coordinate.latitude, longitude: thirdLocation.coordinate.longitude))

        self.polyLine = MKPolyline(coordinates: &location2DCoordinateArray, count: location2DCoordinateArray.count)
        self.polyLine.title = "one";
        self.mapView.addOverlay(polyLine);
        
        var request1:MKDirectionsRequest = MKDirectionsRequest()
        request1.setSource(sourceItem)
        request1.setDestination(firstDestinationItem)
        
    }
    
    // MARK: segmentControl
    func segmentChanged(){
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.searchType = SearchType.relevance
        }
        else {
            self.searchType = SearchType.nearby
        }
    }

}

