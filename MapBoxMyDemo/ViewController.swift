//
//  ViewController.swift
//  MapBoxMyDemo
//
//  Created by think360 on 07/10/17.
//  Copyright © 2017 Think360Solutions. All rights reserved.
//

import UIKit
import Mapbox
import CoreLocation

//MARK: Poly Line Animated
class ViewController: UIViewController, MGLMapViewDelegate {
    var mapView: MGLMapView!
    var timer: Timer?
    var polylineSource: MGLShapeSource?
    var currentIndex = 1
    var allCoordinates: [CLLocationCoordinate2D]!
    var mycord = CLLocationCoordinate2D()
    
    var latAry = NSMutableArray()
    var longAry = NSMutableArray()
    
    
     var coordsArray: [CLLocationCoordinate2D] = []
    
    
    @IBOutlet weak var pathbutton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.setCenter(
            CLLocationCoordinate2D(latitude: 30.6983052, longitude: 76.6273398),
            zoomLevel: 9,
            animated: false)
        view.addSubview(mapView)
        mapView.delegate = self
        
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: 30.6983052, longitude: 76.6273398)
        hello.title = "Think 360 Solutions"
        hello.subtitle = "The Mobile App Dev Company"
        mapView.addAnnotation(hello)
        
        mapView.addSubview(pathbutton)
        
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let url = URL(string: "http://maps.googleapis.com/maps/api/directions/json?origin=\("30.6983052"),\("76.6273398")&destination=\("30.7006476"),\("76.6760144")&sensor=true&mode=driving")!
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }else{
                do {
            if let json : [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                        
        //print("json \(json)")
        if json["status"] as? String == "OK"{
            
                if let routes = json["routes"] as? [Any] {
                if let route = routes[0] as? [String:Any] {
                if let legs = route["legs"] as? [Any] {
                                    
                let dic :NSDictionary = legs[0] as! NSDictionary
                let steps:NSArray = dic.value(forKey: "steps") as! NSArray
                    
               for i in 0..<steps.count{
                                        
                let lat  = ((steps.object(at: i) as! NSDictionary).value(forKey: "end_location") as! NSDictionary).value(forKey: "lat") as! NSNumber
                let long  = ((steps.object(at: i) as! NSDictionary).value(forKey: "end_location") as! NSDictionary).value(forKey: "lng") as! NSNumber
                
                self.latAry.add(lat)
                self.longAry.add(long)
                                        
                 }
                   
             for i in 0..<self.latAry.count{
                
                let ld:Double = Double(self.latAry.object(at: i) as! NSNumber)
                let lnd:Double = Double(self.longAry.object(at: i) as! NSNumber)
                                        
                 self.mycord = CLLocationCoordinate2DMake(ld,lnd)
                 self.coordsArray.append(CLLocationCoordinate2DMake(ld,lnd))
                
             }
                  
                   }
                 }
              }
             }else{
                    print("Rout not found")
                 }
            }
             }catch{
                    print("error in JSONSerialization")
                    }
            }
        })
        task.resume()
    }
    
    // Wait until the map is loaded before adding to the map.
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addLayer(to: style)
        
