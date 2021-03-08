//
//  TimeClockViewController.swift
//  PORTLR
//
//  Created by puma on 01.05.2020.
//  Copyright © 2020 Ranksol. All rights reserved.
//

import UIKit

class TimeClockViewController: UIViewController {

    
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var endTime: UITextField!
    
    @IBOutlet weak var checkBtn: UIButton!
    @IBOutlet weak var phoneCallBtn: UIButton!
    
    let CHECK_IN_STR = "CHECK-IN"
    let CHECK_OUT_STR = "CHECK-OUT"
    let END_TIME = "End Time"
    
    var myUser:[User]?{didSet{}}
    var autoTime = AutoTimeTrack()
    var checkInOut = CheckInOut()
    
    let endTimePic = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showPhoneCallLoggerBtn()
        
        myUser = User.readUserFromArchive()
        
        setUpUi()
        loadUI()
        showEndTimePicker()
    }
    
    func loadUI() {
        checkInOut.loadObj()
        autoTime.loadObj()
        
        let calendar = Calendar.current
        let date = checkInOut.date!
        
        if calendar.isDateInToday(date) {
            if checkInOut.checkout {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                startTime.text = formatter.string(from: autoTime.startTime)
                
                endTime.text = formatter.string(from: checkInOut.endDate)
                endTime.isUserInteractionEnabled = false
                
                checkBtn.setTitle(CHECK_IN_STR, for: .normal)
                
                return
            }
            
            if checkInOut.checkin {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                startTime.text = formatter.string(from: autoTime.startTime)
                
                endTime.text = END_TIME
                endTime.isUserInteractionEnabled = true
                
                checkBtn.setTitle(CHECK_OUT_STR, for: .normal)
                
                return
            }
        } else {
            autoTime.registerNotifications()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        startTime.text = formatter.string(from: autoTime.startTime)
        
        endTime.text = END_TIME
        endTime.isUserInteractionEnabled = false
        
        checkBtn.setTitle(CHECK_IN_STR, for: .normal)
        
    }
    
    func setUpUi() {
        startTime.layer.borderColor = COLOR_TIME_REG
        startTime.layer.borderWidth = BORDER_WIDTH_TIME_REG
        startTime.layer.cornerRadius = RADIUS_TIME_REG
        
        endTime.layer.borderColor = COLOR_TIME_REG
        endTime.layer.borderWidth = BORDER_WIDTH_TIME_REG
        endTime.layer.cornerRadius = RADIUS_TIME_REG
        
        checkBtn.layer.cornerRadius = RADIUS_TIME_REG
    }
    
    @IBAction func onClickCheck(_ sender: Any) {
        
        let btnTitle = checkBtn.title(for: .normal)
        
        if btnTitle == CHECK_IN_STR {
            
            if checkInOut.checkout {
                AppUtility?.displayAlert(title: NSLocalizedString("alert_app_name", comment: ""), messageText: NSLocalizedString("today_time_already_registered_sucessfully", comment: ""), delegate: self)
                
                return
            }
            
            checkInOut.date = Date()
            checkInOut.checkin = true
            checkInOut.checkout = false
            checkInOut.saveObj()
            // Remove notification
            
            autoTime.removeNotification(status: 1)
            loadUI()
            
        } else {
            if checkInOut.checkout {
                // alert
                
                AppUtility?.displayAlert(title: NSLocalizedString("alert_app_name", comment: ""), messageText: NSLocalizedString("time_already_registered_sucessfully", comment: ""), delegate: self)
                
            } else {
                self.registerTimeAutomatically()
            }
        }
        
    }
    
    func registerTimeAutomatically() {
        
        if endTime.text == END_TIME {
            let alert = UIAlertController(title: "Warning", message: "Please select end time.", preferredStyle: .alert)
                   alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                   self.present(alert, animated: true, completion: nil)
            return
        }
        
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "HH:mm"
        let time1Str = formatter1.string(from: autoTime.startTime!)
        let time2Str = formatter1.string(from: endTimePic.date)
        
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy/MM/dd HH:mm"
        
        let time1 = formatter2.date(from: "2020/01/01 \(time1Str)")!
        let time2 = formatter2.date(from: "2020/01/01 \(time2Str)")!
        

        
        let interval = time2.timeIntervalSince(time1)
        
        if interval <= 0 {
            let alert = UIAlertController(title: "Warning", message: "End Time should be greater than Start Time", preferredStyle: .alert)
                   alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                   self.present(alert, animated: true, completion: nil)
            return
        }
        
        if autoTime.projectID!.isEmpty {
            let alert = UIAlertController(title: "Warning", message: "You didn't select the project. At this time, we can't register the time automatically", preferredStyle: .alert)
                   alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                   self.present(alert, animated: true, completion: nil)
            return
        }
        
        let hour = Int(interval / 3600)
        let minute = Int(interval.truncatingRemainder(dividingBy: 3600) / 60)
        
        let resultStr = "\(hour):\(minute)"
        
        let endAt = self.changeTimeFormatSpe(strTime: self.endTimePic.date)
        let startAt = self.changeTimeFormatSpe(strTime: self.autoTime.startTime)
        let spent = "\(self.changeDateFormat(strDate: Date(), format: "yyyy-MM-dd"))T\(self.changeTimeFormat(strTime: self.autoTime.startTime)).000Z"
        let arrHoursValues = self.getHoursDetail(resultStr: resultStr)
        
        APIHandler.sharedInstance.newSetTimeSheet(timeSheetId: 0, projectID: autoTime.projectID!, taskID: "", userID: self.myUser![0].userId, endedAt: endAt, hours: DateTimeUtils.share.getServerTimeForPost(timeStr: arrHoursValues[0]), roundedHours: DateTimeUtils.share.getServerTimeForPost(timeStr: arrHoursValues[1]), spentAt: spent, startedAt: startAt, notes: "") { (isSuccess, response) in
            if isSuccess {
                let success = response!["success"] as! Bool
                if success{

                    self.timeRegistered()
                    
                    let alert = UIAlertController(title: NSLocalizedString("alert_app_name", comment: ""), message: NSLocalizedString("time_registered_sucessfully", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        
                    }))
                    self.present(alert, animated: true, completion: nil)

                }else{
                    AppUtility?.displayAlert(title: NSLocalizedString("alert_app_name", comment: ""), messageText: NSLocalizedString("error_400", comment: ""), delegate: self)
                }
            }else{
                AppUtility?.displayAlert(title: NSLocalizedString("alert_app_name", comment: ""), messageText: NSLocalizedString("error_400", comment: ""), delegate: self)
            }
        }
        
    }
    
    func timeRegistered() {
        checkInOut.date = Date()
        checkInOut.checkin = true
        checkInOut.checkout = true
        checkInOut.endDate = endTimePic.date
        checkInOut.saveObj()
        autoTime.removeNotification(status: 2)
        loadUI()
    }
    
    @IBAction func onLogout(_ sender: Any) {
        self.myUser = User.readUserFromArchive()
        self.myUser?.remove(at: 0)
        if User.saveUserToArchive(user: self.myUser!){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.isHidden = true
            appDelegate.window!.rootViewController = nav
        }
    }
    
    func changeTimeFormatSpe(strTime: Date) -> String {
        let timeFormatter2 = DateFormatter()
             timeFormatter2.dateFormat = "HH:mm:ss"
             let finalTime = timeFormatter2.string(from: strTime)
        return "\(finalTime).0000000"
    }
    
    func changeDateFormat(strDate:Date ,format:String) -> String{
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = format
        let finalDate = dateFormatter2.string(from: strDate)
        return finalDate
    }
    
    func changeTimeFormat(strTime:Date) -> String{
          let timeFormatter2 = DateFormatter()
          timeFormatter2.dateFormat = "HH:mm:ss"
          let finalTime = timeFormatter2.string(from: strTime)
          return finalTime
      }

    func getHoursDetail(resultStr: String) -> [String]{
        let intervalInt = DateTimeUtils.share.getIntervalTime(timeStr: resultStr)
        if intervalInt == -1 {
            return []
        }
        let interval = Double(intervalInt)
        let hours = Int(interval / 3600)
        let minute = Int(interval.truncatingRemainder(dividingBy: 3600) / 60)
        
        let roundVal = Float(minute)
        var roundedHours = "0"
        if roundVal < 15.0{
            roundedHours = "\(hours).15"
        }
        if roundVal > 15.0 && roundVal < 30.0{
            roundedHours = "\(hours).30"
        }
        if roundVal > 30.0 && roundVal < 45.0{
            roundedHours = "\(hours).45"
        }
        if roundVal > 45.0 && roundVal < 60.0{
            roundedHours = "\(hours + 1).00"
        }
        return [resultStr.replacingOccurrences(of: ":", with: "."),roundedHours]
    }
    
    func showEndTimePicker(){
        //Formate Date
        endTimePic.datePickerMode = .time
        
        //ToolBar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneEndTimePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelEndTimePicker));
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        endTime.inputAccessoryView = toolbar
        endTime.inputView = endTimePic
    }
    
    @objc func doneEndTimePicker(){
        
      updateTime()
        self.view.endEditing(true)
    }
    
    @objc func cancelEndTimePicker(){
        self.view.endEditing(true)
    }
    
    func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        endTime.text = formatter.string(from: endTimePic.date)
        
        let time1 = autoTime.startTime!
        let time2 = endTimePic.date
        
        let interval = time2.timeIntervalSince(time1)
        
        if interval <= 0 {
            let alert = UIAlertController(title: "Warning", message: "End Time should be greater than Start Time", preferredStyle: .alert)
                   alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                   self.present(alert, animated: true, completion: nil)
            return
        }
    
    }
    
    func showPhoneCallLoggerBtn() {
        if AutoTimeTrack().isCheckCallLogger() {
            phoneCallBtn.isHidden = false
        } else {
            phoneCallBtn.isHidden = true
        }
    }
    
}
