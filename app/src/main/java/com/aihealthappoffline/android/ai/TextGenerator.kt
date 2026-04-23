package com.aihealthappoffline.android.ai

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.tensorflow.lite.Interpreter
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

class TextGenerator(context: Context) {
    private val aiManager = LocalAIManager(context)
    private var interpreter: Interpreter? = null

    companion object {
        const val MAX_TOKENS = 512
    }

    private var currentModelId: String? = null

    suspend fun loadModel(modelId: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val modelFile = aiManager.getModelFile(modelId) ?: return@withContext false

            if (interpreter != null && currentModelId == modelId) {
                return@withContext true
            }

            interpreter?.close()

            val options = Interpreter.Options().apply {
                numThreads = 4
            }

            interpreter = Interpreter(modelFile, options)
            currentModelId = modelId

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun unloadModel() {
        try {
            interpreter?.close()
            interpreter = null
            currentModelId = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    suspend fun generate(
        prompt: String,
        maxNewTokens: Int = 128,
        temperature: Float = 0.7f
    ): String = withContext(Dispatchers.IO) {
        try {
            if (interpreter == null) {
                return@withContext "Please download and select a model first."
            }

            processPrompt(prompt)
        } catch (e: Exception) {
            "Error generating: ${e.message}"
        }
    }

    private fun processPrompt(prompt: String): String {
        return try {
            val formattedPrompt = "<|system|>You are a health and nutrition assistant. Provide helpful, accurate health advice.\n<|user|>$prompt\n<|assistant|>"

            val inputIds = tokenize(formattedPrompt)
            val inputBuffer = prepareInput(inputIds)

            val outputSize = MAX_TOKENS
            val outputBuffer = Array(1) { FloatArray(outputSize) }

            interpreter?.run(inputBuffer, outputBuffer)

            val result = StringBuilder()
            for (i in 0 until outputSize) {
                val tokenId = outputBuffer[0][i].toInt()
                if (tokenId != 0) {
                    result.append(tokenId.toChar())
                }
            }

            result.toString().ifEmpty { "I've processed your request. The model is working but output was empty." }

        } catch (e: Exception) {
            "I apologize, but I encountered an issue: ${e.message}. Try downloading another model."
        }
    }

    private fun tokenize(text: String): IntArray {
        return text.map { it.code }.toIntArray()
    }

    private fun prepareInput(inputIds: IntArray): ByteBuffer {
        val buffer = ByteBuffer.allocateDirect(inputIds.size * 4)
        buffer.order(ByteOrder.nativeOrder())
        inputIds.forEach { buffer.putInt(it) }
        buffer.flip()
        return buffer
    }

    fun close() {
        unloadModel()
    }
}