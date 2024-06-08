import HealthKit

class HealthStore {
    var healthStore: HKHealthStore?

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard let healthStore = self.healthStore else { return completion(false, nil) }

        let allTypes = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ])

        healthStore.requestAuthorization(toShare: [], read: allTypes) { success, error in
            completion(success, error)
        }
    }

    func fetchSteps(completion: @escaping (Double?, Error?) -> Void) {
        guard let healthStore = self.healthStore else { return completion(nil, nil) }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                return completion(nil, error)
            }
            completion(sum.doubleValue(for: HKUnit.count()), nil)
        }
        healthStore.execute(query)
    }
    
    func fetchDistance(completion: @escaping (Double?, Error?) -> Void) {
           guard let healthStore = self.healthStore else {
               completion(nil, nil)
               return
           }

           let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
           let now = Date()
           let startOfDay = Calendar.current.startOfDay(for: now)
           let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

           let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
               guard let result = result, let sum = result.sumQuantity() else {
                   completion(nil, error)
                   return
               }
               completion(sum.doubleValue(for: HKUnit.meterUnit(with: .kilo)), nil)
           }
           healthStore.execute(query)
       }

       func fetchHeartRate(completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
           guard let healthStore = self.healthStore else {
               completion(nil, nil)
               return
           }

           let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
           let now = Date()
           let startOfDay = Calendar.current.startOfDay(for: now)
           let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

           let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
               completion(samples as? [HKQuantitySample], error)
           }
           healthStore.execute(query)
       }
}
