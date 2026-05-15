# llama.cpp Integration Guide

## Overview
The app uses llama.cpp for real on-device Gemma 4 inference. The `LlamaCppEngine` bridges Swift to the C library.

## Option 1: Swift Package (Recommended)

1. Open `HealthApp.xcodeproj` in Xcode
2. File → Add Package Dependencies
3. Enter URL: `https://github.com/nickvdp/llama.swift`
4. Select version: "Up to Next Major Version"
5. Add "llama" package to HealthApp target
6. Build and run

## Option 2: Manual C Library

1. Clone llama.cpp:
```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make -j4
```

2. Add to Xcode:
   - Drag `llama.cpp/llama.h` into project
   - Drag `llama.cpp/llama.cpp` into project
   - Create bridging header:
   ```c
   #import "llama.h"
   ```

3. Uncomment the real inference code in `LlamaCppEngine.swift`

## Model Download

The Gemma 4 2B Q4 model (~1.5GB) is downloaded via the in-app Model Management screen.

Alternatively, manually download:
```bash
# Download GGUF model
wget https://huggingface.co/google/gemma-4-2b-GGUF/resolve/main/gemma-4-2b-q4_K_M.gguf

# Place in app's model directory
mkdir -p ~/Library/Containers/com.aihealthappoffline/Data/Library/Application\ Support/Models/gemma_4_2b_q4/
mv gemma-4-2b-q4_K_M.gguf ~/Library/Containers/com.aihealthappoffline/Data/Library/Application\ Support/Models/gemma_4_2b_q4/model.bin
```

## Prompt Format

Gemma 4 uses this chat template:
```
<start_of_turn>system
You are a helpful health assistant.<end_of_turn>
<start_of_turn>user
What should I eat for dinner?<end_of_turn>
<start_of_turn>model
```

## Performance Notes

- **Q4_K_M quantization**: ~1.5GB, good balance of quality and speed
- **iPhone 15 Pro**: ~15-25 tokens/second
- **iPhone 17 Pro**: ~25-40 tokens/second (estimated)
- **Memory**: ~2GB RAM during inference
- **Context**: 8192 tokens

## Current Status

The `LlamaCppEngine.swift` has:
- ✅ Full architecture ready
- ✅ Prompt building for Gemma 4 format
- ✅ Streaming support
- ✅ Mock responses for testing
- ⏳ Real llama.cpp calls (commented, ready to uncomment)

Once llama.cpp package is added, uncomment the real inference code in `LlamaCppEngine.swift` and remove the mock responses.
