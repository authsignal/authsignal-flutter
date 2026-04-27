import Flutter
import UIKit
import Authsignal

public class AuthsignalPlugin: NSObject, FlutterPlugin {
  var passkey: AuthsignalPasskey?
  var push: AuthsignalPush?
  var email: AuthsignalEmail?
  var sms: AuthsignalSMS?
  var totp: AuthsignalTOTP?
  var whatsapp: AuthsignalWhatsApp?
  var qr: AuthsignalQRCode?
  var inapp: AuthsignalInApp?

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
      let deviceID = arguments["deviceID"] as? String

      self.passkey = AuthsignalPasskey(tenantID: tenantID, baseURL: baseURL, deviceID: deviceID)
      self.push = AuthsignalPush(tenantID: tenantID, baseURL: baseURL)
      self.email = AuthsignalEmail(tenantID: tenantID, baseURL: baseURL)
      self.sms = AuthsignalSMS(tenantID: tenantID, baseURL: baseURL)
      self.totp = AuthsignalTOTP(tenantID: tenantID, baseURL: baseURL)
      self.whatsapp = AuthsignalWhatsApp(tenantID: tenantID, baseURL: baseURL)
      self.qr = AuthsignalQRCode(tenantID: tenantID, baseURL: baseURL)
      self.inapp = AuthsignalInApp(tenantID: tenantID, baseURL: baseURL)

      result(nil)

    case "getDeviceId":
      Task.init {
        let deviceId = await DeviceCache.shared.getDefaultDeviceID()
        result(deviceId)
      }

    case "passkey.signUp":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String
      let username = arguments["username"] as? String
      let displayName = arguments["displayName"] as? String
      let ignorePasskeyAlreadyExistsError = arguments["ignorePasskeyAlreadyExistsError"] as? Bool ?? false

      Task.init {
        let response = await self.passkey!.signUp(
          token: token,
          username: username,
          displayName: displayName,
          ignorePasskeyAlreadyExistsError: ignorePasskeyAlreadyExistsError
        )

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          let data: [String: Any?] = [
            "token": response.data?.token,
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
        } else if let data = response.data {
          let payload: [String: Any?] = [
            "isVerified": data.isVerified,
            "token": data.token,
            "userId": data.userId,
            "userAuthenticatorId": data.userAuthenticatorId,
            "username": data.username,
            "displayName": data.displayName,
          ]

          result(payload)
        } else {
          result(nil)
        }
      }

    case "passkey.cancel":
      self.passkey?.cancel()
      result(nil)

    case "passkey.shouldPromptToCreatePasskey":
      let arguments = call.arguments as? [String: Any]
      let username = arguments?["username"] as? String

      Task.init {
        let response = await self.passkey!.shouldPromptToCreatePasskey(username: username)

        if response.error != nil {
          result(false)
        } else {
          result(response.data ?? false)
        }
      }

