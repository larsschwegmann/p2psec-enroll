//
//  EnrollmentManager.swift
//  ConsoleKit
//
//  Created by Lars Schwegmann on 25.04.19.
//

import Foundation
import CryptoSwift
import Socket

struct EnrollmentInfo {
    var firstName: String
    var lastName: String
    var email: String
    var projectChoice: Project
    var teamNumber: UInt16
}

struct Message {
    static let ENROLL_INIT = 680
    static let ENROLL_REGISTER = 681
    static let ENROLL_SUCCESS = 682
    static let ENROLL_FAILURE = 683
}

////////////////////////////////////////////////////////////////////////////////////////

class EnrollmentManager {

    var enrollmentInfo: EnrollmentInfo
    var socket: Socket
    var challenge: [UInt8] = Array<UInt8>(repeating: 0, count: MemoryLayout<UInt64>.size)
    var attempts: Int = 0
    var attemptSema = DispatchSemaphore(value: 1)
    var nonce: UInt64 = 0

    init(_ info: EnrollmentInfo) throws {
        self.enrollmentInfo = info
        self.socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
    }

    func enroll() throws {
        if !socket.isConnected {
            print("Connecting socket...")
            try socket.connect(to: server, port: port)
            print("Connected to \(server):\(port)")
            // Refetch challenge
            var enrollInitResponse = Data()
            let _ = try socket.read(into: &enrollInitResponse)
            let enrollInitBytes = enrollInitResponse.bytes

            print("\(enrollInitResponse.count) bytes returned: \(enrollInitResponse.toHexString())")
            self.challenge = Array(enrollInitBytes[4...])
        }

        let sem = DispatchSemaphore(value: 0)

        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        let powOperationCount = coreCount
        let operationQueue = OperationQueue()

        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = coreCount + 1
        
        for i in 1...powOperationCount {
            let nonceStart = (UInt64.max / UInt64(powOperationCount)) * UInt64((i - 1))
            let nonceEnd = i == powOperationCount ? UInt64.max : (UInt64.max / UInt64(powOperationCount)) * UInt64(i) - 1
            let operation = POWOperation(enrollmentInfo: self.enrollmentInfo, enrollmentManager: self, id: i, nonceStart: nonceStart, nonceEnd: nonceEnd)
            operation.completionBlock = {
                sem.signal()
            }
            operationQueue.addOperation(operation)
        }
        operationQueue.addOperation(PingOperation(enrollmentManager: self,
                                                  server: server,
                                                  port: port))

        // Wait for POW operation to find a solution
        sem.wait()
        operationQueue.cancelAllOperations()

        var enrollRegister = EnrollRegister(enrollmentInfo: enrollmentInfo, challenge: self.challenge)
        enrollRegister.nonce = self.nonce
        let requestBodyBytes = enrollRegister.getBytes()

        print("Got successful POW (SHA256): \(requestBodyBytes.sha256().toHexString())")

        // POW is valid, check connectivity again
        // Irrelevant, because bluesocket sucks and this status isnt valid at all
        // Very unlikely that the connection is killed by now
        if !socket.isConnected {
            print("Connection isnt valid anymore, retrying...")
        }

        print("Connection is still active, sending request...")
        // Send request
        var requestHeaderBytes = Data()
        // Body Size
        var size = UInt16(requestBodyBytes.count + 4).bigEndian
        requestHeaderBytes.append(withUnsafeBytes(of: &size, { Data($0) }))
        // Message Type
        var message = UInt16(Message.ENROLL_REGISTER).bigEndian
        requestHeaderBytes.append(withUnsafeBytes(of: &message, { Data($0) }))
        // build request
        let requestBytes = requestHeaderBytes + requestBodyBytes
        // send request
        print("Sending: \(requestBytes.toHexString())")
        let bytesSent = try socket.write(from: Data(requestBytes))
        print("\(bytesSent) bytes sent. Awaiting response...")

        var enrollRegisterResponse = Data()
        let readBytes = try socket.read(into: &enrollRegisterResponse)

        print("Response from server: \(readBytes) bytes, hex: \(enrollRegisterResponse.toHexString())")

        let _ = enrollRegisterResponse[0...1].reversed().withUnsafeBytes({ $0.load(as: UInt16.self) })
        let status = enrollRegisterResponse[2...3].reversed().withUnsafeBytes({ $0.load(as: UInt16.self) })

        if status == Message.ENROLL_SUCCESS {
            let teamNumber = enrollRegisterResponse[6...7].reversed().withUnsafeBytes({ $0.load(as: UInt16.self) })
            print("Enrolled successfully, team number: \(teamNumber)")
        } else if status == Message.ENROLL_FAILURE {
            let errorNumber = enrollRegisterResponse[6...7].reversed().withUnsafeBytes({ $0.load(as: UInt16.self) })
            let errorDescription = String(bytes: enrollRegisterResponse[8...], encoding: .utf8) ?? "n/a, hex: " + enrollRegisterResponse[8...].toHexString()
            print("Enrolling failed, error code \(errorNumber), description: \(errorDescription)")
        } else {
            fatalError("Error while parsing response: Unknown response status code")
        }

    }

}
