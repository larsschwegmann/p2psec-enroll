//
//  PingOperation.swift
//  p2p-enroll
//
//  Created by Lars Schwegmann on 25.04.19.
//

import Foundation
import Socket

class PingOperation: Operation {

    var enrollmentManager: EnrollmentManager
    var server: String
    var port: Int32

    init(enrollmentManager: EnrollmentManager, server: String, port: Int32) {
        self.enrollmentManager = enrollmentManager
        self.server = server
        self.port = port
    }

    override func main() {
        let start = Date.timeIntervalSinceReferenceDate
        var socket = enrollmentManager.socket
        while !isCancelled {
            sleep(30)
            let refTime = Date().timeIntervalSinceReferenceDate
            let diffTime = refTime - start
            print("--------------------------------------------------------------------------------------")
            enrollmentManager.attemptSema.wait()
            let hashesPerSec = Double(enrollmentManager.attempts) / diffTime
            print("Total attempts: \(enrollmentManager.attempts), \(hashesPerSec / 1000000) MHash/s")
            enrollmentManager.attemptSema.signal()
            print("--------------------------------------------------------------------------------------")
            do {
                if socket.isConnected {
                    socket.close()
                    socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
                    enrollmentManager.socket = socket
                    print("PING: Reconnecting socket...")
                    try socket.connect(to: server, port: port)
                    print("PING: Connected to \(server):\(port)")
                    // Refetch challenge
                    var enrollInitResponse = Data()
                    let _ = try socket.read(into: &enrollInitResponse)
                    let enrollInitBytes = enrollInitResponse.bytes

                    print("\(enrollInitResponse.count) bytes returned: \(enrollInitResponse.toHexString())")
                    self.enrollmentManager.challenge = Array(enrollInitBytes[4...])
                }
            } catch {
                print("PING: Error: \(error)")
            }
        }
    }

}
