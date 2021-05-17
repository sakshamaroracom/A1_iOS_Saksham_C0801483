//
//  ViewController.swift
//  A1_iOS_Saksham_C0801483
//
//  Created by Saksham Arora on 16/05/21.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var directionBtn: UIButton!
    
    // create location manager
    var locationMnager = CLLocationManager()
    
    // create the places array
    var places:[CLLocationCoordinate2D] = []
    
    // title dict
    var titles:[String:Bool] = ["A":false, "B": false, "C": false]
    
    //array for distance
    var middleArray:[MKAnnotation] = []
    
    
    // Function to load the Map View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set up map
        map.isZoomEnabled = false
        map.showsUserLocation = true
        
        directionBtn.isHidden = false
        
        // we assign the delegate property of the location manager to be this class
        locationMnager.delegate = self
        
        // we define the accuracy of the location
        locationMnager.desiredAccuracy = kCLLocationAccuracyBest
        
        // rquest for the permission to access the location
        locationMnager.requestWhenInUseAuthorization()
        
        // start updating the location
        locationMnager.startUpdatingLocation()
        
        // add double tap
        addTap()
        
        // giving the delegate of MKMapViewDelegate to this class
        map.delegate = self
    }
    
    //MARK: - Drawing route between for places
    
    @IBAction func drawRoute(_ sender: UIButton) {
        map.removeOverlays(map.overlays)
        self.removeDistanceAnnotations()
        var polyLinePlaces = places
        if let  first = places.first {
            polyLinePlaces.append(first)
            for i in 0 ..< polyLinePlaces.count {
                let place = polyLinePlaces[i]
                if i >= places.count {
                    return
                }
                // draw route between two places
                let destination: CLLocationCoordinate2D = polyLinePlaces[i + 1]
                let sourcePlaceMark = MKPlacemark(coordinate: place)
                let destinationPlaceMark = MKPlacemark(coordinate: destination)
                
                // request a direction
                let directionRequest = MKDirections.Request()
                
                // assign the source and destination properties of the request
                directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
                directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
                
                // transportation type
                directionRequest.transportType = .automobile
                
                // calculate the direction
                let directions = MKDirections(request: directionRequest)
                directions.calculate { (response, error) in
                    guard let directionResponse = response else {return}
                    
                    // create the route
                    let route = directionResponse.routes[0]
                    
                    // drawing a polyline
                    self.map.addOverlay(route.polyline, level: .aboveRoads)
                    
                    // define the bounding map rect
                    let rect = route.polyline.boundingMapRect
                    self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
                    self.map.setRegion(MKCoordinateRegion(rect), animated: true)
                }
            }
        }
    }
    
    
    //MARK: - Adding Polyline Method
    func addPolyline() {
        var polyLinePlaces = places
        if let  first = places.first {
            polyLinePlaces.append(first)
            let polyline = MKPolyline(coordinates: polyLinePlaces, count: polyLinePlaces.count)
            polyline.title = "Draw Markers"
            map.addOverlay(polyline)
        }
    }
    
    //MARK: -Adding Polygon Method
    func addPolygon() {
        let polygon = MKPolygon(coordinates: places, count: places.count)
        map.addOverlay(polygon)
    }
    
    //MARK: - Tap Function
    func addTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        map.addGestureRecognizer(doubleTap)
    }
    
    //MARK: - Adding Annotation
    @objc func dropPin(sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: map)
        let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
        
        //Checking if anotation is already there
        for i in 0 ..< places.count{
            let place = places[i]
            let coordinate1 = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let coordinate2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distanceInMeters = coordinate1.distance(from: coordinate2)
            if (place.latitude == coordinate.latitude && place.latitude == coordinate.latitude) || distanceInMeters < 100{
                
                //Remove annotation if we already there
                places.remove(at: i)
                removePin(coordinate: place)
                return
            }
        }
        if places.count == 3 {
            
            // Remove all annotation if we already have A,B,C
            removePin()
        }
        
        //Add new annotation
        addAnotation(title: getTitle(), subtitle: nil, coordinate: coordinate)
        places.append(coordinate)
        
        // We have all A,B,C Draw polyline and polygon
        if places.count == 3 {
            self.addPolyline()
            self.addPolygon()
        }
    }
    
    //MARK: Geting Title for Annotation - A,B,C
    func getTitle() -> String {
        for title in titles.keys.sorted(){
            if !(titles[title] ?? false){
                titles[title] = true
                return title
            }
        }
        return ""
    }
    
    //MARK: - Remove Pin From Map
    func removePin(coordinate : CLLocationCoordinate2D? = nil) {
        //Remove overlays
        map.removeOverlays(map.overlays)
        //remove distance annotations
        self.removeDistanceAnnotations()
        
        //Remove Annotation
        for annotation in map.annotations {
            if let coordinate = coordinate, annotation.coordinate.latitude == coordinate.latitude, annotation.coordinate.latitude == coordinate.latitude {
                map.removeAnnotation(annotation)
                titles[(annotation.title ?? "") ?? ""] = false
                return
            }
            else if coordinate == nil , places.contains(where: { (coordinate) -> Bool in
                return annotation.coordinate.latitude == coordinate.latitude &&  annotation.coordinate.latitude == coordinate.latitude
            }){
                titles[(annotation.title ?? "") ?? ""] = false
                map.removeAnnotation(annotation)
            }
        }
        places.removeAll()
    }
    //MARK: Remove Distance Annotations
    func removeDistanceAnnotations(){
        for annotation in self.middleArray{
            map.removeAnnotation(annotation)
        }
        self.middleArray.removeAll()
    }
    
    //MARK:- Configure and Add New Annotation
    func addAnotation(title:String?, subtitle: String?, coordinate:CLLocationCoordinate2D, isMiddle:Bool = false){
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = coordinate
        annotation.subtitle = subtitle
        map.addAnnotation(annotation)
        if isMiddle{
            middleArray.append(annotation)
        }
    }
    
    //MARK: - Display User Location Method
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees,
                         title: String,
                         subtitle: String) {
        // 2nd step - define span
        let latDelta: CLLocationDegrees = 0.05
        let lngDelta: CLLocationDegrees = 0.05
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        
        // 3rd step is to define the location
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // 4th step is to define the region
        let region = MKCoordinateRegion(center: location, span: span)
        
        // 5th step is to set the region for the map
        map.setRegion(region, animated: true)
        
        // 6th step is to define annotation
        self.addAnotation(title: title, subtitle: subtitle, coordinate: location)
        
    }
    
    //MARK: Get Distance between Marker and User Location
    func getDistance(title:String)-> String{
        switch title {
        case "A":
            if let lat = places.first?.latitude, let long = places.first?.longitude, let myLocation = locationMnager.location{
                let coordinate1 = CLLocation(latitude: lat, longitude: long)
                let distanceInMeters = coordinate1.distance(from: myLocation)
                return String(distanceInMeters/1000) + " KM"
            }
        case "B":
            if let myLocation = locationMnager.location{
                let lat = places[1].latitude
                let long = places[1].longitude
                let coordinate1 = CLLocation(latitude: lat, longitude: long)
                let distanceInMeters = coordinate1.distance(from: myLocation)
                return String(distanceInMeters/1000) + " KM"
            }
        case "C":
            if let lat = places.last?.latitude, let long = places.last?.longitude, let myLocation = locationMnager.location{
                let coordinate1 = CLLocation(latitude: lat, longitude: long)
                let distanceInMeters = coordinate1.distance(from: myLocation)
                return String(distanceInMeters/1000) + " KM"
            }
        default:
            break
        }
        return "0"
    }
    
    //MARK:- Add Distance Marker at Middle of Polyline
    func distanceLabelForMarker(){
        var polyLinePlaces = places
        if let  first = places.first {
            polyLinePlaces.append(first)
            for i in 0 ..< polyLinePlaces.count {
                let place = polyLinePlaces[i]
                if i >= places.count {
                    return
                }
                let destination: CLLocationCoordinate2D = polyLinePlaces[i + 1]
                let middle = middleLocation(location: place, location2: destination)
                let coordinate1 = CLLocation(latitude: place.latitude, longitude: place.longitude)
                let coordinate2 = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
                let distance = coordinate1.distance(from: coordinate2).description
                self.addAnotation(title: distance, subtitle: nil, coordinate: middle, isMiddle: true)
            }
        }
    }
    
    //MARK:- Get Middle Point for Two Locations
    func middleLocation(location:CLLocationCoordinate2D, location2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lon1 = location2.longitude * Double.pi / 180
        let lon2 = location.longitude * Double.pi / 180
        let lat1 = location2.latitude * Double.pi / 180
        let lat2 = location.latitude * Double.pi / 180
        let dLon = lon2 - lon1
        let x = cos(lat2) * cos(dLon)
        let y = cos(lat2) * sin(dLon)
        
        let lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) )
        let lon3 = lon1 + atan2(y, cos(lat1) + x)
        
        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat3 * 180 / Double.pi, lon3 * 180 / Double.pi)
        return center
    }
    
    //MARK: Zoom Out Map
    @IBAction func zoomOutBtnAxn(_ sender: Any) {
        //Zoom Out
        var region: MKCoordinateRegion = map.region
        region.span.latitudeDelta = min(region.span.latitudeDelta * 2.0, 180.0)
        region.span.longitudeDelta = min(region.span.longitudeDelta * 2.0, 180.0)
        map.setRegion(region, animated: true)
    }
    
    //MARK: Zoom In Map
    @IBAction func zoomInBtnAxn(_ sender: Any) {
        //Zoom In
        var region: MKCoordinateRegion = map.region
        region.span.latitudeDelta /= 2.0
        region.span.longitudeDelta /= 2.0
        map.setRegion(region, animated: true)
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    //MARK: - ViewFor Annotation Method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        // Check and Return View for Distance Annotation
        if let title = annotation.title as? String, let intTitle = Double(title){
            let annotationView = DistanceAnnotationView(annotation: annotation, reuseIdentifier: "distance")
            annotationView.distance = Int(intTitle)
            return annotationView
        }
        
        switch annotation.title {
        case "my location":
            
            //Marker view for my location
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            annotationView.markerTintColor = UIColor.blue
            return annotationView
        case "A", "B", "C":
            
            //marker view for A,B, C
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            
            // add detail call out to show distance
            annotationView.canShowCallout = true
            let detailLabel = UILabel()
            detailLabel.text = self.getDistance(title: (annotation.title ?? "") ?? "")
            annotationView.detailCalloutAccessoryView = detailLabel
            return annotationView
        default:
            return nil
        }
    }
    
    //MARK: - Rendrer for Overlay Func
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            
            //Render Polyline
            let rendrer = MKPolylineRenderer(overlay: overlay)
            if overlay.title == "Draw Markers"{
                self.distanceLabelForMarker()
            }
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 3
            return rendrer
        } else if overlay is MKPolygon {
            //render polygon
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            return rendrer
        }
        return MKOverlayRenderer()
    }
    
}

extension ViewController: CLLocationManagerDelegate{
    
    //MARK: - didupdatelocation Method
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        removePin()
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        displayLocation(latitude: latitude, longitude: longitude, title: "my location", subtitle: "you are here")
    }
}
