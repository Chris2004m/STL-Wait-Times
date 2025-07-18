#!/usr/bin/env swift

import Foundation

// Simple script to test ClockwiseMD API and debug patient count discrepancy

struct ClockwiseMDResponse: Codable {
    let hospitalId: Int
    let hospitalWaits: HospitalWaits
    let appointmentQueues: [AppointmentQueue]?
    
    enum CodingKeys: String, CodingKey {
        case hospitalId = "hospital_id"
        case hospitalWaits = "hospital_waits"
        case appointmentQueues = "appointment_queues"
    }
}

struct HospitalWaits: Codable {
    let nextAvailableVisit: Int?
    let currentWait: String?
    let queueLength: Int?
    let queueTotal: Int?
    
    enum CodingKeys: String, CodingKey {
        case nextAvailableVisit = "next_available_visit"
        case currentWait = "current_wait"
        case queueLength = "queue_length"
        case queueTotal = "queue_total"
    }
}

struct AppointmentQueue: Codable {
    let queueId: Int?
    let queueWaits: QueueWaits?
    
    enum CodingKeys: String, CodingKey {
        case queueId = "queue_id"
        case queueWaits = "queue_waits"
    }
}

struct QueueWaits: Codable {
    let currentWait: Int?
    let currentPatientsInLine: Int?
    let currentWaitRange: String?
    
    enum CodingKeys: String, CodingKey {
        case currentWait = "current_wait"
        case currentPatientsInLine = "current_patients_in_line"
        case currentWaitRange = "current_wait_range"
    }
}

func debugFacility(hospitalId: String) {
    let urlString = "https://api.clockwisemd.com/v1/hospitals/\(hospitalId)/waits"
    guard let url = URL(string: urlString) else {
        print("❌ Invalid URL: \(urlString)")
        return
    }
    
    print("🔍 Testing ClockwiseMD API for hospital \(hospitalId)")
    print("📡 URL: \(urlString)")
    print("⏰ Current time: \(Date())")
    print("")
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        defer {
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
        
        if let error = error {
            print("❌ Network error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            print("❌ No data received")
            return
        }
        
        // Print raw JSON for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON response:")
            print(jsonString)
            print("")
        }
        
        do {
            let response = try JSONDecoder().decode(ClockwiseMDResponse.self, from: data)
            
            print("🏥 Parsed Response Analysis:")
            print("   Hospital ID: \(response.hospitalId)")
            print("")
            
            let hospitalWaits = response.hospitalWaits
            print("📊 Hospital Waits (top-level):")
            print("   currentWait: \(hospitalWaits.currentWait ?? "nil")")
            print("   queueLength: \(hospitalWaits.queueLength ?? 0)") 
            print("   queueTotal: \(hospitalWaits.queueTotal ?? 0)")
            print("   nextAvailableVisit: \(hospitalWaits.nextAvailableVisit ?? 0)")
            print("")
            
            // Calculate patients in line using your app's logic
            var patientsInLine = 0
            var debugSource = "UNKNOWN"
            
            if let appointmentQueues = response.appointmentQueues {
                print("📋 Appointment Queues (\(appointmentQueues.count) queues):")
                debugSource = "appointment_queues"
                
                for (index, queue) in appointmentQueues.enumerated() {
                    print("   Queue \(index + 1):")
                    print("      queueId: \(queue.queueId ?? -1)")
                    
                    if let queueWaits = queue.queueWaits {
                        let queuePatients = queueWaits.currentPatientsInLine ?? 0
                        print("      currentPatientsInLine: \(queuePatients)")
                        print("      currentWait: \(queueWaits.currentWait ?? -1)")
                        print("      currentWaitRange: \(queueWaits.currentWaitRange ?? "nil")")
                        patientsInLine += queuePatients
                    } else {
                        print("      queueWaits: NIL")
                    }
                }
            } else {
                patientsInLine = hospitalWaits.queueLength ?? 0
                debugSource = "hospital_waits.queue_length"
                print("❌ No appointment queues found - using fallback")
            }
            
            print("")
            print("🎯 FINAL RESULTS:")
            print("   Data source: \(debugSource)")
            print("   Calculated patients in line: \(patientsInLine)")
            print("   This should match the website: 0")
            print("")
            
            if patientsInLine != 0 {
                print("⚠️  DISCREPANCY DETECTED!")
                print("   Expected: 0 patients (from website)")
                print("   Calculated: \(patientsInLine) patients")
                print("   Check if:")
                print("   - App has cached old data")
                print("   - App fetched at different time")
                print("   - Parsing logic has bugs")
            } else {
                print("✅ Patient count matches website (0)")
                print("   If your app shows different, check for caching issues")
            }
            
        } catch {
            print("❌ JSON parsing error: \(error)")
        }
    }
    
    task.resume()
    CFRunLoopRun()
}

// Test the specific facility mentioned by user
debugFacility(hospitalId: "13598")
