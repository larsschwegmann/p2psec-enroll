import Foundation

////////////////////////////////////////////////////////////////////////////////////////

// Change stuff here
let server = "fulcrum.net.in.tum.de"
let port: Int32 = 34151

////////////////////////////////////////////////////////////////////////////////////////

let firstName = "Lars"
let lastName = "Schwegmann"
let email = ""
let projectChoice = Project.DHT
let teamNumber: UInt16 = 0

////////////////////////////////////////////////////////////////////////////////////////

let info = EnrollmentInfo(firstName: firstName,
                          lastName: lastName,
                          email: email,
                          projectChoice: projectChoice,
                          teamNumber: teamNumber)

let manager = try EnrollmentManager(info)
try manager.enroll()
