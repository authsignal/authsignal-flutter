package com.authsignal.authsignal_flutter

import android.app.Activity
import android.content.Context
import com.authsignal.AuthsignalRequestMetadata
import com.authsignal.DeviceCache
import com.authsignal.TokenCache
import com.authsignal.email.AuthsignalEmail
import com.authsignal.inapp.AuthsignalInApp
import com.authsignal.models.AuthsignalResponse
import com.authsignal.passkey.AuthsignalPasskey
import com.authsignal.push.AuthsignalPush
import com.authsignal.qr.AuthsignalQRCode
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
  private lateinit var qr: AuthsignalQRCode
  private lateinit var inapp: AuthsignalInApp

  private var activity: Activity? = null
  private var context: Context? = null
  private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "authsignal")
    channel.setMethodCallHandler(this)

    context = binding.applicationContext
    DeviceCache.shared.initialize(binding.applicationContext)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when(call.method) {
      "initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!
        val deviceID = call.argument<String>("deviceID")

        AuthsignalRequestMetadata.setWrapperSDK(
          sdk = "flutter",
          version = BuildConfig.VERSION_NAME,
          userAgentToken = "AuthsignalFlutterSDK",
        )

        context?.let {
          DeviceCache.shared.initialize(it, deviceID)
        }

        activity?.let {
          passkey = AuthsignalPasskey(tenantID, baseURL, it, deviceID)
        }

        push = AuthsignalPush(tenantID, baseURL, context = context)
        email = AuthsignalEmail(tenantID, baseURL)
        sms = AuthsignalSMS(tenantID, baseURL)
        totp = AuthsignalTOTP(tenantID, baseURL)
        whatsapp = AuthsignalWhatsApp(tenantID, baseURL)
        qr = AuthsignalQRCode(tenantID, baseURL, context = context)
        inapp = AuthsignalInApp(tenantID, baseURL, context = context)

        result.success(null)
      }

      "getDeviceId" -> {
        coroutineScope.launch {
          val deviceId = DeviceCache.shared.getDefaultDeviceId()
          result.success(deviceId)
        }
      }

      "passkey.signUp" -> {
        val token = call.argument<String>("token")
        val username = call.argument<String>("username")
        val displayName = call.argument<String>("displayName")
        val ignorePasskeyAlreadyExistsError =
          call.argument<Boolean>("ignorePasskeyAlreadyExistsError") ?: false

        coroutineScope.launch {
          val response = passkey.signUp(
            token = token,
            username = username,
            displayName = displayName,
            ignorePasskeyAlreadyExistsError = ignorePasskeyAlreadyExistsError,
          )

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
        val preferImmediatelyAvailableCredentials =
          call.argument<Boolean>("preferImmediatelyAvailableCredentials") ?: true

        coroutineScope.launch {
          val response = passkey.signIn(
            action = action,
            token = token,
            preferImmediatelyAvailableCredentials = preferImmediatelyAvailableCredentials,
          )

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

      "passkey.cancel" -> {
        result.success(null)
      }

      "passkey.shouldPromptToCreatePasskey" -> {
        val username = call.argument<String>("username")

        coroutineScope.launch {
          val response = passkey.shouldPromptToCreatePasskey(username)

          result.success(response.data ?: false)
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

      "passkey.isSupported" -> {
        result.success(if (::passkey.isInitialized) passkey.isSupported() else false)
      }

      "push.getCredential" -> {
        coroutineScope.launch {
          val response = push.getCredential()

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

      "push.addCredential" -> {
        val token = call.argument<String>("token")
        val performAttestation = call.argument<Boolean>("performAttestation") ?: false

        coroutineScope.launch {
          val response = push.addCredential(
            token = token,
            performAttestation = performAttestation,
          )

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

      "qr.getCredential" -> {
        coroutineScope.launch {
          val response = qr.getCredential()

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

      "qr.addCredential" -> {
        val token = call.argument<String>("token")
        val performAttestation = call.argument<Boolean>("performAttestation") ?: false

        coroutineScope.launch {
          val response = qr.addCredential(
            token = token,
            performAttestation = performAttestation,
          )

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

      "qr.removeCredential" -> {
        coroutineScope.launch {
          val response = qr.removeCredential()

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "qr.claimChallenge" -> {
        val challengeId = call.argument<String>("challengeId")!!

        coroutineScope.launch {
          val response = qr.claimChallenge(challengeId)

          handleResponse(response, result)?.let {
            val data = mapOf<String, Any?>(
              "success" to it.success,
              "userAgent" to it.userAgent,
              "ipAddress" to it.ipAddress,
              "actionCode" to it.actionCode,
              "idempotencyKey" to it.idempotencyKey,
            )

            result.success(data)
          }
        }
      }

      "qr.updateChallenge" -> {
        val challengeId = call.argument<String>("challengeId")!!
        val approved = call.argument<Boolean>("approved")!!
        val verificationCode = call.argument<String>("verificationCode")

        coroutineScope.launch {
          val response = qr.updateChallenge(challengeId, approved, verificationCode)

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "inapp.getCredential" -> {
        val username = call.argument<String>("username")

        coroutineScope.launch {
          val response = inapp.getCredential(username = username)

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

      "inapp.addCredential" -> {
        val token = call.argument<String>("token")
        val username = call.argument<String>("username")
        val performAttestation = call.argument<Boolean>("performAttestation") ?: false

        coroutineScope.launch {
          val response = inapp.addCredential(
            token = token,
            username = username,
            performAttestation = performAttestation,
          )

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

      "inapp.removeCredential" -> {
        val username = call.argument<String>("username")

        coroutineScope.launch {
          val response = inapp.removeCredential(username = username)

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "inapp.verify" -> {
        val action = call.argument<String>("action")
        val username = call.argument<String>("username")

        coroutineScope.launch {
          val response = inapp.verify(action = action, username = username)

          handleResponse(response, result)?.let {
            val data = mapOf<String, Any?>(
              "token" to it.token,
              "userId" to it.userId,
              "userAuthenticatorId" to it.userAuthenticatorId,
              "username" to it.username
            )

            result.success(data)
          }
        }
      }

      "inapp.createPin" -> {
        val pin = call.argument<String>("pin")!!
        val username = call.argument<String>("username")!!
        val token = call.argument<String>("token")

        coroutineScope.launch {
          val response = inapp.createPin(pin = pin, username = username, token = token)

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

      "inapp.verifyPin" -> {
        val pin = call.argument<String>("pin")!!
        val username = call.argument<String>("username")!!
        val action = call.argument<String>("action")

        coroutineScope.launch {
          val response = inapp.verifyPin(pin = pin, username = username, action = action)

          handleResponse(response, result)?.let {
            val data = mapOf<String, Any?>(
              "isVerified" to it.isVerified,
              "token" to it.token,
              "userId" to it.userId,
            )

            result.success(data)
          }
        }
      }

      "inapp.deletePin" -> {
        val username = call.argument<String>("username")!!

        coroutineScope.launch {
          val response = inapp.deletePin(username = username)

          handleResponse(response, result)?.let {
            result.success(it)
          }
        }
      }

      "inapp.getAllPinUsernames" -> {
        val response = inapp.getAllPinUsernames()

        if (response.error != null) {
          result.error(response.errorCode ?: "unexpected_error", response.error!!, "")
        } else {
          result.success(response.data ?: emptyList<String>())
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
