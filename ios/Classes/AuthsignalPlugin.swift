import Flutter
import UIKit
import Authsignal

public class AuthsignalPlugin: NSObject, FlutterPlugin {
  var passkey: AuthsignalPasskey?
  var push: AuthsignalPush?
  var email: AuthsignalEmail?
  var sms: AuthsignalSMS?
  var totp: AuthsignalTOTP?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "authsignal", binaryMessenger: registrar.messenger())
    
    let instance = AuthsignalPlugin()
    
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "passkey.initialize":
      let arguments = call.arguments as! [String: Any]
      let tenantID = arguments["tenantID"] as! String
      let baseURL = arguments["baseURL"] as! String
      
      self.passkey = AuthsignalPasskey(tenantID: tenantID, baseURL: baseURL)
      
      result(nil)

    case "passkey.signUp":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as! String
      let username = arguments["username"] as? String
      let displayName = arguments["displayName"] as? String

      Task.init {
        let response = await self.passkey!.signUp(token: token, username: username)
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "signUpError", message: response.error, details: "")
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
        
        if (response.errorCode == "SIGN_IN_CANCELED") {
          let error = FlutterError(code: "signInCanceled", message: "SIGN_IN_CANCELED", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "signInError", message: response.error, details: "")
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
          let error = FlutterError(code: "isAvailableOnDeviceError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.initialize":
      let arguments = call.arguments as! [String: Any]
      let tenantID = arguments["tenantID"] as! String
      let baseURL = arguments["baseURL"] as! String
      
      self.push = AuthsignalPush(tenantID: tenantID, baseURL: baseURL)
      
      result(nil)
      
    case "push.getCredential":
      Task.init {
        let response = await self.push!.getCredential()
        
        if response.error != nil {
          let error = FlutterError(code: "getCredentialError", message: response.error, details: "");
          result(error)
        } else if let data = response.data {
          let credential: [String: String?] = [
            "credentialId": data.credentialId,
            "createdAt": data.createdAt,
            "lastAuthenticatedAt": data.lastAuthenticatedAt,
          ]

          result(data)
        } else {
          result(nil)
        }
      }
          
    case "push.addCredential":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String

      Task.init {
        let response = await self.push!.addCredential(token: token)
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "addCredentialError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.removeCredential":
      Task.init {
        let response = await self.push!.removeCredential()
        
        if response.error != nil {
          let error = FlutterError(code: "removeCredentialError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.getChallenge":
      Task.init {
        let response = await self.push!.getChallenge()
        
        if response.error != nil {
          let error = FlutterError(code: "getChallengeError", message: response.error, details: "");
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
          let error = FlutterError(code: "updateChallengeError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "email.initialize":
      let arguments = call.arguments as! [String: Any]
      let tenantID = arguments["tenantID"] as! String
      let baseURL = arguments["baseURL"] as! String
      
      self.email = AuthsignalEmail(tenantID: tenantID, baseURL: baseURL)
      
      result(nil)
      
    case "email.enroll":
      let arguments = call.arguments as! [String: Any]
      let email = arguments["email"] as! String
      
      Task.init {
        let response = await self.email!.enroll(email: email)
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "enrollError", message: response.error, details: "");
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
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "challengeError", message: response.error, details: "");
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
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "verifyError", message: response.error, details: "");
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
      
    case "sms.initialize":
      let arguments = call.arguments as! [String: Any]
      let tenantID = arguments["tenantID"] as! String
      let baseURL = arguments["baseURL"] as! String
      
      self.sms = AuthsignalSMS(tenantID: tenantID, baseURL: baseURL)
      
      result(nil)
      
    case "sms.enroll":
      let arguments = call.arguments as! [String: Any]
      let phoneNumber = arguments["phoneNumber"] as! String
      
      Task.init {
        let response = await self.sms!.enroll(phoneNumber: phoneNumber)
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "enrollError", message: response.error, details: "");
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
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "challengeError", message: response.error, details: "");
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
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "verifyError", message: response.error, details: "");
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

    case "totp.initialize":
      let arguments = call.arguments as! [String: Any]
      let tenantID = arguments["tenantID"] as! String
      let baseURL = arguments["baseURL"] as! String
      
      self.totp = AuthsignalTOTP(tenantID: tenantID, baseURL: baseURL)
      
    case "totp.enroll":
      Task.init {
        let response = await self.totp!.enroll()
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "enrollError", message: response.error, details: "");
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
        
        if response.errorCode == "TOKEN_NOT_SET" {
          let error = FlutterError(code: "tokenNotSetError", message: "TOKEN_NOT_SET", details: "")
          result(error)
        } else if response.error != nil {
          let error = FlutterError(code: "verifyError", message: response.error, details: "");
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
