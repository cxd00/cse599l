//
//  MotionView.swift
//  cxd599l_a1
//
//  Created by Cynthia on 4/8/25.
//
import SwiftUI
import CoreMotion
import Collections
import Charts

struct TiltData: Identifiable {
    var index: Int
    var pitch: Double
    var roll: Double
    var tilt: Double
    var dataSource: String
    let id = UUID()
    let deg_const = 180.0 / Double.pi
    
    init(dataSource: String, index: Int, pitch: Double, roll: Double) {
        self.dataSource = dataSource
        self.pitch = pitch
        self.index = index
        self.roll = roll
        self.tilt = deg_const * sqrt(pow(roll, 2) + pow(pitch, 2))
    }
}

class MotionView: ObservableObject {
    @Published var accelDisplay: String = ""
    @Published var gyroDisplay: String = ""
    
    private let motionManager = CMMotionManager()
    
    private var accel: CMAcceleration = CMAcceleration()
    private var gyro: CMRotationRate = CMRotationRate()
    
    private var accelHistory: Deque<CMAcceleration> = []
    private var gyroHistory: Deque<CMRotationRate> = []
    @Published var accelSummary = ""
    @Published var gyroSummary = ""

    private var prevTilt = TiltData(dataSource: "comp", index: 0, pitch: 0.0, roll: 0.0)
    private var prevTilt_g = TiltData(dataSource: "gyro", index: 0, pitch: 0.0, roll: 0.0)
    private var prevTilt_a = TiltData(dataSource: "accel", index: 0, pitch: 0.0, roll: 0.0)
    @Published var tiltSummary = ""
    @Published var tiltHistory: [TiltData] = []
    var showChart = false
    let collectRate = 1.0 / 40
    let readRate = 1.0 / 60
    private var historyIndex = 1
    
    let acc_noise = (x: 0.00044, y: 0.00039, z: 0.00076)
    let gyro_noise = (x: 0.00151, y: 0.00131, z: 0.00124)
    let acc_bias = (x: 0.00494, y: 0.00240, z: -0.01363)
    let gyro_bias = (x: 0.00261, y: 0.00742, z: -0.01635)
    
    
    private var timer : Timer?
//    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("tilt.txt")
    
    init() {
        motionManager.accelerometerUpdateInterval = collectRate
        motionManager.gyroUpdateInterval = collectRate
        self.tiltHistory.append(prevTilt)
        self.tiltHistory.append(prevTilt_a)
        self.tiltHistory.append(prevTilt_g)
    }
    
    func startDisplay() {
        fetchSensorData()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: self.readRate, repeats: true) { [weak self] timer in
            self?.getFullTilt()
        }
    }
    
    func clear() {
        self.stopDisplay()
        self.prevTilt = TiltData(dataSource: "comp", index: 0, pitch: 0.0, roll: 0.0)
        self.prevTilt_g = TiltData(dataSource: "gyro", index: 0, pitch: 0.0, roll: 0.0)
        self.prevTilt_a = TiltData(dataSource: "accel", index: 0, pitch: 0.0, roll: 0.0)
        self.tiltHistory = [prevTilt, prevTilt_g, prevTilt_a]
        tiltSummary = ""
        accelSummary = ""
        gyroSummary = ""
        accelDisplay = ""
        gyroDisplay = ""
    }
    
    private func fetchSensorData() {
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                getAcceleration(motion: motion)
            }
        }
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                getGyro(motion: motion)
            }
        }
    }
    
    private func getAcceleration(motion: CMAccelerometerData?) {
        if let motion = motion {
            self.accel = motion.acceleration
//            self.accelDisplay = "Acceleration\nX: \(self.accel.x)\nY: \(self.accel.y)\nZ: \(self.accel.z)"
            self.accelHistory.append(self.accel)
        }
    }
    
    private func getGyro(motion: CMGyroData?) {
        if let motion = motion {
            self.gyro = motion.rotationRate
//            self.gyroDisplay = "Rotation\nX: \(self.gyro.x)\nY: \(self.gyro.y)\nZ: \(self.gyro.z)"
            self.gyroHistory.append(self.gyro)
        }
    }
    
    func stopDisplay() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        self.showChart = true
        timer?.invalidate()