//        let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 2500, pitch: 25, heading: 360)
//        
//        // Animate the camera movement over 5 seconds.
//        mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        
    }
    
        // Allow callout view to appear when an annotation is tapped.
        func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
            return true
        }
    @IBAction func pathButtonAction(_ sender: Any) {
        animatePolyline()
        
        let vancouver = CLLocationCoordinate2D(latitude: 30.6983052, longitude: 76.6273398)
        let calgary = CLLocationCoordinate2D(latitude:30.7006476,longitude: 76.6760144)
       
        
        let visibleCoordinateBounds = MGLCoordinateBoundsMake(vancouver, calgary)
        
        let camera = mapView.cameraThatFitsCoordinateBounds(visibleCoordinateBounds, edgePadding: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
        mapView.camera = camera
        
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: 30.7006476, longitude: 76.6760144)
        hello.title = "Mohali"
        hello.subtitle = ""
        mapView.addAnnotation(hello)
    }
    
    func addLayer(to style: MGLStyle) {
        // Add an empty MGLShapeSource, we’ll keep a reference to this and add points to this later.
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source
        
        // Add a layer to style our polyline.
        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
        layer.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        layer.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        layer.lineColor = MGLStyleValue(rawValue: UIColor.red)
        layer.lineWidth = MGLStyleFunction(interpolationMode: .exponential,
                                           cameraStops: [14: MGLConstantStyleValue<NSNumber>(rawValue: 5),
                                                         18: MGLConstantStyleValue<NSNumber>(rawValue: 20)],
                                           options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        style.addLayer(layer)
    }
    
    func animatePolyline() {
        currentIndex = 1
        
        // Start a timer that will simulate adding points to our polyline. This could also represent coordinates being added to our polyline from another source, such as a CLLocationManagerDelegate.
        timer = Timer.scheduledTimer(timeInterval: 0.08, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    
    @objc func tick() {
        if currentIndex > self.coordsArray.count {
            timer?.invalidate()
            timer = nil
            return
        }
        
        // Create a subarray of locations up to the current index.
        let coordinates = Array(self.coordsArray[0..<currentIndex])
        
        // Update our MGLShapeSource with the current locations.
        updatePolylineWithCoordinates(coordinates: coordinates)
        
        currentIndex += 1
    }
    
    func updatePolylineWithCoordinates(coordinates: [CLLocationCoordinate2D]) {
        var mutableCoordinates = coordinates
        
        let polyline = MGLPolylineFeature(coordinates: &mutableCoordinates, count: UInt(mutableCoordinates.count))
        
        // Updating the MGLShapeSource’s shape will have the map redraw our polyline with the current coordinates.
        polylineSource?.shape = polyline
    }
    
    
}

//MARK: 1
//class ViewController: UIViewController,MGLMapViewDelegate {
//
//    override func viewDidLoad() {
//        
//        super.viewDidLoad()
//        
////        let mapView = MGLMapView(frame: view.bounds)
////        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
////        
////        // Set the map’s center coordinate and zoom level.
////        mapView.setCenter(CLLocationCoordinate2D(latitude: 40.7326808, longitude: -73.9843407), zoomLevel: 5, animated: false)
////        view.addSubview(mapView)
////        
////        // Set the delegate property of our map view to `self` after instantiating it.
////        mapView.delegate = self
//        
//        
//        
////        let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 4500, pitch: 5, heading: 180)
////        
////        // Animate the camera movement over 5 seconds.
////        mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
//        
//        
//        
//        let mapView = MGLMapView(frame: view.bounds)
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        mapView.delegate = self
//        
//        mapView.styleURL = MGLStyle.outdoorsStyleURL();
//        
//        // Mauna Kea, Hawaii
//        let center = CLLocationCoordinate2D(latitude: 30.7363168, longitude: 76.7375199)
//        
//        // Optionally set a starting point.
//        mapView.setCenter(center, zoomLevel: 7, direction: 0, animated: false)
//        
//        view.addSubview(mapView)
//        
//        
//        // Declare the marker `hello` and set its coordinates, title, and subtitle.
//        let hello = MGLPointAnnotation()
//        hello.coordinate = CLLocationCoordinate2D(latitude: 30.7363168, longitude: 76.7375199)
//        hello.title = "Think 360 Solutions"
//        hello.subtitle = "The Mobile App Dev Company"
//        
//        // Add marker `hello` to the map.
//        mapView.addAnnotation(hello)
//        
//        
//        
//    }
//    
//    // Use the default marker. See also: our view annotation or custom marker examples.
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        return nil
//    }
//    
//    // Allow callout view to appear when an annotation is tapped.
//    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
//        return true
//    }
//    
//    
//    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
//        // Wait for the map to load before initiating the first camera movement.
//        
//        // Create a camera that rotates around the same center point, rotating 180°.
//        // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.
//        let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 4500, pitch: 15, heading: 180)
//        
//        // Animate the camera movement over 5 seconds.
//        mapView.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
//    }
//    
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//
//
//}



//MARK: 3
//class ViewController: UIViewController, MGLMapViewDelegate {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let mapView = MGLMapView(frame: view.bounds)
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        mapView.styleURL = MGLStyle.darkStyleURL()
//        mapView.tintColor = .lightGray
//        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 66)
//        mapView.zoomLevel = 2
//        mapView.delegate = self
//        view.addSubview(mapView)
//        
//        // Specify coordinates for our annotations.
//        let coordinates = [
//            CLLocationCoordinate2D(latitude: 0, longitude: 33),
//            CLLocationCoordinate2D(latitude: 0, longitude: 66),
//            CLLocationCoordinate2D(latitude: 0, longitude: 99),
//            ]
//        
//        // Fill an array with point annotations and add it to the map.
//        var pointAnnotations = [MGLPointAnnotation]()
//        for coordinate in coordinates {
//            let point = MGLPointAnnotation()
//            point.coordinate = coordinate
//            point.title = "\(coordinate.latitude), \(coordinate.longitude)"
//            pointAnnotations.append(point)
//        }
//        
//        mapView.addAnnotations(pointAnnotations)
//    }
//    

//    
//    // This delegate method is where you tell the map to load a view for a specific annotation. To load a static MGLAnnotationImage, you would use `-mapView:imageForAnnotation:`.
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        // This example is only concerned with point annotations.
//        guard annotation is MGLPointAnnotation else {
//            return nil
//        }
//        
//        // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
//        let reuseIdentifier = "\(annotation.coordinate.longitude)"
//        
//        // For better performance, always try to reuse existing annotations.
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
//        
//        // If there’s no reusable annotation view available, initialize a new one.
//        if annotationView == nil {
//            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
//            annotationView!.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//            
//            // Set the annotation view’s background color to a value determined by its longitude.
//            let hue = CGFloat(annotation.coordinate.longitude) / 100
//            annotationView!.backgroundColor = UIColor(hue: hue, saturation: 0.5, brightness: 1, alpha: 1)
//        }
//        
//        return annotationView
//    }
//    
//    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
//        return true
//    }
//}


//Mark: Single Marker:
// MGLAnnotationView subclass
//class CustomAnnotationView: MGLAnnotationView {
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        // Force the annotation view to maintain a constant size when the map is tilted.
//        scalesWithViewingDistance = false
//        
//        // Use CALayer’s corner radius to turn this view into a circle.
//        layer.cornerRadius = frame.width / 2
//        layer.borderWidth = 2
//        layer.borderColor = UIColor.white.cgColor
//    }
//    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        
//        // Animate the border width in/out, creating an iris effect.
//        let animation = CABasicAnimation(keyPath: "borderWidth")
//        animation.duration = 0.1
//        layer.borderWidth = selected ? frame.width / 4 : 2
//        layer.add(animation, forKey: "borderWidth")
//    }
//}

//MARK: Multiple Markers :
//class MyCustomPointAnnotation: MGLPointAnnotation {
//    var willUseImage: Bool = false
//}
// end MGLPointAnnotation subclass

//class ViewController: UIViewController, MGLMapViewDelegate {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Create a new map view using the Mapbox Light style.
//        let mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.lightStyleURL())
//        
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        
//        // Set the map’s center coordinate and zoom level.
//        mapView.setCenter(CLLocationCoordinate2D(latitude: 36.54, longitude: -116.97), zoomLevel: 9, animated: false)
//        view.addSubview(mapView)
//        mapView.delegate = self
//        
//        // Create four new point annotations with specified coordinates and titles.
//        let pointA = MyCustomPointAnnotation()
//        pointA.coordinate = CLLocationCoordinate2D(latitude: 36.4623, longitude: -116.8656)
//        pointA.title = "Stovepipe Wells"
//        pointA.willUseImage = true
//        
//        let pointB = MyCustomPointAnnotation()
//        pointB.coordinate = CLLocationCoordinate2D(latitude: 36.6071, longitude: -117.1458)
//        pointB.title = "Furnace Creek"
//        pointB.willUseImage = true
//        
//        let pointC = MyCustomPointAnnotation()
//        pointC.title = "Zabriskie Point"
//        pointC.coordinate = CLLocationCoordinate2D(latitude: 36.4208, longitude: -116.8101)
//        
//        let pointD = MyCustomPointAnnotation()
//        pointD.title = "Mesquite Flat Sand Dunes"
//        pointD.coordinate = CLLocationCoordinate2D(latitude: 36.6836, longitude: -117.1005)
//        
//        // Fill an array with four point annotations.
//        let myPlaces = [pointA, pointB, pointC, pointD]
//        
//        // Add all annotations to the map all at once, instead of individually.
//        mapView.addAnnotations(myPlaces)
//        
//    }
//    
//    // This delegate method is where you tell the map to load a view for a specific annotation based on the willUseImage property of the custom subclass.
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        
////        if let castAnnotation = annotation as? MyCustomPointAnnotation {
////            if (castAnnotation.willUseImage) {
////                return nil;
////            }
////        }
//        
//        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
//        let reuseIdentifier = "reusableDotView"
//        
//        // For better performance, always try to reuse existing annotations.
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
//        
//        // If there’s no reusable annotation view available, initialize a new one.
//        if annotationView == nil {
//            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
//            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//            annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
//            annotationView?.layer.borderWidth = 4.0
//            annotationView?.layer.borderColor = UIColor.white.cgColor
//            annotationView!.backgroundColor = UIColor(red:0.03, green:0.80, blue:0.69, alpha:1.0)
//        }
//        
//        return annotationView
//    }
//    
//    // This delegate method is where you tell the map to load an image for a specific annotation based on the willUseImage property of the custom subclass.
//    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
//        
//        if let castAnnotation = annotation as? MyCustomPointAnnotation {
//            if (!castAnnotation.willUseImage) {
//                return nil;
//            }
//        }
//        
//        // For better performance, always try to reuse existing annotations.
//        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "camera")
//        
//        // If there is no reusable annotation image available, initialize a new one.
//        if(annotationImage == nil) {
//            annotationImage = MGLAnnotationImage(image: UIImage(named: "camera")!, reuseIdentifier: "camera")
//        }
//        
//        return annotationImage
//    }
//    
//    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
//        // Always allow callouts to popup when annotations are tapped.
//        return true
//    }
//    
//}


//MARK: Change Light:
//class ViewController: UIViewController, MGLMapViewDelegate {
//    
//    var mapView : MGLMapView!
//    var light : MGLLight!
//    var slider : UISlider!
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Set the map style to Mapbox Streets Style version 9. The map's source will be queried later in this example.
//        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.streetsStyleURL(withVersion: 9))
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        mapView.delegate = self
//        
//        // Center the map on the Flatiron Building in New York, NY.
//        mapView.camera = MGLMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 40.7411, longitude: -73.9897), fromDistance: 600, pitch: 45, heading: 200)
//        
//        view.addSubview(mapView)
//        
//        addSlider()
//    }
//    
//    // Add a slider to the map view. This will be used to adjust the map's light object.
//    func addSlider() {
//        slider = UISlider(frame: CGRect(x: view.frame.width / 8, y: view.frame.height - 60, width: view.frame.width * 0.75, height: 20))
//        slider.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
//        slider.minimumValue = -180
//        slider.maximumValue = 180
//        slider.value = 0
//        slider.addTarget(self, action: #selector(shiftLight), for: .valueChanged)
//        view.addSubview(slider)
//    }
//    
//    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
//        
//        // Add a MGLFillExtrusionStyleLayer.
//        addFillExtrusionLayer(style: style)
//        
//        // Create an MGLLight object.
//        light = MGLLight()
//        
//        // Create an MGLSphericalPosition and set the radial, azimuthal, and polar values.
//        // Radial : Distance from the center of the base of an object to its light. Takes a CGFloat.
//        // Azimuthal : Position of the light relative to its anchor. Takes a CLLocationDirection.
//        // Polar : The height of the light. Takes a CLLocationDirection.
//        let position = MGLSphericalPositionMake(5, 180, 80)
//        light.position = MGLStyleValue<NSValue>(rawValue: NSValue(mglSphericalPosition: position))
//        
//        // Set the light anchor to the map and add the light object to the map view's style. The light anchor can be the viewport (or rotates with the viewport) or the map (rotates with the map). To make the viewport the anchor, replace `MGLLightAnchor.map` with `MGLLightAnchor.viewport`.
//        light.anchor = MGLStyleValue(rawValue: NSValue(mglLightAnchor: MGLLightAnchor.map))
//        style.light = light
//    }
//    
//    @objc func shiftLight() {
//        
//        // Use the slider's value to change the light's polar value.
//        let position = MGLSphericalPositionMake(5, 180, CLLocationDirection(slider.value))
//        light.position = MGLStyleValue<NSValue>(rawValue: NSValue(mglSphericalPosition: position))
//        mapView.style?.light = light
//    }
//    
//    func addFillExtrusionLayer(style: MGLStyle) {
//        // Access the Mapbox Streets source and use it to create a `MGLFillExtrusionStyleLayer`. The source identifier is `composite`. Use the `sources` property on a style to verify source identifiers.
//        let source = style.source(withIdentifier: "composite")!
//        let layer = MGLFillExtrusionStyleLayer(identifier: "extrusion-layer", source: source)
//        layer.sourceLayerIdentifier = "building"
//        layer.fillExtrusionBase = MGLStyleValue(interpolationMode: .identity, sourceStops: nil, attributeName: "min_height", options: nil)
//        layer.fillExtrusionHeight = MGLStyleValue(interpolationMode: .identity, sourceStops: nil, attributeName: "height", options: nil)
//        layer.fillExtrusionOpacity = MGLStyleValue(rawValue: 0.75)
//        layer.fillExtrusionColor = MGLStyleValue(rawValue: .white)
//        
//        // Access the map's layer with the identifier "poi-scalerank3" and insert the fill extrusion layer below it.
//        let symbolLayer = style.layer(withIdentifier: "poi-scalerank3")!
//        style.insertLayer(layer, below: symbolLayer)
//    }
//}

//Mark: Select a layer:
//class ViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate {
//    
//    var mapView : MGLMapView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        mapView = MGLMapView(frame: view.bounds)
//        mapView.delegate = self
//        mapView.setCenter(CLLocationCoordinate2D(latitude:39.23225, longitude:-97.91015), animated: true)
//        mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
//        view.addSubview(mapView)
//        
//        // Add a tap gesture recognizer to the map view.
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
//        gesture.delegate = self
//        mapView.addGestureRecognizer(gesture)
//    }
//    
//    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
//        
//        // Load a tileset containing U.S. states and their population density. For more information about working with tilesets, see: https://www.mapbox.com/help/studio-manual-tilesets/
//        let url = URL(string: "mapbox://examples.69ytlgls")!
//        let source = MGLVectorSource(identifier: "state-source", configurationURL: url)
//        style.addSource(source)
//        
//        let layer = MGLFillStyleLayer(identifier: "state-layer", source: source)
//        
//        // Access the tileset layer.
//        layer.sourceLayerIdentifier = "stateData_2-dx853g"
//        
//        // Create a stops dictionary. This defines the relationship between population density and a UIColor.
//        let stops = [0: MGLStyleValue(rawValue: UIColor.yellow),
//                     600: MGLStyleValue(rawValue: UIColor.red),
//                     1200: MGLStyleValue(rawValue: UIColor.blue)]
//        
//        // Style the fill color using the stops dictionary, exponential interpolation mode, and the feature attribute name.
//        layer.fillColor = MGLStyleValue(interpolationMode: .exponential, sourceStops: stops, attributeName: "density", options: [.defaultValue: MGLStyleValue(rawValue: UIColor.white)])
//        
//        // Insert the new layer below the Mapbox Streets layer that contains state border lines. See the layer reference for more information about layer names: https://www.mapbox.com/vector-tiles/mapbox-streets-v7/
//        let symbolLayer = style.layer(withIdentifier: "admin-3-4-boundaries")
//        style.insertLayer(layer, below: symbolLayer!)
//    }
//    
//    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
//        
//        // Get the CGPoint where the user tapped.
//        let spot = gesture.location(in: mapView)
//        
//        // Access the features at that point within the state layer.
//        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(["state-layer"]))
//        
//        // Get the name of the selected state.
//        if let feature = features.first, let state = feature.attribute(forKey: "name") as? String{
//            changeOpacity(name: state)
//        } else {
//            changeOpacity(name: "")
//        }
//    }
//    
//    func changeOpacity(name: String) {
//        let layer = mapView.style?.layer(withIdentifier: "state-layer") as! MGLFillStyleLayer
//        
//        // Check if a state was selected, then change the opacity of the states that were not selected.
//        if name.characters.count > 0 {
//            layer.fillOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [name: MGLStyleValue<NSNumber>(rawValue: 1)], attributeName: "name", options: [.defaultValue: MGLStyleValue<NSNumber>(rawValue: 0)])
//        } else {
//            // Reset the opacity for all states if the user did not tap on a state.
//            layer.fillOpacity = MGLStyleValue(rawValue: 1)
//        }
//    }
//}


//MARK: PolyLine:
//class ViewController: UIViewController, MGLMapViewDelegate {
//    var mapView: MGLMapView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        mapView = MGLMapView(frame: view.bounds)
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        mapView.setCenter(CLLocationCoordinate2D(latitude: 45.5076, longitude: -122.6736),
//                          zoomLevel: 11, animated: false)
//        view.addSubview(self.mapView)
//
//        mapView.delegate = self
//
//        drawPolyline()
//    }
//
//    func drawPolyline() {
//        // Parsing GeoJSON can be CPU intensive, do it on a background thread
//
//        DispatchQueue.global(qos: .background).async(execute: {
//            // Get the path for example.geojson in the app's bundle
//            let jsonPath = Bundle.main.path(forResource: "example", ofType: "geojson")
//            let url = URL(fileURLWithPath: jsonPath!)
//            print(url)
//
//            do {
//                // Convert the file contents to a shape collection feature object
//                let data = try Data(contentsOf: url)
//                let shapeCollectionFeature = try MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLShapeCollectionFeature
//
//                if let polyline = shapeCollectionFeature.shapes.first as? MGLPolylineFeature {
//                    // Optionally set the title of the polyline, which can be used for:
//                    //  - Callout view
//                    //  - Object identification
//                    polyline.title = polyline.attributes["name"] as? String
//
//                    // Add the annotation on the main thread
//                    DispatchQueue.main.async(execute: {
//                        // Unowned reference to self to prevent retain cycle
//                        [unowned self] in
//                        self.mapView.addAnnotation(polyline)
//                    })
//                }
//            }
//            catch {
//                print("GeoJSON parsing failed")
//            }
//
//        })
//
//    }
//
//    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
//        // Set the alpha for all shape annotations to 1 (full opacity)
//        return 1
//    }
//
//    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
//        // Set the line width for polyline annotations
//        return 2.0
//    }
//
//    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
//        // Give our polyline a unique color by checking for its `title` property
//        if (annotation.title == "Crema to Council Crest" && annotation is MGLPolyline) {
//            // Mapbox cyan
//            return UIColor(red: 59/255, green:178/255, blue:208/255, alpha:1)
//        }
//        else
//        {
//            return .red
//        }
//    }
//}

//MARK: PolyLine Style:
//class ViewController: UIViewController, MGLMapViewDelegate {
//    var mapView: MGLMapView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        mapView = MGLMapView(frame: view.bounds)
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        mapView.setCenter(
//            CLLocationCoordinate2D(latitude: 45.5076, longitude: -122.6736),
//            zoomLevel: 11,
//            animated: false)
//        view.addSubview(mapView)
//
//        mapView.delegate = self
//    }
//
//    // Wait until the map is loaded before adding to the map.
//    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
//        loadGeoJson()
//    }
//
//    func loadGeoJson() {
//        DispatchQueue.global().async {
//            // Get the path for example.geojson in the app’s bundle.
//            guard let jsonUrl = Bundle.main.url(forResource: "example", withExtension: "geojson") else { return }
//            guard let jsonData = try? Data(contentsOf: jsonUrl) else { return }
//            print(jsonData)
//            DispatchQueue.main.async {
//                self.drawPolyline(geoJson: jsonData)
//            }
//        }
//    }
//
//    func drawPolyline(geoJson: Data) {
//        // Add our GeoJSON data to the map as an MGLGeoJSONSource.
//        // We can then reference this data from an MGLStyleLayer.
//
//        // MGLMapView.style is optional, so you must guard against it not being set.
//        guard let style = self.mapView.style else { return }
//
//        let shapeFromGeoJSON = try! MGLShape(data: geoJson, encoding: String.Encoding.utf8.rawValue)
//        print(shapeFromGeoJSON)
//        let source = MGLShapeSource(identifier: "polyline", shape: shapeFromGeoJSON, options: nil)
//        print(source)
//        style.addSource(source)
//
//        // Create new layer for the line
//        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
//        layer.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
//        layer.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
//        layer.lineColor = MGLStyleValue(rawValue: UIColor.green)
//        // Use a style function to smoothly adjust the line width from 2pt to 20pt between zoom levels 14 and 18. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
//        layer.lineWidth = MGLStyleValue(interpolationMode: .exponential,
//                                        cameraStops: [14: MGLStyleValue<NSNumber>(rawValue: 2),
//                                                      18: MGLStyleValue<NSNumber>(rawValue: 20)],
//                                        options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
//
//        // We can also add a second layer that will draw a stroke around the original line.
//        let casingLayer = MGLLineStyleLayer(identifier: "polyline-case", source: source)
//        // Copy these attributes from the main line layer.
//        casingLayer.lineJoin = layer.lineJoin
//        casingLayer.lineCap = layer.lineCap
//        // Line gap width represents the space before the outline begins, so should match the main line’s line width exactly.
//        casingLayer.lineGapWidth = layer.lineWidth
//        // Stroke color slightly darker than the line color.
//        casingLayer.lineColor = MGLStyleValue(rawValue: UIColor.red)
//        // Use a style function to gradually increase the stroke width between zoom levels 14 and 18.
//        casingLayer.lineWidth = MGLStyleValue(interpolationMode: .exponential,
//                                              cameraStops: [14: MGLStyleValue(rawValue: 2),
//                                                            18: MGLStyleValue(rawValue: 4)],
//                                              options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
//        // Just for fun, let’s add another copy of the line with a dash pattern.
//        let dashedLayer = MGLLineStyleLayer(identifier: "polyline-dash", source: source)
//        dashedLayer.lineJoin = layer.lineJoin
//        dashedLayer.lineCap = layer.lineCap
//        dashedLayer.lineColor = MGLStyleValue(rawValue: .purple)
//        dashedLayer.lineOpacity = MGLStyleValue(rawValue: 1)
//        dashedLayer.lineWidth = layer.lineWidth
//        // Dash pattern in the format [dash, gap, dash, gap, ...]. You’ll want to adjust these values based on the line cap style.
//        dashedLayer.lineDashPattern = MGLStyleValue(rawValue: [0, 1.5])
//
//        style.addLayer(layer)
//        style.addLayer(dashedLayer)
//        style.insertLayer(casingLayer, below: layer)
//    }
//}


//MARK: Dots Map
//class ViewController: UIViewController, MGLMapViewDelegate {
//    var mapView: MGLMapView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        mapView = MGLMapView(frame: view.bounds)
//        mapView.styleURL = MGLStyle.lightStyleURL()
//        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        mapView.tintColor = .darkGray
//
//        mapView.setCenter(
//            CLLocationCoordinate2D(latitude: 37.753574, longitude: -122.447303),
//            zoomLevel: 10,
//            animated: false)
//        view.addSubview(mapView)
//
//        mapView.delegate = self
//    }
//
//    // Wait until the style is loaded before modifying the map style.
//    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
//        addLayer(to: style)
//    }
//
//    func addLayer(to style: MGLStyle) {
//        let source = MGLVectorSource(identifier: "population", configurationURL: URL(string: "mapbox://examples.8fgz4egr")!)
//
//        let ethnicities = [
//            "White": UIColor(red: 251/255.0, green: 176/255.0, blue: 59/255.0, alpha: 1.0),
//            "Black": UIColor(red: 34/255.0, green: 59/255.0, blue: 83/255.0, alpha: 1.0),
//            "Hispanic": UIColor(red: 229/255.0, green: 94/255.0, blue: 94/255.0, alpha: 1.0),
//            "Asian": UIColor(red: 59/255.0, green: 178/255.0, blue: 208/255.0, alpha: 1.0),
//            "Other": UIColor(red: 204/255.0, green: 204/255.0, blue: 204/255.0, alpha: 1.0),
//            ]
//
//        style.addSource(source)
//
//        // Create a new layer for each ethnicity/circle color.
//        for (ethnicity, color) in ethnicities {
//            // Each layer should have a unique identifier.
//            let layer = MGLCircleStyleLayer(identifier: "population-\(ethnicity)", source: source)
//
//            // Specifying the `sourceLayerIdentifier` is required for a vector tile source. This is the json attribute that wraps the data in the source.
//            layer.sourceLayerIdentifier = "sf2010"
//
//            // Use a style function to smoothly adjust the circle radius from 2pt to 180pt between zoom levels 12 and 22. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
//            layer.circleRadius = MGLStyleValue(interpolationMode: .exponential,
//                                               cameraStops: [12: MGLStyleValue(rawValue: 2),
//                                                             22: MGLStyleValue(rawValue: 180)],
//                                               options: [.defaultValue : 1.75])
//
//            layer.circleOpacity = MGLStyleValue(rawValue: 0.7)
//
//            // Set the circle color to match the ethnicity.
//            layer.circleColor = MGLStyleValue(rawValue: color)
//
//            // Use an NSPredicate to filter to just one ethnicity for this layer.
//            layer.predicate = NSPredicate(format: "ethnicity == %@", ethnicity)
//
//            style.addLayer(layer)
//        }
//    }
//}

