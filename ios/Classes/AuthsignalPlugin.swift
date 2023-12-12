import Flutter
import UIKit
import Authsignal

public class AuthsignalPlugin: NSObject, FlutterPlugin {
  var passkey: AuthsignalPasskey?
  var push: AuthsignalPush?
  
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
      let userName = arguments["userName"] as? String

      Task.init {
        let response = await self.passkey!.signUp(token: token, userName: userName)
        
        if (response.error != nil) {
          let error = FlutterError(code: "signUpError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "passkey.signIn":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String
      let autofill = arguments["autofill"] as? Bool ?? false

      Task.init {
        let response = await self.passkey!.signIn(token: token, autofill: autofill)
        
        if (response.error != nil) {
          let error = FlutterError(code: "signInError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }

    case "passkey.cancel":
      self.passkey?.cancel()
      
    case "push.initialize":
      let arguments = call.arguments as! [String: Any]
      let tenantID = arguments["tenantID"] as! String
      let baseURL = arguments["baseURL"] as! String
      
      self.push = AuthsignalPush(tenantID: tenantID, baseURL: baseURL)
      
      result(nil)
      
    case "push.getCredential":
      Task.init {
        let response = await self.push!.getCredential()
        
        if (response.error != nil) {
          let error = FlutterError(code: "getCredentialError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
          
    case "push.addCredential":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as! String

      Task.init {
        let response = await self.push!.addCredential(token: token)
        
        if (response.error != nil) {
          let error = FlutterError(code: "addCredentialError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.removeCredential":
      Task.init {
        let response = await self.push!.removeCredential()
        
        if (response.error != nil) {
          let error = FlutterError(code: "removeCredentialError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }
      
    case "push.getChallenge":
      Task.init {
        let response = await self.push!.getChallenge()
        
        if (response.error != nil) {
          let error = FlutterError(code: "getChallengeError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data ?? nil)
        }
      }
      
    case "push.updateChallenge":
      let arguments = call.arguments as! [String: Any]
      let challengeID = arguments["challengeId"] as! String
      let approved = arguments["approved"] as! Bool
      let verificationCode = arguments["verificationCode"] as? String
      
      Task.init {
        let response = await self.push!.updateChallenge(
          challengeID: challengeID,
          approved: approved,
          verificationCode: verificationCode
        )
        
        if (response.error != nil) {
          let error = FlutterError(code: "updateChallengeError", message: response.error, details: "");
          result(error)
        } else {
          result(response.data)
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