//        print(self.tiltHistory.joined(separator: "\n"))
    }
    
    func getDataSummary() {
        let accelHistoryLength: Double = Double(self.accelHistory.count)
        print(accelHistoryLength)
        let x_mean = self.accelHistory.map{($0.x / accelHistoryLength)}.reduce(0, +)
        let y_mean = self.accelHistory.map{($0.y / accelHistoryLength)}.reduce(0, +)
        let z_mean = self.accelHistory.map{($0.z / accelHistoryLength)}.reduce(0, +)
        
        let x_std = sqrt(self.accelHistory.map{(pow($0.x - x_mean, 2))}.reduce(0, +) / (accelHistoryLength-1))
        let y_std = sqrt(self.accelHistory.map{(pow($0.y - y_mean, 2))}.reduce(0, +) / (accelHistoryLength-1))
        let z_std = sqrt(self.accelHistory.map{(pow($0.z - z_mean, 2))}.reduce(0, +) / (accelHistoryLength-1))
        
        self.accelSummary =  String(format: "Total Acceleration over %.0f samples\nX: %.5f pm %.5f\nY: %.5f pm %.5f\nZ: %.5f pm %.5f", accelHistoryLength, x_mean, x_std, y_mean, y_std, z_mean, z_std)

        
        let gyroHistoryLength: Double = Double(self.gyroHistory.count)
        print(gyroHistoryLength)
        let gyro_x_mean = self.gyroHistory.map{($0.x / gyroHistoryLength)}.reduce(0, +)
        let gyro_y_mean = self.gyroHistory.map{($0.y / gyroHistoryLength)}.reduce(0, +)
        let gyro_z_mean = self.gyroHistory.map{($0.z / gyroHistoryLength)}.reduce(0, +)
        
        let gyro_x_std = sqrt(self.gyroHistory.map{(pow($0.x - gyro_x_mean, 2))}.reduce(0, +) / (gyroHistoryLength-1))
        let gyro_y_std = sqrt(self.gyroHistory.map{(pow($0.y - gyro_y_mean, 2))}.reduce(0, +) / (gyroHistoryLength-1))
        let gyro_z_std = sqrt(self.gyroHistory.map{(pow($0.z - gyro_z_mean, 2))}.reduce(0, +) / (gyroHistoryLength-1))
        
        self.gyroSummary =  String(format: "Total Gyro over %.0f samples\nX: %.5f pm %.5f\nY: %.5f pm %.5f\nZ: %.5f pm %.5f", gyroHistoryLength, gyro_x_mean, gyro_x_std, gyro_y_mean, gyro_y_std, gyro_z_mean, gyro_z_std)
    }
    
    func getFullTilt() {
        let alpha = 0.98
        let accel = self.accelHistory.popFirst()
        let gyro = self.gyroHistory.popFirst()
//        let deg_const = 180 / Double.pi
        if var accel = accel, var gyro = gyro  {
            // denoise
            accel.x = (accel.x - acc_bias.x) // acc_noise.x
            accel.y = (accel.y - acc_bias.y) // acc_noise.y
            accel.z = (accel.z - acc_bias.z) // acc_noise.z
            
            gyro.x = (gyro.x - gyro_bias.x - gyro_noise.x)
            gyro.y = (gyro.y - gyro_bias.y - gyro_noise.y)
            gyro.z = (gyro.z - gyro_bias.z - gyro_noise.z)
            // calculate
            let g = sqrt(accel.x*accel.x + accel.y*accel.y + accel.z*accel.z)
            let tilt_a = TiltData(
                dataSource: "accel", index: self.historyIndex,
                pitch: asin(accel.x / g), roll: atan(accel.y/accel.z)
            )
            let tilt_g_only = TiltData(
                dataSource: "gyro", index: self.historyIndex,
                pitch: prevTilt_g.pitch + (gyro.x * self.collectRate),
                roll: prevTilt_g.roll + (gyro.y * self.collectRate)
            )
            let tilt = TiltData(
                dataSource: "comp", index: self.historyIndex,
                pitch: alpha * (prevTilt.pitch + (gyro.x * self.collectRate)) + (1-alpha) * tilt_a.pitch,
                roll: alpha * (prevTilt.roll + (gyro.y * self.collectRate)) + (1-alpha) * tilt_a.roll
            )
            prevTilt = tilt
            prevTilt_g = tilt_g_only
            self.tiltHistory.append(tilt)
            self.tiltHistory.append(tilt_g_only)
            self.tiltHistory.append(tilt_a)
            self.historyIndex += 1
            if (self.historyIndex % 10 == 0) {
                self.tiltSummary = String(format: "Acc Tilt: %2f\nGyro Tilt:%2f\nFiltered Tilt: %2f", tilt_a.tilt, tilt_g_only.tilt, tilt.tilt)
            }
        }
    }
}
