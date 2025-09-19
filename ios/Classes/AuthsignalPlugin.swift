import Flutter
import UIKit
import Authsignal

public class AuthsignalPlugin: NSObject, FlutterPlugin {
  var passkey: AuthsignalPasskey?
  var push: AuthsignalPush?
  var email: AuthsignalEmail?
  var sms: AuthsignalSMS?
  var totp: AuthsignalTOTP?
  var device: AuthsignalDevice?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "authsignal", binaryMessenger: registrar.messenger())
    
    let instance = AuthsignalPlugin()
    
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      let arguments = call.arguments as! [String: Any]
      let tenantID = arguments["tenantID"] as! String
      let baseURL = arguments["baseURL"] as! String
      
      self.passkey = AuthsignalPasskey(tenantID: tenantID, baseURL: baseURL)
      self.push = AuthsignalPush(tenantID: tenantID, baseURL: baseURL)
      self.email = AuthsignalEmail(tenantID: tenantID, baseURL: baseURL)
      self.sms = AuthsignalSMS(tenantID: tenantID, baseURL: baseURL)
      self.totp = AuthsignalTOTP(tenantID: tenantID, baseURL: baseURL)
      self.device = AuthsignalDevice(tenantID: tenantID, baseURL: baseURL)
      
      result(nil)

    case "passkey.signUp":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as! String
      let username = arguments["username"] as? String
      let displayName = arguments["displayName"] as? String

      Task.init {
        let response = await self.passkey!.signUp(token: token, username: username, displayName: displayName)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          let data: [String: Any?] = [
            "token": response.data!.token,
          ]

          result(data)
        }
      }
      
    case "passkey.signIn":
      let arguments = call.arguments as! [String: Any]
      let action = arguments["action"] as? String
      let token = arguments["token"] as? String
      let autofill = arguments["autofill"] as? Bool ?? false
      let preferImmediatelyAvailableCredentials = arguments["preferImmediatelyAvailableCredentials"] as? Bool ?? true

      Task.init {
        let response = await self.passkey!.signIn(
          token: token,
          action: action,
          autofill: autofill,
          preferImmediatelyAvailableCredentials: preferImmediatelyAvailableCredentials
        )
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          let data: [String: Any?] = [
            "isVerified": response.data!.isVerified,
            "token": response.data!.token,
            "userId": response.data!.userId,
            "userAuthenticatorId": response.data!.userAuthenticatorId,
            "username": response.data!.username,
            "displayName": response.data!.displayName,
          ]

          result(data)
        }
      }

    case "passkey.cancel":
      self.passkey?.cancel()

    case "passkey.isAvailableOnDevice":
      Task.init {
        let response = await self.passkey!.isAvailableOnDevice()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.getCredential":
      Task.init {
        let response = await self.push!.getCredential()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else if let data = response.data {
          let credential: [String: String?] = [
            "credentialId": data.credentialId,
            "createdAt": data.createdAt,
            "lastAuthenticatedAt": data.lastAuthenticatedAt,
          ]

          result(credential)
        } else {
          result(nil)
        }
      }
          
    case "push.addCredential":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String

      Task.init {
        let response = await self.push!.addCredential(token: token)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.removeCredential":
      Task.init {
        let response = await self.push!.removeCredential()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.getChallenge":
      Task.init {
        let response = await self.push!.getChallenge()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else if let challenge = response.data as? PushChallenge {
          let data: [String: String?] = [
            "challengeId": challenge.challengeId,
            "actionCode": challenge.actionCode,
            "idempotencyKey": challenge.idempotencyKey,
            "userAgent": challenge.userAgent,
            "deviceId": challenge.deviceId,
            "ipAddress": challenge.ipAddress,
          ]

          result(data)
        } else {
          result(nil)
        }
      }
      
    case "push.updateChallenge":
      let arguments = call.arguments as! [String: Any]
      let challengeId = arguments["challengeId"] as! String
      let approved = arguments["approved"] as! Bool
      let verificationCode = arguments["verificationCode"] as? String
      
      Task.init {
        let response = await self.push!.updateChallenge(
          challengeId: challengeId,
          approved: approved,
          verificationCode: verificationCode
        )
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "email.enroll":
      let arguments = call.arguments as! [String: Any]
      let email = arguments["email"] as! String
      
      Task.init {
        let response = await self.email!.enroll(email: email)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let enrollResponse: [String: Any?] = [
            "userAuthenticatorId": response.data!.userAuthenticatorId,
          ]
          
          result(enrollResponse)
        }
      }
      
    case "email.challenge":
      Task.init {
        let response = await self.email!.challenge()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let challengeResponse: [String: Any?] = [
            "challengeId": response.data!.challengeId,
          ]
          
          result(challengeResponse)
        }
      }
      
    case "email.verify":
      let arguments = call.arguments as! [String: Any]
      let code = arguments["code"] as! String
      
      Task.init {
        let response = await self.email!.verify(code: code)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let verifyResponse: [String: Any?] = [
            "isVerified": response.data!.isVerified,
            "token": response.data!.token,
            "failureReason": response.data!.failureReason,
          ]
          
          result(verifyResponse)
        }
      }
      
    case "sms.enroll":
      let arguments = call.arguments as! [String: Any]
      let phoneNumber = arguments["phoneNumber"] as! String
      
      Task.init {
        let response = await self.sms!.enroll(phoneNumber: phoneNumber)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let enrollResponse: [String: Any?] = [
            "userAuthenticatorId": response.data!.userAuthenticatorId,
          ]
          
          result(enrollResponse)
        }
      }
      
    case "sms.challenge":
      Task.init {
        let response = await self.sms!.challenge()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let challengeResponse: [String: Any?] = [
            "challengeId": response.data!.challengeId,
          ]
          
          result(challengeResponse)
        }
      }
      
    case "sms.verify":
      let arguments = call.arguments as! [String: Any]
      let code = arguments["code"] as! String
      
      Task.init {
        let response = await self.sms!.verify(code: code)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let verifyResponse: [String: Any?] = [
            "isVerified": response.data!.isVerified,
            "token": response.data!.token,
            "failureReason": response.data!.failureReason,
          ]
          
          result(verifyResponse)
        }
      }
      
    case "totp.enroll":
      Task.init {
        let response = await self.totp!.enroll()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let enrollResponse: [String: String?] = [
            "userAuthenticatorId": response.data!.userAuthenticatorId,
            "uri": response.data!.uri,
            "secret": response.data!.secret,
          ]
          
          result(enrollResponse)
        }
      }
      
    case "totp.verify":
      let arguments = call.arguments as! [String: Any]
      let code = arguments["code"] as! String
      
      Task.init {
        let response = await self.totp!.verify(code: code)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "");
          result(error)
        } else {
          let verifyResponse: [String: Any?] = [
            "isVerified": response.data!.isVerified,
            "token": response.data!.token,
            "failureReason": response.data!.failureReason,
          ]
          
          result(verifyResponse)
        }
      }

    case "device.getCredential":
      Task.init {
        let response = await self.device!.getCredential()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let data = response.data {
          let credential: [String: String?] = [
            "credentialId": data.credentialId,
            "createdAt": data.createdAt,
            "userId": data.userId,
            "lastAuthenticatedAt": data.lastAuthenticatedAt,
          ]

          result(credential)
        } else {
          result(nil)
        }
      }

    case "device.addCredential":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String
      let deviceName = arguments["deviceName"] as? String
      let userAuthenticationRequired = arguments["userAuthenticationRequired"] as? Bool ?? false

      Task.init {
        let response = await self.device!.addCredential(
          token: token,
          userPresenceRequired: userAuthenticationRequired
        )
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let data = response.data {
          let credential: [String: String?] = [
            "credentialId": data.credentialId,
            "createdAt": data.createdAt,
            "userId": data.userId,
            "lastAuthenticatedAt": data.lastAuthenticatedAt,
          ]

          result(credential)
        } else {
          result(nil)
        }
      }

    case "device.removeCredential":
      Task.init {
        let response = await self.device!.removeCredential()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data)
        }
      }

    case "device.getChallenge":
      Task.init {
        let response = await self.device!.getChallenge()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let challenge = response.data {
          let data: [String: String?] = [
            "challengeId": challenge.challengeId,
            "userId": challenge.userId,
            "actionCode": challenge.actionCode,
            "idempotencyKey": challenge.idempotencyKey,
            "deviceId": challenge.deviceId,
            "userAgent": challenge.userAgent,
            "ipAddress": challenge.ipAddress,
          ]

          result(data)
        } else {
          result(nil)
        }
      }

    case "device.claimChallenge":
      let arguments = call.arguments as! [String: Any]
      let challengeId = arguments["challengeId"] as! String
      
      Task.init {
        let response = await self.device!.claimChallenge(challengeId: challengeId)
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let data = response.data {
          let claimResponse: [String: String?] = [
            "challengeId": data.challengeId,
            "userId": data.userId,
          ]

          result(claimResponse)
        } else {
          result(nil)
        }
      }

    case "device.updateChallenge":
      let arguments = call.arguments as! [String: Any]
      let challengeId = arguments["challengeId"] as! String
      let approved = arguments["approved"] as! Bool
      let verificationCode = arguments["verificationCode"] as? String
      
      Task.init {
        let response = await self.device!.updateChallenge(
          challengeId: challengeId,
          approved: approved,
          verificationCode: verificationCode
        )
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data)
        }
      }

    case "device.verify":
      Task.init {
        let response = await self.device!.verify()
        
        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let data = response.data {
          let verifyResponse: [String: Any?] = [
            "isVerified": data.isVerified,
            "token": data.token,
            "userId": data.userId,
            "userAuthenticatorId": data.userAuthenticatorId,
            "username": data.username,
            "displayName": data.displayName,
          ]

          result(verifyResponse)
        } else {
          result(nil)
        }
      }

    case "setToken":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as! String
      
      TokenCache.shared.token = token

      result("token_set")

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
