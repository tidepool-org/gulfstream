/*
* Copyright (c) 2015, Tidepool Project
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the associated License, which is identical to the BSD 2-Clause
* License as published by the Open Source Initiative at opensource.org.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the License for more details.
*
* You should have received a copy of the License along with this program; if
* not, you can obtain one from Tidepool Project at tidepool.org.
*/

import UIKit

class ViewController: UIViewController, NSXMLParserDelegate {

    @IBOutlet weak var bgNowLabel: UILabel!
    @IBOutlet weak var bgNowMinutesAgoLabel: UILabel!
    @IBOutlet weak var highTempLabel: UILabel!
    @IBOutlet weak var lowTempLabel: UILabel!
    @IBOutlet weak var weatherDescriptionLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var nInboundLabel: UILabel!
    @IBOutlet weak var sixInboundLabel: UILabel!
    @IBOutlet weak var seventyOneInboundLabel: UILabel!
    @IBOutlet weak var fortyFourInboundLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    var currentRoute: String = String()
    var currentRouteDirection: String = String()
    var currentStopName: String = String()
    var ifDepartureTime: String = String()
    var hasPrintedNextDeparture: Bool = false
    var routesOfInterest = ["N-Judah", "6-Parnassus", "71-Haight Noriega", "44-OShaughnessy"]
    var routeDirectionsOfInterest = ["Inbound to Caltrain via Downtown", "Inbound to Downtown", "Inbound to Downtown", "Inbound to The Richmond District"]
    var stopNamesOfInterest = ["9th Ave and Irving St", "9th Ave and Judah St", "Lincoln Way and 9th Ave", "9th Ave and Lincoln Way"]
    var tableStrings: [String] = ["one", "two", "three", "four"]
    var bgNow: String = "-1"
    var bgNowMinutesAgo: Int = -1
    var weatherDescription: String = String()
    var temp: Int = Int()
    var temp_min: Int = Int()
    var temp_max: Int = Int()
    var i = 0
    var stopNameOfInterestForUrl: String = String()
    var cgmName = "ba-cgm"
    var zipCode = "94122"
    
