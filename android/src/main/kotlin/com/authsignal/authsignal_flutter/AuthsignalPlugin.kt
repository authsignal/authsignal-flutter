package com.authsignal.authsignal_flutter

import android.app.Activity
import android.content.Context
import com.authsignal.passkey.AuthsignalPasskey
import com.authsignal.push.AuthsignalPush
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
        val token = call.argument<String>("token")!!
        val userName = call.argument<String>("userName")!!

        passkey.signUpAsync(token, userName).thenApply {
          result.success(it)
        }
      }

      "passkey.signIn" -> {
        val token = call.argument<String>("token")

        passkey.signInAsync(token).thenApply {
          result.success(it)
        }
      }

      "push.initialize" -> {
        val tenantID = call.argument<String>("tenantID")!!
        val baseURL = call.argument<String>("baseURL")!!

        push = AuthsignalPush(tenantID, baseURL)

        result.success(null)
      }

      "push.getCredential" -> {
        push.getCredentialAsync().thenApply {
          result.success(it)
        }
      }

      "push.addCredential" -> {
        val token = call.argument<String>("token")!!

        push.addCredentialAsync(token).thenApply {
          result.success(it)
        }
      }

      "push.removeCredential" -> {
        push.removeCredentialAsync().thenApply {
          result.success(it)
        }
      }

      "push.getChallenge" -> {
        push.getChallengeAsync().thenApply {
          result.success(it)
        }
      }

      "push.updateChallenge" -> {
        val challengeId = call.argument<String>("challengeId")!!
        val approved = call.argument<Boolean>("approved")!!
        val verificationCode = call.argument<String>("verificationCode")

        push.updateChallengeAsync(challengeId, approved, verificationCode).thenApply {
          result.success(it)
        }
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
