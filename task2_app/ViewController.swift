//
//  ViewController.swift
//  task2_app
//
//  Created by Ömer Faruk Başaran on 9.09.2023.
//

import UIKit
import UserNotifications
import AVFoundation
import CoreData

class ViewController: UIViewController, UNUserNotificationCenterDelegate {

    var data = [NSManagedObject]()
    var timer = Timer()
    var audioPlayer: AVAudioPlayer?
    var alarmTime : Date?
    var pickedDate : Date?
    @IBOutlet weak var succesLabel: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    @IBOutlet weak var setAlarmButton: UIButton!
    let notificationCenter = UNUserNotificationCenter.current()
    
    override func viewDidAppear(_ animated: Bool) {
        if(chechForAlarmTime()){
            PlayMusic()
        }
        ChechForAlarmState()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        ChechForAlarmState()
        // Do any additional setup after loading the view.
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) {
                    (permissionGranted, error) in
                    if(!permissionGranted)
                    {
                        print("Permission Denied")
                    }
                }

    }

    @IBAction func setAlertClicked(_ sender: Any) {
        if (audioPlayer?.isPlaying == true){
            audioPlayer?.stop()
            setAlarmButton.setTitle("Set Alarm", for: [])
            setAlarmButton.tintColor = .systemBlue
        }
        else{
            print(timePicker.date)
            timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(TimeOver), userInfo: nil, repeats: false)
            succesLabel.isHidden = false
            notificationCenter.getNotificationSettings { (settings) in

                DispatchQueue.main.async
                {
                    let title = "It's Time"
                    let message = "Wake UP!"
                    let date = self.timePicker.date
                    if(settings.authorizationStatus == .authorized)
                    {
                        let content = UNMutableNotificationContent()
                        let identifer = "alarm-identifier"
                        content.title = title
                        content.body = message
                        //content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm.mp3") )
                        content.sound = .criticalSoundNamed(UNNotificationSoundName("alarm.mp3"), withAudioVolume: 0.5)
                        let pickedDate = Calendar.current.dateComponents([.hour, .minute], from: date)
                        //print(self.pickedDate as Any)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: pickedDate, repeats: false)
                        let request = UNNotificationRequest(identifier: identifer, content: content, trigger: trigger)
                        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifer])
                        self.notificationCenter.add(request) { (error) in
                            if(error != nil)
                            {
                                print("Error " + error.debugDescription)
                                return
                            }
                        }
                    }
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    let menagedObjectContext = appDelegate?.persistentContainer.viewContext
                    for items in self.data {
                                menagedObjectContext?.delete(items)
                    }
                    let entity = NSEntityDescription.entity(forEntityName: "Entity", in: menagedObjectContext!)
                    let item = NSManagedObject(entity: entity!, insertInto: menagedObjectContext)

                    
                    item.setValue(date , forKey: "lastAlarm")
                    print("save succes \(String(describing: date))")
                    try? menagedObjectContext?.save()
                }
            }
        }
        
    }
    
    @objc func TimeOver() {
        print("time is over")
        succesLabel.isHidden = true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if(chechForAlarmTime()){
            PlayMusic()
        }
        ChechForAlarmState()
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if(chechForAlarmTime()){
            PlayMusic()
        }
        ChechForAlarmState()
        completionHandler([.sound, .badge, .banner])
    }
    
    func PlayMusic(){
        if let soundPath = Bundle.main.path(forResource: "alarm", ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundPath))
                audioPlayer?.prepareToPlay()
                audioPlayer?.play(atTime: audioPlayer!.deviceCurrentTime + 1)
                print("succes playing")
                audioPlayer?.volume = 0.3 // Başlangıç ses düzeyi
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                    if let player = self.audioPlayer {
                        if player.volume < 1.0 {
                            player.volume += 0.03 // Her saniye sesi artır
                        } else {
                            timer.invalidate() // Ses maksimuma ulaştığında zamanlayıcıyı iptal et
                        }
                    }
                }
            } catch {
                print("Ses çalma hatası: \(error)")
            }
        }
    }
    func ChechForAlarmState(){
        if( audioPlayer?.isPlaying == true){
            setAlarmButton.tintColor = .systemRed
            setAlarmButton.setTitle("Stop Alarm", for: [])

        } else if(audioPlayer?.isPlaying == false){
            setAlarmButton.tintColor = .systemBlue
            setAlarmButton.setTitle("Set Alarm", for: [])
        }
    }
    func fetch(){
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let menagedObjectContext = appDelegate?.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Entity")
            data = try! menagedObjectContext!.fetch(fetchRequest)
            let lastDate = data.first
            alarmTime = lastDate?.value(forKey: "lastAlarm") as? Date
            print(alarmTime as Any)
        }
    func chechForAlarmTime() -> Bool{
        fetch()
        print(alarmTime ?? "no alarm was settled")
        pickedDate = self.timePicker.date
        print("picked date \(String(describing: pickedDate)) and fetched date \(String(describing: alarmTime))")
        let p1 = Calendar.current.dateComponents([.hour,.minute], from: pickedDate!)
        let p2 = Calendar.current.dateComponents([.hour, .minute], from: alarmTime ?? .distantPast)
        print("p1 ve p2 == \(p1)  ----- \(p2) ")
        if p1 == p2 {
            return true
        }
        else {
            return false
        }
    }
}

