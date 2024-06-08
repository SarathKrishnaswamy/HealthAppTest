import SwiftUI
import HealthKit
import Charts

// Main view that displays health data
struct HealthDataView: View {
    @State private var steps: Double = 0.0
    @State private var distance: Double = 0.0
    @State private var heartRates: [HKQuantitySample] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    private var healthStore = HealthStore()

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Fetching Health Data...")
                    .transition(.opacity)
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .transition(.opacity)
            } else {
                ScrollView {
                    VStack{
                        HStack(spacing: 20) {
                            HealthCard(title: "Steps", value: String(format: "%.0f", steps))
                            HealthCard(title: "Distance", value: String(format: "%.2f km", distance))
                            
                        }
                        .padding()
                        .transition(.slide)
                        LineChartView(data: heartRates.map { $0.quantity.doubleValue(for: .count().unitDivided(by: .minute())) }, title: "Heart Rate", unit: "bpm")
                        TableView(steps: steps, distance: distance, heartRates: heartRates)
                    }
                    .frame(height: 900)
                   
                }
            }
        }
        .onAppear {
            fetchHealthData()
        }
    }

    // Function to fetch health data
    private func fetchHealthData() {
        healthStore.requestAuthorization { success, error in
            if success {
                let group = DispatchGroup()
                // Fetch steps
                group.enter()
                healthStore.fetchSteps { steps, error in
                    if let steps = steps {
                        DispatchQueue.main.async {
                            withAnimation {
                                self.steps = steps
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = error?.localizedDescription
                        }
                    }
                    group.leave()
                }

                // Fetch distance
                group.enter()
                healthStore.fetchDistance { distance, error in
                    if let distance = distance {
                        DispatchQueue.main.async {
                            withAnimation {
                                self.distance = distance
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = error?.localizedDescription
                        }
                    }
                    group.leave()
                }

                // Fetch heart rate
                group.enter()
                healthStore.fetchHeartRate { heartRates, error in
                    if let heartRates = heartRates {
                        DispatchQueue.main.async {
                            withAnimation {
                                self.heartRates = heartRates
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = error?.localizedDescription
                        }
                    }
                    group.leave()
                }

                // Notify when all fetch operations are completed
                group.notify(queue: .main) {
                    withAnimation {
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorMessage = error?.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

// Custom view to display a health data card
struct HealthCard: View {
    var title: String
    var value: String

    @State private var animate = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title)
                .bold()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                animate = true
            }
        }
    }
}

// Custom view to display a line chart of heart rate data
struct LineChartView: View {
    var data: [Double]
    var title: String
    var unit: String

    struct DataPoint: Identifiable {
        var id: Int
        var value: Double
    }

    @State private var animate = false

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Value", data[index])
                    )
                }
            }
            .frame(height: 300)
            .opacity(animate ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    animate = true
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// Custom view to display health data in a table format
struct TableView: View {
    var steps: Double
    var distance: Double
    var heartRates: [HKQuantitySample]

    @State private var animate = false

    var body: some View {
        VStack {
            Text("Health Data Summary")
                .font(.headline)
            GeometryReader { geometry in
                List {
                    Section(header: Text("Steps")) {
                        Text("\(steps)")
                    }
                    Section(header: Text("Distance")) {
                        Text(String(format: "%.2f km", distance))
                    }
                    Section(header: Text("Heart Rate")) {
                        ForEach(heartRates, id: \.uuid) { sample in
                            Text(String(format: "%.0f bpm", sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))))
                        }
                    }
                }
                .frame(height: 900)
                //.frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                animate = true
            }
        }
    }
}
