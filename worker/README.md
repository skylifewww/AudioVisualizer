# AudioVisualizer Worker

A Node.js TypeScript application that processes audio files (WAV, MP3, FLAC, OGG) and sends real-time visualization data via UDP.

## Features

- **Universal Audio Support**: Reads WAV, MP3, FLAC, OGG files via audio-decode
- **Audio Processing**: Performs FFT analysis on decoded audio
- **Frequency Bands**: Converts audio spectrum to 32 logarithmic frequency bands
- **Beat Detection**: Energy-based beat detection algorithm
- **UDP Streaming**: Sends visualization data at 60 FPS to target device
- **TypeScript**: Full TypeScript support with strict typing

## Installation

```bash
cd worker
npm install
```

## Usage

```bash
# UDP streaming mode (real-time)
npm run dev <audio-file>

# Example with MP3
npm run dev ./audio/sample.mp3

# Preprocess mode (generate .visual file)
npm run preprocess <audio-file>

# Example: generate visualization data
npm run preprocess ./audio/sample.mp3

# Build for production
npm run build
```

## Modes

### UDP Streaming Mode
- Processes audio in real-time at 60 FPS
- Sends UDP packets to 192.168.4.1:7777
- Ideal for live visualization

### Preprocess Mode
- Generates `.visual` binary file with all frames
- Creates `.visual.meta.json` metadata file alongside
- Compact binary format for efficient storage
- Contains header metadata and frame data
- Useful for offline processing or debugging

#### Metadata Format
```json
{
  "durationSeconds": 182.3,
  "fps": 86,
  "bands": 32,
  "version": 1,
  "compact": true,
  "totalFrames": 15678
}
```

#### Binary Format
```
Header (20 bytes):
- uint32 version (little-endian) - Always 1
- uint32 isCompact (little-endian) - 0 = float32 bars, 1 = uint8 bars
- uint32 fps (little-endian)
- uint32 totalFrames (little-endian) 
- uint32 durationMs (little-endian)

Frame (33 or 129 bytes each):
Compact mode (33 bytes):
- 32 × uint8 bars (0-255, scaled from 0-1)
- 1 × uint8 beat (0 or 1)

Full precision mode (129 bytes):
- 32 × float32 bars (little-endian)
- 1 × uint8 beat (0 or 1)

Footer (4 bytes):
- uint32 CRC32 checksum (little-endian) - Covers all data except checksum
```

## Supported Formats

- **WAV** - Uncompressed audio
- **MP3** - Compressed audio
- **FLAC** - Lossless compressed audio
- **OGG** - Open source compressed audio

## Output Format

The application sends UDP packets containing:

```typescript
{
  frame: number,      // Frame counter
  bars: number[32],   // 32 normalized frequency bands (0-1)
  beat: boolean       // Beat detection flag
}
```

## Target Configuration

- **IP**: 192.168.4.1
- **Port**: 7777
- **Frame Rate**: 60 FPS

## Architecture

- `dsp.ts` - Audio processing and FFT analysis
- `beat.ts` - Beat detection algorithm
- `udpSender.ts` - UDP communication
- `index.ts` - Main application entry point

## Dependencies

- `audio-decode` - Universal audio decoder (supports WAV, MP3, FLAC, OGG)
- `fft-js` - Fast Fourier Transform implementation
- `@types/node` - Node.js TypeScript definitions
