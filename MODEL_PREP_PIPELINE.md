# Model Preparation Pipeline

## Purpose

This pipeline converts approved source model checkpoints into the runtime format the iOS app expects. The app **never** performs training, conversion, or heavy transforms on device.

## Pipeline Steps

### 1. Download Source Weights
```bash
# Example for Qwen 3.5 0.8B
huggingface-cli download Qwen/Qwen3.5-0.8B --local-dir ./source_weights/qwen3_5_0_8b
```

### 2. Convert to Runtime Format

**For llama.cpp:**
```bash
python convert_hf_to_gguf.py ./source_weights/qwen3_5_0_8b --outfile ./converted/qwen3_5_0_8b.gguf
```

**For MLX:**
```bash
python -m mlx_lm.convert --hf-path Qwen/Qwen3.5-0.8B --mlx-path ./converted/qwen3_5_0_8b_mlx
```

### 3. Quantize

```bash
# Q4 quantization (recommended for mobile)
./quantize ./converted/qwen3_5_0_8b.gguf ./quantized/qwen3_5_0_8b_q4.gguf q4_K_M
```

### 4. Generate Manifest

Create `manifest.json`:
```json
{
  "id": "qwen3_5_0_8b_local_q4",
  "display_name": "Qwen3.5 0.8B Local",
  "runtime": "custom_local",
  "version": "1.0.0",
  "quantization": "q4",
  "file_size_bytes": 500000000,
  "checksum_sha256": "<computed_sha256>",
  "supports_vision": false,
  "supports_tool_calling": false,
  "context_window": 8192,
  "min_ios_version": "18.0",
  "download_url": "https://your-cdn.com/models/qwen3_5_0_8b_q4.gguf",
  "license": "Apache-2.0"
}
```

### 5. Generate Checksum

```bash
shasum -a 256 ./quantized/qwen3_5_0_8b_q4.gguf
```

### 6. Smoke Tests

```bash
# Run inference test
./test_inference --model ./quantized/qwen3_5_0_8b_q4.gguf \
    --prompt "What is the calorie count of 2 roti?" \
    --max-tokens 100
```

Verify:
- Model loads without errors
- Inference produces coherent output
- Response time < 5s for 100 tokens
- Memory usage < 1GB

### 7. Publish Versioned Artifacts

Upload to CDN/storage:
```
/models/
  qwen3_5_0_8b_local_q4/
    v1.0.0/
      model.gguf
      manifest.json
```

## Supported Source Models

| Model | Parameters | Quantized Size | Languages |
|-------|-----------|----------------|-----------|
| Qwen 3.5 0.8B | 0.8B | ~500MB (Q4) | 201 |

## Quality Assurance

Before releasing any model artifact:
- [ ] Checksum matches manifest
- [ ] Inference produces valid output on test prompts
- [ ] Memory footprint is acceptable for target devices
- [ ] Response latency meets SLA (< 5s TTFT)
- [ ] No regressions from previous version
