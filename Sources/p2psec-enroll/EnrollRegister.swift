//
//  EnrollInit.swift
//  CryptoSwift
//
//  Created by Lars Schwegmann on 23.04.19.
//

import Foundation

enum Project: UInt16 {
    case DHT = 4963
    case RPS = 15882
    case NSE = 7071
    case Onion = 39943
}

struct EnrollRegister {
    var challenge: [UInt8]
    var teamNumber: UInt16
    var projectChoice: Project
    var nonce: UInt64
    var email: String
    var firstName: String
    var lastName: String

    init(enrollmentInfo: EnrollmentInfo, challenge: [UInt8], nonceStart: UInt64 = 0) {
        self.challenge = challenge
        self.teamNumber = enrollmentInfo.teamNumber
        self.projectChoice = enrollmentInfo.projectChoice
        self.email = enrollmentInfo.email
        self.firstName = enrollmentInfo.firstName
        self.lastName = enrollmentInfo.lastName
        self.nonce = nonceStart
    }

    mutating func incrementNonce() {
        self.nonce += 1
    }

    func getBytes() -> Data {
        var retVal = Data()
        // Challenge
        retVal.append(contentsOf: self.challenge)
        // Team Number
        var teamNumber = self.teamNumber.bigEndian
        let teamNumberBytes = withUnsafeBytes(of: &teamNumber, { Data($0) })
        retVal.append(teamNumberBytes)
        // Project Choice
        var projectChoice = self.projectChoice.rawValue.bigEndian
        let projectChoiceBytes = withUnsafeBytes(of: &projectChoice, { Data($0) })
        retVal.append(projectChoiceBytes)
        // Nonce
        var nonce = self.nonce.bigEndian
        let nonceBytes = withUnsafeBytes(of: &nonce, { Data($0) })
        retVal.append(nonceBytes)

        // String parts
        let string = "\(self.email)\r\n\(self.firstName)\r\n\(self.lastName)"

        // Append string
        #if os(Linux)
        let data = string.data(using: .utf8)!
        retVal.append(data)
        #else
        autoreleasepool {
            let data = string.data(using: .utf8)!
            retVal.append(data)
        }
        #endif
        return retVal
    }
}
