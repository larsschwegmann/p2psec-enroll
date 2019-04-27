//
//  POWOperation.swift
//  p2p-enroll
//
//  Created by Lars Schwegmann on 25.04.19.
//

import Foundation
import CommonCrypto

class POWOperation: Operation {

    var enrollmentInfo: EnrollmentInfo
    var enrollmentManager: EnrollmentManager
    var id: Int
    var nonceStart: UInt64
    var nonceEnd: UInt64

    init(enrollmentInfo: EnrollmentInfo, enrollmentManager: EnrollmentManager, id: Int, nonceStart: UInt64, nonceEnd: UInt64) {
        self.enrollmentInfo = enrollmentInfo
        self.enrollmentManager = enrollmentManager
        self.id = id
        self.nonceStart = nonceStart
        self.nonceEnd = nonceEnd
    }

    override func main() {
        var enrollRegister = EnrollRegister(enrollmentInfo: self.enrollmentInfo,
                                            challenge: self.enrollmentManager.challenge,
                                            nonceStart: nonceStart)
        while !isCancelled {
            enrollRegister.challenge = enrollmentManager.challenge
            
            let enrollRegisterBytes = enrollRegister.getBytes()
            let hash = sha256(data: enrollRegisterBytes)

            if checkPOW(hash) {
                // we are done
                enrollmentManager.nonce = enrollRegister.nonce
                print("Thread \(id): Found matching nonce \(enrollmentManager.nonce) with hash \(hash.toHexString())")
                break
            } else {
                enrollmentManager.attempts += 1
                if enrollRegister.nonce == nonceEnd {
                    // Reset nonce
                    enrollRegister.nonce = nonceStart
                } else {
                    enrollRegister.incrementNonce()
                }
            }
        }

    }

    func sha256(data: Data) -> Data {
        // https://stackoverflow.com/questions/25388747/sha256-in-swift
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }

    private func checkPOW(_ bytes: Data) -> Bool {
        return bytes[0] == 0 && bytes[1] == 0 && bytes[2] == 0 && bytes[3] <= 0x03
    }

}
