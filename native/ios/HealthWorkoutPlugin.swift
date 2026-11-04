import Foundation
import Capacitor
import HealthKit

/// Saves finished C1 workouts to Apple Health as "Traditional Strength Training".
/// JS name: HealthWorkout. Methods: isAvailable, requestAuthorization, saveWorkout, deleteWorkout.
/// Each workout is tagged with metadata C1SessionId, so saving again replaces the earlier copy.
@objc(HealthWorkoutPlugin)
public class HealthWorkoutPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "HealthWorkoutPlugin"
    public let jsName = "HealthWorkout"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestAuthorization", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "saveWorkout", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "deleteWorkout", returnType: CAPPluginReturnPromise)
    ]

    private let store = HKHealthStore()
    private static let idKey = "C1SessionId"
    private var energyType: HKQuantityType { HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)! }

    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": HKHealthStore.isHealthDataAvailable()])
    }

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        authorize { ok, err in
            if let err = err { call.reject(err) } else { call.resolve(["canWrite": ok]) }
        }
    }

    /// { id, startDate, endDate (ISO 8601), calories?, title? }
    @objc func saveWorkout(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), !id.isEmpty,
              let start = parse(call.getString("startDate")),
              let end = parse(call.getString("endDate")), end > start else {
            return call.reject("Needs id, startDate and an endDate after startDate")
        }
        let kcal = call.getDouble("calories") ?? 0
        let title = call.getString("title") ?? ""
        authorize { ok, err in
            if let err = err { return call.reject(err) }
            guard ok else {
                return call.reject("Not allowed to save workouts. Turn on Workouts in Health → Sharing → Apps → C1 Workout.")
            }
            self.remove(id: id) { _ in
                self.build(id: id, start: start, end: end, kcal: kcal, title: title) { error in
                    if let error = error { call.reject(error) } else { call.resolve(["saved": true]) }
                }
            }
        }
    }

    /// { id } – removes the workout (and its calories) this app saved for that session.
    @objc func deleteWorkout(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), !id.isEmpty else { return call.reject("Needs id") }
        remove(id: id) { n in call.resolve(["deleted": n]) }
    }

    private func authorize(_ done: @escaping (Bool, String?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { return done(false, "Apple Health isn't available on this device") }
        let share: Set<HKSampleType> = [HKObjectType.workoutType(), energyType]
        store.requestAuthorization(toShare: share, read: nil) { _, error in
            if let error = error { return done(false, error.localizedDescription) }
            done(self.store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized, nil)
        }
    }

    /// Deletes only objects this app saved with the given session id. Needs no read permission.
    private func remove(id: String, _ done: @escaping (Int) -> Void) {
        let pred = HKQuery.predicateForObjects(withMetadataKey: Self.idKey, allowedValues: [id])
        store.deleteObjects(of: HKObjectType.workoutType(), predicate: pred) { _, n, _ in
            self.store.deleteObjects(of: self.energyType, predicate: pred) { _, _, _ in done(n) }
        }
    }

    private func build(id: String, start: Date, end: Date, kcal: Double, title: String, _ done: @escaping (String?) -> Void) {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        var meta: [String: Any] = [Self.idKey: id, HKMetadataKeyIndoorWorkout: true]
        if !title.isEmpty { meta[HKMetadataKeyWorkoutBrandName] = title }
        builder.beginCollection(withStart: start) { ok, error in
            guard ok else { return done(error?.localizedDescription ?? "Couldn't start the workout") }
            let finish = {
                builder.addMetadata(meta) { _, _ in
                    builder.endCollection(withEnd: end) { ok, error in
                        guard ok else { return done(error?.localizedDescription ?? "Couldn't end the workout") }
                        builder.finishWorkout { workout, error in
                            done(workout == nil ? (error?.localizedDescription ?? "Couldn't save the workout") : nil)
                        }
                    }
                }
            }
            guard kcal > 0 else { return finish() }
            let sample = HKQuantitySample(type: self.energyType,
                                          quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                                          start: start, end: end, metadata: [Self.idKey: id])
            builder.add([sample]) { _, _ in finish() }
        }
    }

    private func parse(_ s: String?) -> Date? {
        guard let s = s else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}