    func handleLongPress(sender: AnyObject) {
        if sender.state == UIGestureRecognizerState.Began {
            let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            alertController.addAction(UIAlertAction(title: "Change NightScout CGM Name", style: UIAlertActionStyle.Default, handler: changeNightScoutURLAlert))
            alertController.addAction(UIAlertAction(title: "Change Weather ZIP Code", style: UIAlertActionStyle.Default, handler: changeWeatherZipAlert))
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func changeNightScoutURLAlert(alert: UIAlertAction!) {
        let changeURLAlert = UIAlertController(title: "Change NightScout CGM Name", message: "Enter a new NightScout CGM name. For example, 'ba-cgm'.", preferredStyle: .Alert)
        changeURLAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in textField.placeholder = "ba-cgm"})
        let callActionHandler = { (action:UIAlertAction!) -> Void in
            let newCGMName = (changeURLAlert.textFields?.first as! UITextField).text
            if (newCGMName != "") {
                self.cgmName = newCGMName
                self.updateBG()
            } else {
                let invalidURLAlert = UIAlertController(title: "Invalid CGM Name", message: "Please try again with a valid NightScout CGM name.", preferredStyle: .Alert)
                invalidURLAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(invalidURLAlert, animated: true, completion: nil)
            }
        }
        changeURLAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: callActionHandler))
        changeURLAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(changeURLAlert, animated: true, completion: nil)
    }
    
    func changeWeatherZipAlert(alert: UIAlertAction!) {
        let changeZipAlert = UIAlertController(title: "Change Weather ZIP Code", message: "Enter a new zip code for weather data. For example, '94301'.", preferredStyle: .Alert)
        changeZipAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in textField.placeholder = "ZIP Code"})
        let callActionHandler = { (action:UIAlertAction!) -> Void in
            let newZipCode = (changeZipAlert.textFields?.first as! UITextField).text
            if (newZipCode != "") {
                self.zipCode = newZipCode
               self.updateWeather()
            } else {
                let invalidURLAlert = UIAlertController(title: "Invalid ZIP Code", message: "Please try again with a valid ZIP Code.", preferredStyle: .Alert)
                invalidURLAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(invalidURLAlert, animated: true, completion: nil)
            }
        }
        changeZipAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: callActionHandler))
        changeZipAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(changeZipAlert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        self.refresh()
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("refresh"), userInfo: nil, repeats: true)
        
        var gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        
        gesture.minimumPressDuration = 1.0
        
        self.view.addGestureRecognizer(gesture)
    }
    
    func refresh(){
        for index in 0...(stopNamesOfInterest.count - 1) {
            var urlString = "http://services.my511.org/Transit2.0/GetNextDeparturesByStopName.aspx?token=88d72eab-fcf8-4f1b-a9b4-059596f59197&agencyName=SF-MUNI&stopName=\(stopNamesOfInterest[index])"
            var escapedUrl = urlString.stringByReplacingOccurrencesOfString(" ", withString: "%20")
            
            var url = NSURL(string: escapedUrl)
            var xmlParser = NSXMLParser(contentsOfURL: url)
            xmlParser?.delegate = self
            xmlParser?.parse()
            i++
            hasPrintedNextDeparture = false
        }
        i = 0
        
        if (tableStrings[0] != "one") {
            self.nInboundLabel.text = tableStrings[0]
        }
        if (tableStrings[1] != "two") {
            self.sixInboundLabel.text = tableStrings[1]
        }
        if (tableStrings[2] != "three") {
            self.seventyOneInboundLabel.text = tableStrings[2]
        }
        if (tableStrings[3] != "four") {
            self.fortyFourInboundLabel.text = tableStrings[3]
        }
        
        updateBG()
        
        updateWeather()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let date = dateFormatter.stringFromDate(NSDate())
        self.currentTimeLabel.text = date
    }
    
    func updateBG() {
        getBGNow()
        if (self.bgNow != "-1") {
            self.bgNowLabel.text = self.bgNow
            
            if (self.bgNowMinutesAgo >= 15) {
                var myMutableString = NSMutableAttributedString()
                myMutableString = NSMutableAttributedString(string: bgNow, attributes: [NSStrikethroughStyleAttributeName:NSUnderlineStyle.StyleSingle.rawValue])
                
                self.bgNowLabel.attributedText = myMutableString
            } else {
                self.bgNowLabel.text = self.bgNow
            }
        } else {
            self.bgNowLabel.text = " "
        }
        if (bgNowMinutesAgo != -1 && bgNowMinutesAgo != 1) {
            self.bgNowMinutesAgoLabel.text = "\(bgNowMinutesAgo) minutes ago"
        } else if (bgNowMinutesAgo == 1) {
            self.bgNowMinutesAgoLabel.text = "\(bgNowMinutesAgo) minute ago"
        } else {
            self.bgNowMinutesAgoLabel.text = " "
        }
    }
    
    func getBGNow() {
        let urlAsString = "http://" + cgmName + ".azurewebsites.net/pebble"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let jsonQuery = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            if (error != nil) {
                println(error.localizedDescription)
            }
            var err: NSError?
            
            var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSDictionary
            if (err != nil) {
                println("JSON Error \(err!.localizedDescription)")
            }
            
            if let bgs = jsonResult["bgs"] as? NSArray {
                if let bgs2 = bgs[0] as? NSDictionary {
                    if let sgv = bgs2["sgv"] as? NSString {
                        self.bgNow = sgv as String
                    }
                    if let datetime = bgs2["datetime"] as? NSTimeInterval {
                        let date = NSDate(timeIntervalSince1970: (datetime/1000))
                        let currentDate = NSDate()
                        let cal = NSCalendar.currentCalendar()
                        let unit:NSCalendarUnit = NSCalendarUnit.CalendarUnitMinute
                        let components = cal.components(unit, fromDate: date, toDate: currentDate, options: nil)
                        self.bgNowMinutesAgo = components.minute
                    }
                }
            }
        })
        
        jsonQuery.resume()
    }
    
    func updateWeather() {
        getWeather()
        if (self.temp_max != 0) {
            self.highTempLabel.text = String("H: \(self.temp_max)°")
        } else {
            self.highTempLabel.text = " "
        }
        if (self.temp_min != 0) {
            self.lowTempLabel.text = String("L: \(self.temp_min)°")
        } else {
            self.lowTempLabel.text = " "
        }
        if (self.weatherDescription != "") {
            self.weatherDescriptionLabel.text = String(self.weatherDescription)
        } else {
            self.weatherDescriptionLabel.text = " "
        }
        if (self.temp != 0) {
            self.currentTempLabel.text = String("\(self.temp)°")
        } else {
            self.currentTempLabel.text = " "
        }
    }
    
    func getWeather() {
        let weatherURL = "http://api.openweathermap.org/data/2.5/weather?zip=" + zipCode + ",us"
        let url = NSURL(string: weatherURL)!
        let urlSession = NSURLSession.sharedSession()
        
        let jsonQuery = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            if (error != nil) {
                println(error.localizedDescription)
            }
            var err: NSError?
            
            var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSDictionary
            if (err != nil) {
                println("JSON Error \(err!.localizedDescription)")
            }
            
            if let weather = jsonResult["weather"] as? NSArray {
                if let weather2 = weather[0] as? NSDictionary {
                    if let weatherDescription = weather2["main"] as? NSString {
                        self.weatherDescription = weatherDescription as String
                    }
                }
            }
            if let main = jsonResult["main"] as? NSDictionary {
                if let kelvinTemperature = main["temp"] as? Int {
                    let fahrenheitTemperature = self.kelvinToFahrenheiht(kelvinTemperature)
                    self.temp = fahrenheitTemperature
                }
                if let kelvinTemp_Min = main["temp_min"] as? Int {
                    let fahrenheitTemp_Min = self.kelvinToFahrenheiht(kelvinTemp_Min)
                    self.temp_min = fahrenheitTemp_Min
                }
                if let kelvinTemp_Max = main["temp_max"] as? Int {
                    let fahrenheitTemp_Max = self.kelvinToFahrenheiht(kelvinTemp_Max)
                    self.temp_max = fahrenheitTemp_Max
                }
            }
        })
        
        jsonQuery.resume()
    }
    
    func kelvinToFahrenheiht(kel: Int) -> Int {
        return Int(9/5*(kel - 273) + 32)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        if (elementName == "Route") {
            currentRoute = attributeDict["Name"]! as! String
        } else if (elementName == "RouteDirection") {
            currentRouteDirection = attributeDict["Name"]! as! String
        } else if (elementName == "Stop") {
            currentStopName = attributeDict["name"]! as! String
        } else if (elementName == "DepartureTime") {
            ifDepartureTime = elementName
        }
    }
    
    
    func parser(parser: NSXMLParser, foundCharacters characters: String?){
        
        if (ifDepartureTime == "DepartureTime" && currentRoute == routesOfInterest[i] && currentRouteDirection == routeDirectionsOfInterest[i] && currentStopName == stopNamesOfInterest[i] && !hasPrintedNextDeparture && characters != "\n" && characters != "\n\n") {
            tableStrings[i] = "\(currentRoute) (in): \(characters!)"
            hasPrintedNextDeparture = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

