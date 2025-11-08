package com.example.platform_channels_in_flutter

import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/// MainActivity - Main Android Activity for the Flutter app
/// Handles native-to-Flutter communication using EventChannel
/// Manages shake detection through SensorManager
class MainActivity : FlutterActivity() {
    /// EventChannel name for sending shake events to Flutter
    private val shakeEventChannel = "com.example/shake_events"

    /// MethodChannel name for start/stop control from Flutter
    private val shakeControlChannel = "com.example/shake_control"

    /// Instance of ShakeDetector (created on first use)
    private var shakeDetector: ShakeDetector? = null

    /// Android SensorManager for accessing accelerometer
    private var sensorManager: SensorManager? = null

    /// EventSink to send shake events to Flutter app
    private var eventSink: EventChannel.EventSink? = null

    /// configureFlutterEngine - Called when Flutter engine is ready
    /// Sets up communication channels between Flutter and Android
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        /// Get the SensorManager service from Android
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager

        /// Setup EventChannel - Sends shake events from Android to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, shakeEventChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                /// onListen - Called when Flutter starts listening for shake events
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startShakeDetection() // Start monitoring accelerometer
                }

                /// onCancel - Called when Flutter stops listening
                override fun onCancel(arguments: Any?) {
                    stopShakeDetection() // Stop monitoring accelerometer
                    eventSink = null
                }
            })

        /// Setup MethodChannel - For optional manual control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shakeControlChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListen" -> {
                        startShakeDetection()
                        result.success(null)
                    }
                    "stopListen" -> {
                        stopShakeDetection()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// startShakeDetection - Begins monitoring accelerometer for shake events
    /// Creates ShakeDetector if not exists, then registers it with SensorManager
    private fun startShakeDetection() {
        /// Create ShakeDetector only once
        if (shakeDetector == null) {
            shakeDetector = ShakeDetector {
                /// When shake is detected, send timestamp to Flutter
                eventSink?.success(System.currentTimeMillis())
            }
        }

        /// Get the accelerometer sensor
        val accelerometer = sensorManager?.getDefaultSensor(android.hardware.Sensor.TYPE_ACCELEROMETER)

        /// Register the detector to receive accelerometer events
        accelerometer?.let {
            sensorManager?.registerListener(shakeDetector, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    /// stopShakeDetection - Stops monitoring accelerometer
    /// Unregisters the detector to save battery and resources
    private fun stopShakeDetection() {
        shakeDetector?.let {
            sensorManager?.unregisterListener(it)
        }
    }

    /// onPause - Called when app goes to background
    /// Stop monitoring to save battery
    override fun onPause() {
        super.onPause()
        stopShakeDetection()
    }

    /// onResume - Called when app comes back to foreground
    /// Resume monitoring
    override fun onResume() {
        super.onResume()
        startShakeDetection()
    }
}
