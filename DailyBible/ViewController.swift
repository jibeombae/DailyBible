//
//  ViewController.swift
//  DailyBible
//
//  Created by Jibeom Bae on 2020-07-18.
//  Copyright © 2020 Jibeom Bae. All rights reserved.
//

import UIKit
import WebKit
import PDFKit
import UserNotifications


class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var pdfViewTopCons: NSLayoutConstraint!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var ConfirmButton: UIButton!
    @IBOutlet weak var changeTimeLabel: UILabel!
    @IBOutlet weak var findPage: UITextField!
    @IBOutlet weak var pagesLeftCount: UILabel!
    @IBOutlet weak var statsbutton: UIButton!
    
    @IBOutlet private var chartView: MacawChartView!
    
    @IBOutlet weak var pagesReadThisWeekL: UILabel!
    
    var started = false
    var document = PDFDocument()
    var inSettings = false
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    var pagesLeft = 4
    var pagesLeft1 = 4
    var inStats = false
    var pagesReadtd = 0
    
    
    
    static var RSun = UserDefaults.standard.integer(forKey: "sun")
    static var RMon = UserDefaults.standard.integer(forKey: "mon")
    static var RTue = UserDefaults.standard.integer(forKey: "tue")
    static var RWed = UserDefaults.standard.integer(forKey: "wed")
    static var RThu = UserDefaults.standard.integer(forKey: "thu")
    static var RFri = UserDefaults.standard.integer(forKey: "fri")
    static var RSat = UserDefaults.standard.integer(forKey: "sat")
    
    var sun = RSun
    var mon = RMon
    var tue = RTue
    var wed = RWed
    var thu = RThu
    var fri = RFri
    var sat = RSat
    
    var sundays: [Int] = []
    var mondays: [Int] = []
    var tuesdays: [Int] = []
    var wednesdays: [Int] = []
    var thursdays: [Int] = []
    var fridays: [Int] = []
    var saturdays: [Int] = []
    
    let numWeeks = UserDefaults.standard.integer(forKey: "weeks")
    
    var resetSun = UserDefaults.standard.bool(forKey: "rstSun")
    var resetMon = UserDefaults.standard.bool(forKey: "rstMon")
    var resetTue = UserDefaults.standard.bool(forKey: "rstTue")
    var resetWed = UserDefaults.standard.bool(forKey: "rstWed")
    var resetThu = UserDefaults.standard.bool(forKey: "rstThu")
    var resetFri = UserDefaults.standard.bool(forKey: "rstFri")
    var resetSat = UserDefaults.standard.bool(forKey: "rstSat")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        chartView.contentMode = .scaleAspectFit
        
        center.requestAuthorization(options: [.alert, .sound])
            { (granted, error) in
        }

        content.title = "Time to Read!"
        content.body = "Pick up where you left off"
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange(notification:)), name: Notification.Name.PDFViewPageChanged, object: nil)

        for n in 0...numWeeks {
            sundays.append(UserDefaults.standard.integer(forKey: "sun\(n)"))
            mondays.append(UserDefaults.standard.integer(forKey: "mon\(n)"))
            tuesdays.append(UserDefaults.standard.integer(forKey: "tue\(n)"))
            wednesdays.append(UserDefaults.standard.integer(forKey: "wed\(n)"))
            thursdays.append(UserDefaults.standard.integer(forKey: "thu\(n)"))
            fridays.append(UserDefaults.standard.integer(forKey: "fri\(n)"))
            saturdays.append(UserDefaults.standard.integer(forKey: "sat\(n)"))
        }

        setup()
    }
    
    @objc func resetData() {
        print("Data Reset")
        sundays.append(ViewController.RSun)
        mondays.append(ViewController.RMon)
        tuesdays.append(ViewController.RTue)
        wednesdays.append(ViewController.RWed)
        thursdays.append(ViewController.RThu)
        fridays.append(ViewController.RFri)
        saturdays.append(ViewController.RSat)
        
        UserDefaults.standard.set(sundays.count, forKey: "weeks")
        updateWeekArrays()
        resetGraph()
    }
    
    
    @IBAction func settingsClicked(_ sender: Any) {
        if inSettings{
            inSettings = false
            pdfViewTopCons.constant = 40
            timePicker.isHidden = true
            ConfirmButton.isHidden = true
            changeTimeLabel.isHidden = true

            
        }
        else{
            if inStats{
                pdfViewTopCons.constant = 40
                chartView.isHidden = true
                pagesLeftCount.isHidden = true
                pagesReadThisWeekL.isHidden = true
                inStats = false
            }
            inSettings = true
            pdfViewTopCons.constant = 280
            timePicker.isHidden = false
            ConfirmButton.isHidden = false
            changeTimeLabel.isHidden = false

        }
        
    }
    
    @IBAction func pushTimeChanged(_ sender: Any) {
        //timePicker.
    }
    
    
    @IBAction func findPageClicked(_ sender: Any) {
        print(findPage.text ?? "none")
        guard var pageNum = Int(findPage.text!) else { return }
        if pageNum > 127{
            pageNum = 127
        }
        else if pageNum < 1{
            pageNum = 1
        }
        
        guard let targetPage = document.page(at:pageNum - 1) else{return}
        
        pdfView.go(to: targetPage)
        
    }
    
    @IBAction func ConfButtonClicked(_ sender: Any) {
        center.removeAllPendingNotificationRequests()
        let date = timePicker.date
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            
        }
        
        inSettings = false
        pdfViewTopCons.constant = 40
        timePicker.isHidden = true
        ConfirmButton.isHidden = true
        changeTimeLabel.isHidden = true
        
    }
    
    @IBAction func statsButtonClicked(_ sender: Any) {

        if inStats{
            pdfViewTopCons.constant = 40
            chartView.isHidden = true
            pagesLeftCount.isHidden = true
            pagesReadThisWeekL.isHidden = true
            inStats = false
        }
        else{
            if inSettings{
                inSettings = false
                pdfViewTopCons.constant = 40
                timePicker.isHidden = true
                ConfirmButton.isHidden = true
                changeTimeLabel.isHidden = true
            }
            pdfViewTopCons.constant = 410
            chartView.isHidden = false
            pagesLeftCount.isHidden = false
            pagesReadThisWeekL.isHidden = false
            
            redrawGraph()
            
            tSun = ViewController.RSun
            tMon = ViewController.RMon
            tTue = ViewController.RTue
            tWed = ViewController.RWed
            tThu = ViewController.RThu
            tFri = ViewController.RFri
            tSat = ViewController.RSat

            inStats = true
        }
        
        
    }
    
    func redrawGraph(){
        MacawChartView.lastFiveShows = ViewController.createDummyData()
        MacawChartView.adjustedData = MacawChartView.lastFiveShows.map({ $0.pagesRead / MacawChartView.dataDivisor})
        MacawChartView.maxValue = 30
        MacawChartView.playAnimations()
    }
    
    
    func setup() {
        chartView.isHidden = true
        pagesLeftCount.isHidden = true
        timePicker.isHidden = true
        ConfirmButton.isHidden = true
        changeTimeLabel.isHidden = true
        pagesReadThisWeekL.isHidden = true
        
        
        pdfView.autoScales = true
        pdfView.displaysAsBook = true
        view.addSubview(pdfView)
        guard let path = Bundle.main.url(forResource: "bible", withExtension: "pdf") else { return }
        
        document = PDFDocument(url: path)!
        pdfView.document = document

        let pageNum = UserDefaults.standard.integer(forKey: "Key")
        guard let targetPage = document.page(at:pageNum) else{return}
        pdfView.go(to: targetPage)

        pagesLeft = 126 - pageNum
        pagesLeftCount.text = "Pages Left to Read: \(pagesLeft)"

        
        pagesReadtd = pageNum
        
        started = true
    }

    @objc private func handlePageChange(notification: Notification) {

        guard document.page(at: 0) != nil else{return}
        
        let page = pdfView.currentPage

        let thisPage = document.index(for: page!)

        if started{
            UserDefaults.standard.set(thisPage, forKey: "Key")
            pagesLeft = 126 - thisPage

            pagesLeftCount.text = "Pages Left to Read: \(pagesLeft)"
            
            let pagesReadtd1 = thisPage - pagesReadtd

            addNumPagesTd(pagesRead: pagesReadtd1)
            
        }
        
        
    }
    
    private func updateWeekArrays() {
        for i in 0...sundays.count - 1 {
            UserDefaults.standard.set(sundays[i], forKey: "sun\(i)")
            UserDefaults.standard.set(mondays[i], forKey: "mon\(i)")
            UserDefaults.standard.set(tuesdays[i], forKey: "tue\(i)")
            UserDefaults.standard.set(wednesdays[i], forKey: "wed\(i)")
            UserDefaults.standard.set(thursdays[i], forKey: "thu\(i)")
            UserDefaults.standard.set(fridays[i], forKey: "fri\(i)")
            UserDefaults.standard.set(saturdays[i], forKey: "sat\(i)")
        }
    }
    
    private func addNumPagesTd(pagesRead: Int) {
        
        let date = Date()
        guard let today = Calendar.current.dateComponents([.weekday], from: date).weekday else { return }
        if today == 1 {
            resetSat = false
            UserDefaults.standard.set(resetSat, forKey: "rstSat")
            if !resetSun && sun > 0{
                resetData()
                resetSun = true
                UserDefaults.standard.set(resetSun, forKey: "rstSun")
            }
            ViewController.RSun = sun + pagesRead
            if ViewController.RSun < 0{
                ViewController.RSun = 0
            }else if ViewController.RSun > 20{
                ViewController.RSun = 20
            }
            UserDefaults.standard.set(ViewController.RSun, forKey: "sun")
        }else if today == 2{
            resetSun = false
            UserDefaults.standard.set(resetSun, forKey: "rstSun")
            if !resetMon && mon > 0{
                resetData()
                resetMon = true
                UserDefaults.standard.set(resetMon, forKey: "rstMon")
            }
            ViewController.RMon = mon + pagesRead
            if ViewController.RMon < 0{
                ViewController.RMon = 0
            }else if ViewController.RMon > 20{
                ViewController.RMon = 20
            }
            UserDefaults.standard.set(ViewController.RMon, forKey: "mon")
        }else if today == 3{
            resetMon = false
            UserDefaults.standard.set(resetMon, forKey: "rstMon")
            if !resetTue && tue > 0{
                resetData()
                resetTue = true
                UserDefaults.standard.set(resetTue, forKey: "rstTue")
            }
            ViewController.RTue = tue + pagesRead
            if ViewController.RTue < 0{
                ViewController.RTue = 0
            }else if ViewController.RTue > 20{
                ViewController.RTue = 20
            }
            UserDefaults.standard.set(ViewController.RTue, forKey: "tue")
        }else if today == 4{
            resetTue = false
            UserDefaults.standard.set(resetTue, forKey: "rstTue")
            if !resetWed && wed > 0{
                resetData()
                resetWed = true
                UserDefaults.standard.set(resetWed, forKey: "rstWed")
            }
            ViewController.RWed = wed + pagesRead
            if ViewController.RWed < 0{
                ViewController.RWed = 0
            }else if ViewController.RWed > 20{
                ViewController.RWed = 20
            }
            UserDefaults.standard.set(ViewController.RWed, forKey: "wed")
        }else if today == 5{
            resetWed = false
            UserDefaults.standard.set(resetWed, forKey: "rstWed")
            if !resetThu && thu > 0{
                resetData()
                resetThu = true
                UserDefaults.standard.set(resetThu, forKey: "rstThu")
            }
            ViewController.RThu = thu + pagesRead
            if ViewController.RThu < 0{
                ViewController.RThu = 0
            }else if ViewController.RThu > 20{
                ViewController.RThu = 20
            }
            UserDefaults.standard.set(ViewController.RThu, forKey: "thu")
        }else if today == 6{
            resetThu = false
            UserDefaults.standard.set(resetThu, forKey: "rstThu")
            if !resetFri && fri > 0{
                resetData()
                resetFri = true
                UserDefaults.standard.set(resetFri, forKey: "rstFri")
            }
            ViewController.RFri = fri + pagesRead
            if ViewController.RFri < 0{
                ViewController.RFri = 0
            }else if ViewController.RFri > 20{
                ViewController.RFri = 20
            }
            UserDefaults.standard.set(ViewController.RFri, forKey: "fri")
        }else if today == 7{
            resetFri = false
            UserDefaults.standard.set(resetFri, forKey: "rstFri")
            if !resetSat && sat > 0{
                resetData()
                resetSat = true
                UserDefaults.standard.set(resetSat, forKey: "rstSat")
            }
            ViewController.RSat = sat + pagesRead
            if ViewController.RSat < 0{
                ViewController.RSat = 0
            }else if ViewController.RSat > 20{
                ViewController.RSat = 20
            }
            UserDefaults.standard.set(ViewController.RSat, forKey: "sat")
        }
        
    }
    
    private func resetGraph(){
        sun = 0
        mon = 0
        tue = 0
        wed = 0
        thu = 0
        fri = 0
        sat = 0
        ViewController.RSun = 0
        ViewController.RMon = 0
        ViewController.RTue = 0
        ViewController.RWed = 0
        ViewController.RThu = 0
        ViewController.RFri = 0
        ViewController.RSat = 0
        UserDefaults.standard.set(0, forKey: "sun")
        UserDefaults.standard.set(0, forKey: "mon")
        UserDefaults.standard.set(0, forKey: "tue")
        UserDefaults.standard.set(0, forKey: "wed")
        UserDefaults.standard.set(0, forKey: "thu")
        UserDefaults.standard.set(0, forKey: "fri")
        UserDefaults.standard.set(0, forKey: "sat")
    }
    
    static func createDummyData() -> [SwiftNewsVideo] {
        let one = SwiftNewsVideo(date: "Sun", pagesRead: Double(RSun))
        let two = SwiftNewsVideo(date: "Mon", pagesRead: Double(RMon))
        let three = SwiftNewsVideo(date: "Tue", pagesRead: Double(RTue))
        let four = SwiftNewsVideo(date: "Wed", pagesRead: Double(RWed))
        let five = SwiftNewsVideo(date: "Thu", pagesRead: Double(RThu))
        let six = SwiftNewsVideo(date: "Fri", pagesRead: Double(RFri))
        let seven = SwiftNewsVideo(date: "Sat", pagesRead: Double(RSat))
        
        return [one, two, three, four, five, six, seven]
    }
    var swipeCount = 0
    
    var tSun = 0
    var tMon = 0
    var tTue = 0
    var tWed = 0
    var tThu = 0
    var tFri = 0
    var tSat = 0
    
    @IBAction func swipedRight(_ sender: Any) {
        print("right") //go back one week
        
        
        let week = saturdays.count
        if week > swipeCount{
            swipeCount += 1
        }
        print(week,swipeCount)
        if week != 0{
            ViewController.RSun = sundays[week - swipeCount]
            ViewController.RMon = mondays[week - swipeCount]
            ViewController.RTue = tuesdays[week - swipeCount]
            ViewController.RWed = wednesdays[week - swipeCount]
            ViewController.RThu = thursdays[week - swipeCount]
            ViewController.RFri = fridays[week - swipeCount]
            ViewController.RSat = saturdays[week - swipeCount]
            redrawGraph()
        }
        
    }
    @IBAction func swipedLeft(_ sender: Any) {
        let week = saturdays.count
        if swipeCount > 0{
            swipeCount -= 1
        }
        if swipeCount == 0{
            ViewController.RSun = tSun
            ViewController.RMon = tMon
            ViewController.RTue = tTue
            ViewController.RWed = tWed
            ViewController.RThu = tThu
            ViewController.RFri = tFri
            ViewController.RSat = tSat
            redrawGraph()
        }
        if week != 0 && swipeCount != 0{
            ViewController.RSun = sundays[week - swipeCount]
            ViewController.RMon = mondays[week - swipeCount]
            ViewController.RTue = tuesdays[week - swipeCount]
            ViewController.RWed = wednesdays[week - swipeCount]
            ViewController.RThu = thursdays[week - swipeCount]
            ViewController.RFri = fridays[week - swipeCount]
            ViewController.RSat = saturdays[week - swipeCount]
            redrawGraph()
        }
        
    }
    
}


