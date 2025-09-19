package com.authsignal.authsignal_flutter

import android.app.Activity
import android.content.Context
import com.authsignal.TokenCache
import com.authsignal.device.AuthsignalDevice
import com.authsignal.email.AuthsignalEmail
import com.authsignal.models.AuthsignalResponse
import com.authsignal.passkey.AuthsignalPasskey
import com.authsignal.push.AuthsignalPush
import com.authsignal.sms.AuthsignalSMS
import com.authsignal.totp.AuthsignalTOTP
import com.authsignal.whatsapp.AuthsignalWhatsApp
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class AuthsignalPlugin: FlutterPlugin, ActivityAware, MethodCallHandler {
  private lateinit var channel : MethodChannel

  private lateinit var passkey: AuthsignalPasskey
  private lateinit var push: AuthsignalPush
  private lateinit var email: AuthsignalEmail
  private lateinit var sms: AuthsignalSMS
  private lateinit var totp: AuthsignalTOTP
  private lateinit var whatsapp: AuthsignalWhatsApp
  private lateinit var device: AuthsignalDevice

  private var activity: Activity? = null
  private var context: Context? = null
  private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "authsignal")
    channel.setMethodCallHandler(this)

    context = binding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when(call.method) {
      "initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!

        activity?.let {
          passkey = AuthsignalPasskey(tenantID, baseURL, it)
        }

        push = AuthsignalPush(tenantID, baseURL)
        email = AuthsignalEmail(tenantID, baseURL)
        sms = AuthsignalSMS(tenantID, baseURL)
        totp = AuthsignalTOTP(tenantID, baseURL)
        whatsapp = AuthsignalWhatsApp(tenantID, baseURL)
        device = AuthsignalDevice(tenantID, baseURL)

        result.success(null)
      }

      "passkey.signUp" -> {
        val token = call.argument<String>("token")
        val username = call.argument<String>("username")
        val displayName = call.argument<String>("displayName")

        coroutineScope.launch {
          val response = passkey.signUp(token, username, displayName)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "token" to it.token
            )

            result.success(data)
          }
        }
      }

      "passkey.signIn" -> {
        val action = call.argument<String>("action")
        val token = call.argument<String>("token")

        coroutineScope.launch {
          val response = passkey.signIn(action, token)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "isVerified" to it.isVerified,
              "token" to it.token,
              "userId" to it.userId,
              "userAuthenticatorId" to it.userAuthenticatorId,
              "username" to it.username,
              "displayName" to it.displayName
            )

            result.success(data)
          }
        }
      }

      "passkey.isAvailableOnDevice" -> {
        coroutineScope.launch {
          val response = passkey.isAvailableOnDevice()

          handleResponse(response, result)?.let {
            result.success(response.data)
          }
        }
      }

      "push.getCredential" -> {
        coroutineScope.launch {
          val response = push.getCredential()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "credentialId" to it.credentialId,
              "createdAt" to it.createdAt,
              "lastAuthenticatedAt" to it.lastAuthenticatedAt
            )

            result.success(data)
          }
        }
      }

      "push.addCredential" -> {
        val token = call.argument<String>("token")

        coroutineScope.launch {
          val response = push.addCredential(token)

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "push.removeCredential" -> {
        coroutineScope.launch {
          val response = push.removeCredential()

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "push.getChallenge" -> {
        coroutineScope.launch {
          val response = push.getChallenge()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "challengeId" to it.challengeId,
              "actionCode" to it.actionCode,
              "idempotencyKey" to it.idempotencyKey,
              "ipAddress" to it.ipAddress,
              "deviceId" to it.deviceId,
              "userAgent" to it.userAgent
            )

            result.success(data)
          }
        }
      }

      "push.updateChallenge" -> {
        val challengeId = call.argument<String>("challengeId")!!
        val approved = call.argument<Boolean>("approved")!!
        val verificationCode = call.argument<String>("verificationCode")

        coroutineScope.launch {
          val response = push.updateChallenge(challengeId, approved, verificationCode)

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "email.enroll" -> {
        val emailAddress = call.argument<String>("email")!!

        coroutineScope.launch {
          val response = email.enroll(emailAddress)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "userAuthenticatorId" to it.userAuthenticatorId,
            )

            result.success(data)
          }
        }
      }

      "email.challenge" -> {
        coroutineScope.launch {
          val response = email.challenge()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "challengeId" to it.challengeId,
            )

            result.success(data)
          }
        }
      }

      "email.verify" -> {
        val code = call.argument<String>("code")!!

        coroutineScope.launch {
          val response = email.verify(code)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "isVerified" to it.isVerified,
              "token" to it.token,
              "failureReason" to it.failureReason,
            )

            result.success(data)
          }
        }
      }

      "sms.enroll" -> {
        val phoneNumber = call.argument<String>("phoneNumber")!!

        coroutineScope.launch {
          val response = sms.enroll(phoneNumber)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "userAuthenticatorId" to it.userAuthenticatorId,
            )

            result.success(data)
          }
        }
      }

      "sms.challenge" -> {
        coroutineScope.launch {
          val response = sms.challenge()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "challengeId" to it.challengeId,
            )

            result.success(data)
          }
        }
      }

      "sms.verify" -> {
        val code = call.argument<String>("code")!!

        coroutineScope.launch {
          val response = sms.verify(code)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "isVerified" to it.isVerified,
              "token" to it.token,
              "failureReason" to it.failureReason,
            )

            result.success(data)
          }
        }
      }

      "totp.enroll" -> {
        coroutineScope.launch {
          val response = totp.enroll()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "userAuthenticatorId" to it.userAuthenticatorId,
              "uri" to it.uri,
              "secret" to it.secret,
            )

            result.success(data)
          }
        }
      }

      "totp.verify" -> {
        val code = call.argument<String>("code")!!

        coroutineScope.launch {
          val response = totp.verify(code)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "isVerified" to it.isVerified,
              "token" to it.token,
              "failureReason" to it.failureReason,
            )

            result.success(data)
          }
        }
      }

      "whatsapp.challenge" -> {
        coroutineScope.launch {
          val response = whatsapp.challenge()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "challengeId" to it.challengeId,
            )

            result.success(data)
          }
        }
      }

      "whatsapp.verify" -> {
        val code = call.argument<String>("code")!!

        coroutineScope.launch {
          val response = whatsapp.verify(code)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "isVerified" to it.isVerified,
              "token" to it.token,
              "failureReason" to it.failureReason,
            )

            result.success(data)
          }
        }
      }

      "device.getCredential" -> {
        coroutineScope.launch {
          val response = device.getCredential()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "credentialId" to it.credentialId,
              "createdAt" to it.createdAt,
              "userId" to it.userId,
              "lastAuthenticatedAt" to it.lastAuthenticatedAt
            )

            result.success(data)
          }
        }
      }

      "device.addCredential" -> {
        val token = call.argument<String>("token")
        val deviceName = call.argument<String>("deviceName")
        val userAuthenticationRequired = call.argument<Boolean>("userAuthenticationRequired") ?: false
        val timeout = call.argument<Int>("timeout") ?: 0
        val authorizationType = call.argument<Int>("authorizationType") ?: 0

        coroutineScope.launch {
          val response = device.addCredential(token, deviceName, userAuthenticationRequired, timeout, authorizationType)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "credentialId" to it.credentialId,
              "createdAt" to it.createdAt,
              "userId" to it.userId,
              "lastAuthenticatedAt" to it.lastAuthenticatedAt
            )

            result.success(data)
          }
        }
      }

      "device.removeCredential" -> {
        coroutineScope.launch {
          val response = device.removeCredential()

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "device.getChallenge" -> {
        coroutineScope.launch {
          val response = device.getChallenge()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "challengeId" to it.challengeId,
              "userId" to it.userId,
              "actionCode" to it.actionCode,
              "idempotencyKey" to it.idempotencyKey,
              "deviceId" to it.deviceId,
              "userAgent" to it.userAgent,
              "ipAddress" to it.ipAddress
            )

            result.success(data)
          }
        }
      }

      "device.claimChallenge" -> {
        val challengeId = call.argument<String>("challengeId")!!

        coroutineScope.launch {
          val response = device.claimChallenge(challengeId)

          handleResponse(response, result)?.let {
            val data = mapOf(
              "challengeId" to it.challengeId,
              "userId" to it.userId
            )

            result.success(data)
          }
        }
      }

      "device.updateChallenge" -> {
        val challengeId = call.argument<String>("challengeId")!!
        val approved = call.argument<Boolean>("approved")!!
        val verificationCode = call.argument<String>("verificationCode")

        coroutineScope.launch {
          val response = device.updateChallenge(challengeId, approved, verificationCode)

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "device.verify" -> {
        coroutineScope.launch {
          val response = device.verify()

          handleResponse(response, result)?.let {
            val data = mapOf(
              "isVerified" to it.isVerified,
              "token" to it.token,
              "userId" to it.userId,
              "userAuthenticatorId" to it.userAuthenticatorId,
              "username" to it.username,
              "displayName" to it.displayName
            )

            result.success(data)
          }
        }
      }

      "setToken" -> {
        val token = call.argument<String>("token")!!

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

  private fun <T>handleResponse(response: AuthsignalResponse<T>, result: MethodChannel.Result): T? {
    return if (response.error != null) {
      result.error(response.errorCode ?: "unexpected_error", response.error!!, "")

      null
    } else if (response.data == null) {
      result.success(null)

      null
    } else {
      response.data
    }
  }
}
