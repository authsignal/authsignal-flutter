package com.authsignal.authsignal_flutter

import android.app.Activity
import android.content.Context
import com.authsignal.TokenCache
import com.authsignal.email.AuthsignalEmail
import com.authsignal.passkey.AuthsignalPasskey
import com.authsignal.push.AuthsignalPush
import com.authsignal.sms.AuthsignalSMS
import com.authsignal.totp.AuthsignalTOTP
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


class AuthsignalPlugin: FlutterPlugin, ActivityAware, MethodCallHandler {
  private lateinit var channel : MethodChannel

  private lateinit var passkey: AuthsignalPasskey
  private lateinit var push: AuthsignalPush
  private lateinit var email: AuthsignalEmail
  private lateinit var sms: AuthsignalSMS
  private lateinit var totp: AuthsignalTOTP

  private var activity: Activity? = null
  private var context: Context? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "authsignal")
    channel.setMethodCallHandler(this)

    context = binding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when(call.method) {
      "passkey.initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!

        if (context != null && activity != null) {
          passkey = AuthsignalPasskey(tenantID, baseURL, context!!, activity!!)
        }

        result.success(null)
      }

      "passkey.signUp" -> {
        val token = call.argument<String>("token")
        val username = call.argument<String>("username")
        val displayName = call.argument<String>("displayName")

        passkey.signUpAsync(token, username, displayName).thenApply {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("signUpError", it.error!!, "")
          } else {
            val data = mapOf(
              "token" to it.data!!.token
            )

            result.success(data)
          }
        }
      }

      "passkey.signIn" -> {
        val action = call.argument<String>("action")
        val token = call.argument<String>("token")

        passkey.signInAsync(action, token).thenAcceptAsync {
          if (it.errorType != null) {
            if (it.errorType.equals("android.credentials.GetCredentialException.TYPE_NO_CREDENTIAL")) {
              result.error("signInNoCredential", "SIGN_IN_NO_CREDENTIAL", "")
            }

            if (it.errorType.equals("android.credentials.GetCredentialException.TYPE_USER_CANCELED")) {
              result.error("signInCanceled", "SIGN_IN_CANCELED", "")
            }
          } else if (it.error != null) {
            result.error("signInError", it.error!!, "")
          } else {
            val data = mapOf(
              "isVerified" to it.data!!.isVerified,
              "token" to it.data!!.token,
              "userId" to it.data!!.userId,
              "userAuthenticatorId" to it.data!!.userAuthenticatorId,
              "username" to it.data!!.username,
              "displayName" to it.data!!.displayName
            )

            result.success(data)
          }
        }
      }

      "passkey.isAvailableOnDevice" -> {
        passkey.isAvailableOnDeviceAsync().thenApply {
          if (it.error != null) {
            result.error("isAvailableOnDeviceError", it.error!!, "")
          } else {
            result.success(it.data)
          }
        }
      }

      "push.initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!

        push = AuthsignalPush(tenantID, baseURL)

        result.success(null)
      }

      "push.getCredential" -> {
        push.getCredentialAsync().thenAcceptAsync {
          if (it.error != null) {
            result.error("getCredentialError", it.error!!, "")
          } else if (it.data != null) {
            val data = mapOf(
              "credentialId" to it.data!!.credentialId,
              "createdAt" to it.data!!.createdAt,
              "lastAuthenticatedAt" to it.data!!.lastAuthenticatedAt
            )

            result.success(data)
          } else {
            result.success(null)
          }
        }
      }

      "push.addCredential" -> {
        val token = call.argument<String>("token")

        push.addCredentialAsync(token).thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("addCredentialError", it.error!!, "")
          } else {
            result.success(it.data)
          }
        }
      }

      "push.removeCredential" -> {
        push.removeCredentialAsync().thenAcceptAsync {
          if (it.error != null) {
            result.error("removeCredentialError", it.error!!, "")
          } else {
            result.success(it.data)
          }
        }
      }

      "push.getChallenge" -> {
        push.getChallengeAsync().thenAcceptAsync {
          if (it.error != null) {
            result.error("getChallengeError", it.error!!, "")
          } else if (it.data != null) {
            val data = mapOf(
              "challengeId" to it.data!!.challengeId,
              "actionCode" to it.data!!.actionCode,
              "idempotencyKey" to it.data!!.idempotencyKey,
              "ipAddress" to it.data!!.ipAddress,
              "deviceId" to it.data!!.deviceId,
              "userAgent" to it.data!!.userAgent
            )

            result.success(data)
          } else {
            result.success(null)
          }
        }
      }

      "push.updateChallenge" -> {
        val challengeId = call.argument<String>("challengeId")!!
        val approved = call.argument<Boolean>("approved")!!
        val verificationCode = call.argument<String>("verificationCode")

        push.updateChallengeAsync(challengeId, approved, verificationCode).thenAcceptAsync {
          if (it.error != null) {
            result.error("updateChallengeError", it.error!!, "")
          } else {
            result.success(it.data)
          }
        }
      }

      "email.initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!

        email = AuthsignalEmail(tenantID, baseURL)

        result.success(null)
      }

      "email.enroll" -> {
        val emailAddress = call.argument<String>("email")!!

        email.enrollAsync(emailAddress).thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("enrollError", it.error!!, "")
          } else {
            val data = mapOf(
              "userAuthenticatorId" to it.data!!.userAuthenticatorId,
            )

            result.success(data)
          }
        }
      }

      "email.challenge" -> {
        email.challengeAsync().thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("challengeError", it.error!!, "")
          } else {
            val data = mapOf(
              "challengeId" to it.data!!.challengeId,
            )

            result.success(data)
          }
        }
      }

      "email.verify" -> {
        val code = call.argument<String>("code")!!

        email.verifyAsync(code).thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("verifyError", it.error!!, "")
          } else {
            val data = mapOf(
              "isVerified" to it.data!!.isVerified,
              "token" to it.data!!.token,
              "failureReason" to it.data!!.failureReason,
            )

            result.success(data)
          }
        }
      }

      "sms.initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!

        sms = AuthsignalSMS(tenantID, baseURL)

        result.success(null)
      }

      "sms.enroll" -> {
        val phoneNumber = call.argument<String>("phoneNumber")!!

        sms.enrollAsync(phoneNumber).thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("enrollError", it.error!!, "")
          } else {
            val data = mapOf(
              "userAuthenticatorId" to it.data!!.userAuthenticatorId,
            )

            result.success(data)
          }
        }
      }

      "sms.challenge" -> {
        sms.challengeAsync().thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("challengeError", it.error!!, "")
          } else {
            val data = mapOf(
              "challengeId" to it.data!!.challengeId,
            )

            result.success(data)
          }
        }
      }

      "sms.verify" -> {
        val code = call.argument<String>("code")!!

        sms.verifyAsync(code).thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("verifyError", it.error!!, "")
          } else {
            val data = mapOf(
              "isVerified" to it.data!!.isVerified,
              "token" to it.data!!.token,
              "failureReason" to it.data!!.failureReason,
            )

            result.success(data)
          }
        }
      }

      "totp.initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!

        totp = AuthsignalTOTP(tenantID, baseURL)

        result.success(null)
      }

      "totp.enroll" -> {
        totp.enrollAsync().thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("enrollError", it.error!!, "")
          } else {
            val data = mapOf(
              "userAuthenticatorId" to it.data!!.userAuthenticatorId,
              "uri" to it.data!!.uri,
              "secret" to it.data!!.secret,
            )

            result.success(data)
          }
        }
      }

      "totp.verify" -> {
        val code = call.argument<String>("code")!!

        totp.verifyAsync(code).thenAcceptAsync {
          if (it.errorType != null && it.errorType.equals("TYPE_TOKEN_NOT_SET")) {
            result.error("tokenNotSetError", "TOKEN_NOT_SET", "")
          } else if (it.error != null) {
            result.error("verifyError", it.error!!, "")
          } else {
            val data = mapOf(
              "isVerified" to it.data!!.isVerified,
              "token" to it.data!!.token,
              "failureReason" to it.data!!.failureReason,
            )

            result.success(data)
          }
        }
      }

      "setToken" -> {
        val token = call.argument<String>("tenantID")!!

        TokenCache.shared.token = token

        result.success("token_set")
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
