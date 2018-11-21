//
//  ViewController.swift
//  Atmo
//
//  Created by Marina Lunts on 11/2/18.
//  Copyright © 2018 earine. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON
import SwiftMoment

class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let locationManager = CLLocationManager()
    let weatherDataModel = Weather()
    let city = City()
    var forecast = [Weather]()
    var dates = generateDates(startDate: Date(), addbyUnit: .day, value: 5)
    let dateFormatter = DateFormatter()
    
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var windDirectionLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    
  
    @IBOutlet weak var thisTableView: UITableView!
  
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(forecast.count)
        return forecast.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "forecastViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? forecastViewCell  else {
            fatalError("The dequeued cell is not an instance of OrderTableViewCell.")
        }
        let stringDate = dateFormatter.string(from: dates[indexPath.row])
        let cellForecast = forecast[indexPath.row]
        cell.cellMaxTempLabel.text = "\(cellForecast.temperatureMax)°"
        cell.cellMinTempLabel.text = "\(cellForecast.temperatureMin)°"
        cell.cellCondTempLabel.text = (cellForecast.conditionText).firstUppercased
        cell.cellCondIconImage.image = UIImage(named: cellForecast.weatherIconName)
        cell.cellDateLabel.text = stringDate
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd MMMM"
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        thisTableView?.dataSource = self;
        thisTableView?.delegate = self;
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            
            print("longitude = \(location.coordinate.longitude), latitude = \(location.coordinate.latitude)")
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            let params : [String : String] = ["lat" : latitude, "lon" : longitude, "lang" : "ru", "appid" : APP_ID]
            
            city.coordinates = location.coordinate
            city.setTimeZone()
            
            getWeatherData(url: WEATHER_URL, parameters: params)
            getForecastData(url: FORECAST_URL, parameters: params)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Локация недоступна"
    }
    
    
    func getForecastData(url: String, parameters: [String : String]) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                let forecastJSON : JSON = JSON(response.result.value!)
            print(forecastJSON)
                self.updateForecastData(json: forecastJSON)
            }
        }
    }
    
    func getWeatherData(url: String, parameters: [String : String]) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Success")
                
                let weatherJSON : JSON = JSON(response.result.value!)
                
                self.updateWeatherData(json: weatherJSON)
            }
            else {
                self.cityLabel.text = "Погода недоступна"
            }
        }
    }
    
    func updateWeatherData(json : JSON) {
        if let tempResult = json["main"]["temp"].double {
            city.cityName = json["name"].stringValue
            weatherDataModel.temperature =  Int(tempResult - 273.15)
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.conditionText = json["weather"][0]["description"].stringValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            weatherDataModel.backgroundName = weatherDataModel.updateBackground(condition: weatherDataModel.condition)
            weatherDataModel.windSpeed = json["wind"]["speed"].floatValue
            weatherDataModel.windDirection = weatherDataModel.windDirection(degree: (json["wind"]["deg"].floatValue))
            weatherDataModel.hour = weatherDataModel.getCurrentHour()
            print(weatherDataModel.hour)
            weatherDataModel.sunriseHour = weatherDataModel.setHour(timeZone: city.timeZone, interval: (json["sys"]["sunrise"].intValue))
            weatherDataModel.sunsetHour = weatherDataModel.setHour(timeZone: city.timeZone, interval: (json["sys"]["sunset"].intValue))
            
            updateUI()
            
        } else {
            cityLabel.text = "Weather unavailable"
        }
    }
    
    func updateForecastData(json : JSON) {
//        for i in 0...4 {
        if(forecast.count < 6) {
        for i in 0...4 {
            var weather = Weather()
            weather.temperatureMax = Int(json["list"][i]["main"]["temp_max"].double! - 273.15)
            weather.temperatureMin = Int(json["list"][i]["main"]["temp_min"].double! - 273.15)
            weather.conditionText = json["list"][i]["weather"][0]["description"].stringValue
            weather.condition = json["list"][i]["weather"][0]["id"].intValue
            weather.weatherIconName = weather.updateWeatherIcon(condition: weather.condition)
            forecast.append(weather)
            self.thisTableView.reloadData()
        }
        }
    }
    
    func updateUI() {
        cityLabel.text = city.cityName
        temperatureLabel.text = "\(weatherDataModel.temperature)°"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        backgroundImage.image = UIImage(named: weatherDataModel.backgroundName)
        conditionLabel.text = (weatherDataModel.conditionText).firstUppercased
        windDirectionLabel.text = weatherDataModel.windDirection
        windSpeedLabel.text = "\(weatherDataModel.windSpeed) км/ч"
        sunriseLabel.text = "\(weatherDataModel.sunriseHour)"
        sunsetLabel.text = "\(weatherDataModel.sunsetHour)"
        
    }

}