    case "passkey.isAvailableOnDevice":
      Task.init {
        let response = await self.passkey!.isAvailableOnDevice()

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data)
        }
      }

    case "push.getCredential":
      Task.init {
        let response = await self.push!.getCredential()

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

    case "push.addCredential":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String
      let requireUserAuthentication = arguments["requireUserAuthentication"] as? Bool ?? false
      let keychainAccess = AuthsignalPlugin.getKeychainAccess(value: arguments["keychainAccess"] as? String)
      let performAttestation = arguments["performAttestation"] as? Bool ?? false

      Task.init {
        let response = await self.push!.addCredential(
          token: token,
          keychainAccess: keychainAccess,
          userPresenceRequired: requireUserAuthentication,
          performAttestation: performAttestation
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

    case "push.removeCredential":
      Task.init {
        let response = await self.push!.removeCredential()

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data)
        }
      }

    case "push.getChallenge":
      Task.init {
        let response = await self.push!.getChallenge()

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let challenge = response.data as? AppChallenge {
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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

    case "whatsapp.challenge":
      Task.init {
        let response = await self.whatsapp!.challenge()

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          let challengeResponse: [String: Any?] = [
            "challengeId": response.data!.challengeId,
          ]

          result(challengeResponse)
        }
      }

    case "whatsapp.verify":
      let arguments = call.arguments as! [String: Any]
      let code = arguments["code"] as! String

      Task.init {
        let response = await self.whatsapp!.verify(code: code)

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
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

    case "qr.getCredential":
      Task.init {
        let response = await self.qr!.getCredential()

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

    case "qr.addCredential":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String
      let requireUserAuthentication = arguments["requireUserAuthentication"] as? Bool ?? false
      let keychainAccess = AuthsignalPlugin.getKeychainAccess(value: arguments["keychainAccess"] as? String)
      let performAttestation = arguments["performAttestation"] as? Bool ?? false

      Task.init {
        let response = await self.qr!.addCredential(
          token: token,
          keychainAccess: keychainAccess,
          userPresenceRequired: requireUserAuthentication,
          performAttestation: performAttestation
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

    case "qr.removeCredential":
      Task.init {
        let response = await self.qr!.removeCredential()

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data)
        }
      }

    case "qr.claimChallenge":
      let arguments = call.arguments as! [String: Any]
      let challengeId = arguments["challengeId"] as! String

      Task.init {
        let response = await self.qr!.claimChallenge(challengeId: challengeId)

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let data = response.data {
          let claimResponse: [String: Any?] = [
            "success": data.success,
            "userAgent": data.userAgent,
            "ipAddress": data.ipAddress,
            "actionCode": data.actionCode,
            "idempotencyKey": data.idempotencyKey,
          ]

          result(claimResponse)
        } else {
          result(nil)
        }
      }

    case "qr.updateChallenge":
      let arguments = call.arguments as! [String: Any]
      let challengeId = arguments["challengeId"] as! String
      let approved = arguments["approved"] as! Bool
      let verificationCode = arguments["verificationCode"] as? String

      Task.init {
        let response = await self.qr!.updateChallenge(
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

    case "inapp.getCredential":
      let arguments = call.arguments as? [String: Any]
      let username = arguments?["username"] as? String

      Task.init {
        let response = await self.inapp!.getCredential(username: username)

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

    case "inapp.addCredential":
      let arguments = call.arguments as! [String: Any]
      let token = arguments["token"] as? String
      let requireUserAuthentication = arguments["requireUserAuthentication"] as? Bool ?? false
      let keychainAccess = AuthsignalPlugin.getKeychainAccess(value: arguments["keychainAccess"] as? String)
      let username = arguments["username"] as? String
      let performAttestation = arguments["performAttestation"] as? Bool ?? false

      Task.init {
        let response = await self.inapp!.addCredential(
          token: token,
          keychainAccess: keychainAccess,
          userPresenceRequired: requireUserAuthentication,
          username: username,
          performAttestation: performAttestation
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

    case "inapp.removeCredential":
      let arguments = call.arguments as? [String: Any]
      let username = arguments?["username"] as? String

      Task.init {
        let response = await self.inapp!.removeCredential(username: username)

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data)
        }
      }

    case "inapp.verify":
      let arguments = call.arguments as? [String: Any]
      let action = arguments?["action"] as? String
      let username = arguments?["username"] as? String

      Task.init {
        let response = await self.inapp!.verify(action: action, username: username)

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let data = response.data {
          let verifyResponse: [String: Any?] = [
            "token": data.token,
            "userId": data.userId,
            "userAuthenticatorId": data.userAuthenticatorId,
            "username": data.username,
          ]

          result(verifyResponse)
        } else {
          result(nil)
        }
      }

    case "inapp.createPin":
      let arguments = call.arguments as! [String: Any]
      let pin = arguments["pin"] as! String
      let username = arguments["username"] as! String
      let token = arguments["token"] as? String

      Task.init {
        let response = await self.inapp!.createPin(pin: pin, username: username, token: token)

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

    case "inapp.verifyPin":
      let arguments = call.arguments as! [String: Any]
      let pin = arguments["pin"] as! String
      let username = arguments["username"] as! String
      let action = arguments["action"] as? String

      Task.init {
        let response = await self.inapp!.verifyPin(pin: pin, username: username, action: action)

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else if let data = response.data {
          let verifyPinResponse: [String: Any?] = [
            "isVerified": data.isVerified,
            "token": data.token,
            "userId": data.userId,
          ]

          result(verifyPinResponse)
        } else {
          result(nil)
        }
      }

    case "inapp.deletePin":
      let arguments = call.arguments as! [String: Any]
      let username = arguments["username"] as! String

      Task.init {
        let response = await self.inapp!.deletePin(username: username)

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data)
        }
      }

    case "inapp.getAllPinUsernames":
      Task.init {
        let response = await self.inapp!.getAllPinUsernames()

        if response.error != nil {
          let error = FlutterError(code: response.errorCode ?? "unexpected_error", message: response.error, details: "")
          result(error)
        } else {
          result(response.data ?? [])
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

  static func getKeychainAccess(value: String?) -> KeychainAccess {
    switch value {
    case "afterFirstUnlock":
      return .afterFirstUnlock

    case "afterFirstUnlockThisDeviceOnly":
      return .afterFirstUnlockThisDeviceOnly

    case "whenUnlocked":
      return .whenUnlocked

    case "whenUnlockedThisDeviceOnly":
      return .whenUnlockedThisDeviceOnly

    case "whenPasscodeSetThisDeviceOnly":
      return .whenPasscodeSetThisDeviceOnly

    default:
      return .whenUnlockedThisDeviceOnly
    }
  }
}
