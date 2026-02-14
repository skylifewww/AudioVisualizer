import { DSPProcessor } from './dsp';
import { BeatDetector } from './beat';

export interface CollectedFrame {
  bars: number[];
  beat: number;
}

export interface CollectedData {
  fps: number;
  durationMs: number;
  frames: CollectedFrame[];
}

export function collectFrames(dsp: DSPProcessor, beatDetector: BeatDetector): CollectedData {
  // Reset processors
  dsp.reset();
  beatDetector.reset();

  const frames: CollectedFrame[] = [];
  let frameIndex = 0;

  // Get actual DSP parameters
  const sampleRate = dsp.getSampleRate();
  const hopSize = dsp.getHopSize();

  // Calculate FPS
  const fps = sampleRate / hopSize;

  console.log(`Collecting frames at ${fps.toFixed(2)} FPS...`);
  console.log(`Sample rate: ${sampleRate}Hz, Hop size: ${hopSize}`);

  // Process all frames
  while (!dsp.isComplete()) {
    const frame = dsp.processFrame();
    if (!frame) break;

    // Compute time deterministically
    const timeSeconds = frameIndex * (hopSize / sampleRate);

    // Detect beat
    const beat = beatDetector.detectBeat(frame.energy, timeSeconds) ? 1 : 0;

    // Store frame data
    frames.push({
      bars: frame.bars,
      beat: beat
    });

    frameIndex++;

    // Progress reporting
    if (frameIndex % 1000 === 0) {
      console.log(`Collected ${frameIndex} frames...`);
    }
  }

  // Calculate duration in milliseconds
  const durationMs = (frameIndex / fps) * 1000;

  console.log(`Collection complete: ${frames.length} frames, ${durationMs.toFixed(2)}ms duration`);

  return {
    fps: fps,
    durationMs: durationMs,
    frames: frames
  };
}
