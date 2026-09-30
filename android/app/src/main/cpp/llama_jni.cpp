#include <jni.h>
#include <android/log.h>
#include <algorithm>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>
#include "llama.h"

#define LOG_TAG "ZionLLM"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {
std::mutex g_mutex;
llama_model * g_model = nullptr;
llama_context * g_ctx = nullptr;
llama_sampler * g_sampler = nullptr;

void freeLocked() {
    if (g_sampler) { llama_sampler_free(g_sampler); g_sampler = nullptr; }
    if (g_ctx) { llama_free(g_ctx); g_ctx = nullptr; }
    if (g_model) { llama_model_free(g_model); g_model = nullptr; }
}

std::string fail(const char * message) { LOGE("%s", message); return std::string("ERROR: ") + message; }
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_zion_os_ai_LlamaBridge_nativeLoadModel(JNIEnv * env, jobject, jstring modelPath, jint threads) {
    if (!modelPath) return JNI_FALSE;
    const char * path = env->GetStringUTFChars(modelPath, nullptr);
    std::lock_guard<std::mutex> lock(g_mutex);
    freeLocked();
    llama_backend_init();

    auto params = llama_model_default_params();
    params.n_gpu_layers = 0;
    params.load_mode = LLAMA_LOAD_MODE_MMAP;
    g_model = llama_model_load_from_file(path, params);
    env->ReleaseStringUTFChars(modelPath, path);
    if (!g_model) return JNI_FALSE;

    auto ctxParams = llama_context_default_params();
    ctxParams.n_ctx = 4096;
    ctxParams.n_batch = 512;
    ctxParams.n_ubatch = 512;
    ctxParams.n_seq_max = 1;
    ctxParams.n_threads = std::max(1, static_cast<int>(threads));
    ctxParams.n_threads_batch = std::max(1, static_cast<int>(threads));
    g_ctx = llama_init_from_model(g_model, ctxParams);
    if (!g_ctx) { freeLocked(); return JNI_FALSE; }

    auto samplerParams = llama_sampler_chain_default_params();
    g_sampler = llama_sampler_chain_init(samplerParams);
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(0.95f, 1));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_zion_os_ai_LlamaBridge_nativeGenerate(JNIEnv * env, jobject, jstring prompt, jint maxTokens, jfloat temperature) {
    if (!prompt) return env->NewStringUTF("ERROR: Empty prompt");
    const char * text = env->GetStringUTFChars(prompt, nullptr);
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_model || !g_ctx || !g_sampler) {
        env->ReleaseStringUTFChars(prompt, text);
        return env->NewStringUTF("ERROR: Model not loaded");
    }

    llama_memory_clear(llama_get_memory(g_ctx), true);
    llama_sampler_reset(g_sampler);

    const auto * vocab = llama_model_get_vocab(g_model);
    const int32_t textLen = static_cast<int32_t>(strlen(text));
    int32_t capacity = std::max(256, textLen + 128);
    std::vector<llama_token> tokens(capacity);
    int32_t nTokens = llama_tokenize(vocab, text, textLen, tokens.data(), capacity, true, false);
    if (nTokens < 0) {
        capacity = -nTokens;
        tokens.resize(capacity);
        nTokens = llama_tokenize(vocab, text, textLen, tokens.data(), capacity, true, false);
    }
    env->ReleaseStringUTFChars(prompt, text);
    if (nTokens <= 0) return env->NewStringUTF("ERROR: Tokenization failed");
    tokens.resize(nTokens);

    const uint32_t nCtx = llama_n_ctx(g_ctx);
    if (tokens.size() >= nCtx - 8) return env->NewStringUTF("ERROR: Prompt exceeds local context window");

    if (temperature > 0.0f) {
        llama_sampler_free(g_sampler);
        auto samplerParams = llama_sampler_chain_default_params();
        g_sampler = llama_sampler_chain_init(samplerParams);
        llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(40));
        llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(0.95f, 1));
        llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(temperature));
        llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    }

    auto batch = llama_batch_get_one(tokens.data(), static_cast<int32_t>(tokens.size()));
    if (llama_decode(g_ctx, batch) != 0) return env->NewStringUTF("ERROR: Prompt decode failed");

    std::string output;
    const int limit = std::clamp(static_cast<int>(maxTokens), 1, 2048);

    for (int i = 0; i < limit; ++i) {
        const llama_token next = llama_sampler_sample(g_sampler, g_ctx, -1);
        if (llama_vocab_is_eog(vocab, next)) break;

        char piece[1024];
        const int32_t n = llama_token_to_piece(vocab, next, piece, sizeof(piece), 0, true);
        if (n > 0) output.append(piece, n);

        llama_sampler_accept(g_sampler, next);
        auto nextBatch = llama_batch_get_one(&next, 1);
        if (llama_decode(g_ctx, nextBatch) != 0) break;
    }
    return env->NewStringUTF(output.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_zion_os_ai_LlamaBridge_nativeFreeModel(JNIEnv *, jobject) {
    std::lock_guard<std::mutex> lock(g_mutex);
    freeLocked();
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_zion_os_ai_LlamaBridge_nativeIsLoaded(JNIEnv *, jobject) {
    std::lock_guard<std::mutex> lock(g_mutex);
    return g_model != nullptr && g_ctx != nullptr;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_zion_os_ai_LlamaBridge_nativeVersion(JNIEnv * env, jobject) {
    return env->NewStringUTF(llama_version());
}
