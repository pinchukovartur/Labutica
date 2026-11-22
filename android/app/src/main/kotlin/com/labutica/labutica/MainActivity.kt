package com.labutica.labutica

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var gameSounds: SoundPool? = null
    private val loadedSamples = mutableSetOf<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val pool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .build()
        gameSounds = pool
        pool.setOnLoadCompleteListener { loadedPool, sampleId, status ->
            if (loadedPool === gameSounds && status == 0) {
                loadedSamples.add(sampleId)
            }
        }
        val samples = mapOf(
            "playSuccess" to pool.load(this, R.raw.task_success, 1),
            "playStickerReward" to pool.load(this, R.raw.sticker_reward, 1)
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "labutica/task_audio")
            .setMethodCallHandler { call, result ->
                val sample = samples[call.method]
                if (sample == null) {
                    result.notImplemented()
                } else {
                    if (sample in loadedSamples) pool.play(sample, 1f, 1f, 1, 0, 1f)
                    result.success(null)
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "labutica/task_audio")
            .setMethodCallHandler(null)
        gameSounds?.release()
        gameSounds = null
        loadedSamples.clear()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
