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

    private var prevTilt = (x: 0.0, y: 0.0)
    private var prevTilt_g = (x: 0.0, y: 0.0)
    @Published var tiltSummary = ""
    private var tiltHistory: [String] = []
    let collectRate = 1.0 / 40
    let readRate = 1.0 / 60
    
    private var timer : Timer?
//    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("tilt.txt")
    
    init() {
        motionManager.accelerometerUpdateInterval = collectRate
        motionManager.gyroUpdateInterval = collectRate
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
        prevTilt = (x: 0.0, y: 0.0)
        prevTilt_g = (x: 0.0, y: 0.0)
        tiltHistory = []
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
            self.accelDisplay = "Acceleration\nX: \(self.accel.x)\nY: \(self.accel.y)\nZ: \(self.accel.z)"
            accelHistory.append(self.accel)
        }
    }
    
    private func getGyro(motion: CMGyroData?) {
        if let motion = motion {
            self.gyro = motion.rotationRate
            self.gyroDisplay = "Rotation\nX: \(self.gyro.x)\nY: \(self.gyro.y)\nZ: \(self.gyro.z)"
            gyroHistory.append(self.gyro)
        }
    }
    
    func stdev(arr : [Double]) -> Double {
        let length = Double(arr.count)
        print("s1")
        let avg = arr.reduce(0, +) / length
        print("s2")
        let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, +)
        print("s3")
        return sqrt(sumOfSquaredAvgDiff / (length - 1))
    }
    
    func stopDisplay() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        timer?.invalidate()
        print(self.tiltHistory.joined(separator: "\n"))
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
//        self.accelSummary = "Total Acceleration over \(accelHistoryLength) samples\nX: \(x_sum/accelHistoryLength)\nY: \(y_sum/accelHistoryLength)\nZ: \(z_sum/accelHistoryLength)"
        
        let gyroHistoryLength: Double = Double(self.gyroHistory.count)
        print(gyroHistoryLength)
        let gyro_x_mean = self.gyroHistory.map{($0.x / gyroHistoryLength)}.reduce(0, +)
        let gyro_y_mean = self.gyroHistory.map{($0.y / gyroHistoryLength)}.reduce(0, +)
        let gyro_z_mean = self.gyroHistory.map{($0.z / gyroHistoryLength)}.reduce(0, +)
        
        let gyro_x_std = sqrt(self.gyroHistory.map{(pow($0.x - x_mean, 2))}.reduce(0, +) / (gyroHistoryLength-1))
        let gyro_y_std = sqrt(self.gyroHistory.map{(pow($0.y - y_mean, 2))}.reduce(0, +) / (gyroHistoryLength-1))
        let gyro_z_std = sqrt(self.gyroHistory.map{(pow($0.z - z_mean, 2))}.reduce(0, +) / (gyroHistoryLength-1))
        
        self.gyroSummary =  String(format: "Total Acceleration over %.0f samples\nX: %.5f pm %.5f\nY: %.5f pm %.5f\nZ: %.5f pm %.5f", gyroHistoryLength, gyro_x_mean, gyro_x_std, gyro_y_mean, gyro_y_std, gyro_z_mean, gyro_z_std)
    }
    
    func getFullTilt() {
        let alpha = 0.98
        let accel = self.accelHistory.popFirst()
        let gyro = self.gyroHistory.popFirst()
        let deg_const = 180.0 / Double.pi
        if let accel = accel, let gyro = gyro  {
//            let tilt_a = (x: atan2(accel.x, accel.z), y: atan2(-accel.x, sqrt(accel.y*accel.y + accel.z*accel.z)))
            let g = sqrt(accel.x*accel.x + accel.y*accel.y + accel.z*accel.z)
//            let g = -9.81
            let tilt_a = (x: asin(accel.x / g), y: atan(accel.y / accel.z))
            // sqrt(pow(asin(accel.x / g), 2) + pow(atan(accel.y/accel.z), 2))
            let tilt_g = (x: prevTilt.x + (gyro.x * self.collectRate), y: prevTilt.y + (gyro.y * self.collectRate))
            let tilt_g_only = (x: prevTilt_g.x + (gyro.x * self.collectRate), y: prevTilt_g.y + (gyro.y * self.collectRate))
            let tilt = (x: alpha * tilt_g.x + (1-alpha) * tilt_a.x, y: alpha * tilt_g.y + (1-alpha) * tilt_a.y)
            prevTilt = tilt
            prevTilt_g = tilt_g_only
            
            let a_tilt = deg_const * sqrt(tilt_a.x*tilt_a.x + tilt_a.y*tilt_a.y)
            let g_tilt = deg_const * sqrt(tilt_g_only.x*tilt_g_only.x + tilt_g_only.y*tilt_g_only.y)
            let c_tilt = deg_const * sqrt(tilt.x*tilt.x + tilt.y*tilt.y)
            
            self.tiltSummary = String(format: "Tilt\nAcc: %.3f\nGyro: %.3f\nComplementary: %.3f",
                                      a_tilt, g_tilt, c_tilt
//                                      deg_const * tilt_a.x, deg_const * tilt_a.y,
//                                      deg_const * tilt_g_only.x, deg_const * tilt_g_only.y,
//                                      sqrt(tilt_g.x*tilt_g.x + tilt_g.y*tilt_g.y),
//                                      deg_const * tilt_g.x, deg_const * tilt_g.y
            )
            tiltHistory.append(String(format:"%.5f,%.5f,%.5f", a_tilt, g_tilt, c_tilt))
        }
    }
}
