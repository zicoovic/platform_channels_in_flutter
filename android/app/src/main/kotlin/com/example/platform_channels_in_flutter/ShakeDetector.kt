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
    override fun onSensorChanged(event: SensorEvent) {
        /// Only process accelerometer sensor data
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            // Get acceleration values on all 3 axes
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            // Calculate the magnitude of acceleration using Pythagorean theorem
            // This gives the total acceleration regardless of direction
            val acceleration = Math.sqrt((x * x + y * y + z * z).toDouble()).toFloat()

            /// Check if acceleration exceeds the shake threshold
            if (acceleration > SHAKE_THRESHOLD) {
                val currentTime = System.currentTimeMillis()

                /// Only trigger shake callback if enough time has passed since last shake
                /// This prevents multiple events from a single shake motion
                if (currentTime - lastShakeTime > SHAKE_INTERVAL) {
                    lastShakeTime = currentTime
                    onShake() // Execute the callback function
                }
            }
        }
    }

    /// Called when sensor accuracy changes (usually not needed)
    /// This is a required override but we don't need to do anything here
    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        // No action needed for this app
    }
}
