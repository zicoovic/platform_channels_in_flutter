package com.example.platform_channels_in_flutter

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager

/// ShakeDetector - Detects phone shake using accelerometer data
/// Implements SensorEventListener to receive continuous accelerometer updates
/// When significant acceleration is detected, calls the onShake callback
class ShakeDetector(private val onShake: () -> Unit) : SensorEventListener {
    /// Tracks the last time a shake was detected (prevents duplicate triggers)
    private var lastShakeTime = 0L

    /// Acceleration threshold to detect a shake (in m/s²)
    /// Value of 15 means significant shake is required
    private val SHAKE_THRESHOLD = 15f

    /// Minimum time between shake events (milliseconds)
    /// Prevents rapid multiple shake triggers from the same motion
    private val SHAKE_INTERVAL = 500L

    /// Called when accelerometer data changes
    /// Receives X, Y, Z acceleration values from the sensor
    /// Called when phone movement is detected
    /// Checks if movement is strong enough to count as a shake
    override fun onSensorChanged(event: SensorEvent) {
        /// Only look at accelerometer data
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            /// Get movement in 3 directions (X, Y, Z)
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            /// Calculate total movement strength
            val acceleration = Math.sqrt((x * x + y * y + z * z).toDouble()).toFloat()

            /// If movement is strong enough, it's a shake
            if (acceleration > SHAKE_THRESHOLD) {
                val currentTime = System.currentTimeMillis()

                /// Only trigger if enough time passed since last shake
                /// This prevents counting one shake as multiple shakes
                if (currentTime - lastShakeTime > SHAKE_INTERVAL) {
                    lastShakeTime = currentTime
                    onShake() // Notify that shake happened
                }
            }
        }
    }

    /// Handles sensor accuracy changes notification
    /// Required implementation of SensorEventListener interface
    /// No action required for shake detection use case
    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        // Sensor accuracy changes do not affect shake detection logic
    }
}
