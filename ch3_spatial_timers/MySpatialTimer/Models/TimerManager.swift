import SwiftUI
import Observation
import AudioToolbox

@Observable
class TimerManager {

    var timerModels: [TimerModel] = []
    private var timers: [String: Timer] = [:]

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let key = "timers"

    private let notificationDelegate = ForegroundNotificationDelegate()

    func getTargetTimerModel(id: UUID) -> TimerModel? {
        return timerModels.first { $0.id == id }
    }

    init() {
        UNUserNotificationCenter.current().delegate = self.notificationDelegate
        loadTimerModels()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print("Permission granted: \(granted)")
        }
    }

    func getTargetTimerModel(worldAnchorID: UUID) -> TimerModel? {
        return timerModels.first(where: {
            guard let _worldAnchorID = $0.worldAnchorID else { return false }
            return _worldAnchorID == worldAnchorID
        })
    }

    func clearAllData() {
        timerModels.removeAll()
        saveTimerModels()
        
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }

    func clearData(id: UUID) {
        guard let index = timerModels.firstIndex(where: { $0.id == id }) else { return }
        timerModels.remove(at: index)

        saveTimerModels()
    }

    func loadTimerModels() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                timerModels = try decoder.decode([TimerModel].self, from: data)
            } catch {
                print("Error loading data: \(error)")
            }
        }
    }

    func makeTimerModel() -> TimerModel {
        let timerModel = TimerModel()
        return timerModel
    }

    func saveTimerModels() {
        do {
            let data = try encoder.encode(timerModels)
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.synchronize()
        } catch {
            print("Error saving data: \(error)")
        }
    }

    func addTimerModel(timerModel: TimerModel, isSave: Bool = true) {
        timerModels.append(timerModel)
        if isSave {
            saveTimerModels()
        }
    }

    func updateTimerModel(timerModel: TimerModel) {
        if let index = timerModels.firstIndex(of: timerModel) {
            cancelNotification(id: timerModel.id)
            timerModels[index] = timerModel
        } else {
            timerModels.append(timerModel)
        }
        saveTimerModels()
    }

    func removeTimerModel(timerModel: TimerModel, isSave: Bool = true) {
        guard let index = timerModels.firstIndex(of: timerModel) else { return }
        cancelNotification(id: timerModel.id)
        timerModels.remove(at: index)
        if isSave {
            saveTimerModels()
        }
    }

    // MARK: Playing

    func playTimer(timerModel: TimerModel) {
        guard !timers.keys.contains(timerModel.id.uuidString) else { return }

        if timerModel.isNotificationOn {
            self.sendNotificationRequest(id: timerModel.id, title: "Notification", second: timerModel.duration)
        }

        let step = 1.0 / 60.0
        let timer = Timer.scheduledTimer(withTimeInterval: step, repeats: true, block: { _ in
            guard timerModel.state == .running else { return }

            if (timerModel.duration > 0) {
                timerModel.duration -= step
            } else {
                timerModel.state = .stopped

                self.timers[timerModel.id.uuidString]?.invalidate()
                self.timers.removeValue(forKey: timerModel.id.uuidString)

                if timerModel.isAlarmOn {
                    self.playSound(soundId: timerModel.soundID)
                }
            }
        })
        timers[timerModel.id.uuidString] = timer
    }

    func pauseTimer(timerModel: TimerModel) {
        guard timers.keys.contains(timerModel.id.uuidString) else { return }
        guard let timer = timers[timerModel.id.uuidString] else { return }

        timer.invalidate()
        timerModel.state = .paused
        timers.removeValue(forKey: timerModel.id.uuidString)

        cancelNotification(id: timerModel.id)
    }

    func cancelTimer(timerModel: TimerModel) {
        guard let timer = timers[timerModel.id.uuidString] else { return }

        timer.invalidate()
        timerModel.state = .stopped
        timers.removeValue(forKey: timerModel.id.uuidString)

        cancelNotification(id: timerModel.id)
    }

    // MARK: - Private

    private func playSound(soundId: SystemSoundID) {
        AudioServicesPlaySystemSound(soundId)
    }

    private func sendNotificationRequest(id: UUID, title: String, second: TimeInterval, body: String = "") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultRingtone

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: second, repeats: false)

        let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
