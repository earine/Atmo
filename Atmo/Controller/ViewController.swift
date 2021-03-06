//
//  ViewController.swift
//  Atmo
//
//  Created by Marina Lunts on 11/2/18.
//  Copyright © 2018 earine. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON


class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let locationManager = CLLocationManager()
    let service = Service()
    let weatherDataModel = Weather()
    let city = City()
    var forecast = [Weather]()
    var dates = generateDates(startDate: Date(), addbyUnit: .day, value: 5)
    let dateFormatter = DateFormatter()
    
    var selectedCity : CityModel!
    var selectedCityCoord: CLLocationCoordinate2D?
    
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var windDirectionLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    @IBOutlet weak var cloudnessLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    
    @IBOutlet weak var thisTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDataByCity()
        
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd MMMM"
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        thisTableView?.dataSource = self
        thisTableView?.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecast.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "forecastViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? forecastViewCell  else {
            fatalError("The dequeued cell is not an instance of forecastViewCell.")
        }
        let stringDate = dateFormatter.string(from: dates[indexPath.row])
        let cellForecast = forecast[indexPath.row]
        if(cellForecast.temperatureMax < cellForecast.temperatureMin) {
            cell.cellMaxTempLabel.text = "\(cellForecast.temperatureMin)°"
            cell.cellMinTempLabel.text = "\(cellForecast.temperatureMax)°"
        } else {
            cell.cellMaxTempLabel.text = "\(cellForecast.temperatureMax)°"
            cell.cellMinTempLabel.text = "\(cellForecast.temperatureMin)°"
        }
        cell.cellCondTempLabel.text = (cellForecast.conditionText).firstUppercased
        cell.cellCondIconImage.image = UIImage(named: cellForecast.weatherIconName)
        cell.cellDateLabel.text = stringDate
        return cell
    }
    
    func getDataByCity() {

        let params : [String : String] = ["lat" : String(selectedCity.lat), "lon" : String(selectedCity.lng), "lang" : "ru", "appid" : APP_ID]
        
        getForecastData(url: FORECAST_URL, parameters: params)
        self.updateUI()
    }
    
    
    func getCoordinateFrom(address: String, completion: @escaping(_ coordinate: CLLocationCoordinate2D?, _ error: Error?) -> () ) {
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            completion(placemarks?.first?.location?.coordinate, error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
//        cityLabel.text = "Локация недоступна"
    }
    
    
    func getForecastData(url: String, parameters: [String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                let forecastJSON : JSON = JSON(response.result.value!)
                self.updateForecastData(json: forecastJSON)
            }
        }
    }
    
    func updateForecastData(json : JSON) {
        for i in 0...4 {
            let weather = Weather()
            let j = 7*(i+1)
            service.getForecastDay(weather: weather, j: j, i: i, json: json)
            forecast.append(weather)
            self.thisTableView.reloadData()
        }
    }
    
    func updateUI() {
        cityLabel.text = selectedCity.cityTitle
        temperatureLabel.text = "\(selectedCity.temp)°"
        weatherIcon.image = UIImage(named: selectedCity.conditionIcon ?? "tornado")
        backgroundImage.image = UIImage(named: selectedCity.conditionBackground ?? "thunderstorm-night-image")
        conditionLabel.text = (selectedCity.conditionText)?.firstUppercased
        windDirectionLabel.text = selectedCity.windDirection
        windSpeedLabel.text = "\(selectedCity.windSpeed) км/ч"
        sunriseLabel.text = selectedCity.sunriseHour
        sunsetLabel.text = selectedCity.sunsetHour
        humidityLabel.text = "\(selectedCity.humidity)%"
        cloudnessLabel.text = "\(selectedCity.cloudness )%"
    }
    
}

