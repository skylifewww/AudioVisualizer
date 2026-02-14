import * as fs from 'fs';
import decodeAudio from 'audio-decode';
// @ts-ignore
import * as fft from 'fft-js';

export async function loadAudio(filePath: string): Promise<{ samples: Float32Array; sampleRate: number }> {
  const buffer = fs.readFileSync(filePath);
  const audioData = await decodeAudio(buffer);

  const { numberOfChannels, length, sampleRate } = audioData;

  // If mono, return directly
  if (numberOfChannels === 1) {
    return {
      samples: new Float32Array(audioData.getChannelData(0)),
      sampleRate: sampleRate
    };
  }

  // Proper downmix for stereo or multi-channel
  const mono = new Float32Array(length);

  for (let ch = 0; ch < numberOfChannels; ch++) {
    const channelData = audioData.getChannelData(ch);
    for (let i = 0; i < length; i++) {
      mono[i] += channelData[i];
    }
  }

  // Average channels to prevent clipping
  for (let i = 0; i < length; i++) {
    mono[i] /= numberOfChannels;
  }

  return {
    samples: mono,
    sampleRate: sampleRate
  };
}

export interface AudioData {
  samples: Float32Array;
  sampleRate: number;
}

export interface ProcessedFrame {
  bars: number[];
  energy: number;
}

export class DSPProcessor {
  private audioData: AudioData | null = null;
  private readonly fftSize: number = 1024;
  private readonly hopSize: number = 512;
  private readonly numBands: number = 32;
  private currentPosition: number = 0;
  private peakValue: number = 1;
  private previousBars: number[] | null = null;
  private smoothingFactor: number = 0.7;

  constructor() {}

  async loadAudioFile(filePath: string): Promise<void> {
    try {
      const audioData = await loadAudio(filePath);
      this.audioData = {
        samples: audioData.samples,
        sampleRate: audioData.sampleRate
      };
      this.currentPosition = 0;
      console.log(`Loaded audio file: ${filePath}`);
      console.log(`Sample rate: ${this.audioData.sampleRate}Hz`);
      console.log(`Duration: ${this.audioData.samples.length / this.audioData.sampleRate}s`);
    } catch (error) {
      throw new Error(`Failed to load audio file: ${error}`);
    }
  }

  private applyWindow(samples: Float32Array): Float32Array {
    const windowed = new Float32Array(samples.length);
    for (let i = 0; i < samples.length; i++) {
      const hann = 0.5 * (1 - Math.cos((2 * Math.PI * i) / (samples.length - 1)));
      windowed[i] = samples[i] * hann;
    }
    return windowed;
  }

  private frequencyToBin(frequency: number, sampleRate: number, fftSize: number): number {
    return Math.floor((frequency * fftSize) / sampleRate);
  }

  private logScale(index: number, totalBands: number): number {
    const minFreq = 20;
    const maxFreq = 20000;
    const logMin = Math.log(minFreq);
    const logMax = Math.log(maxFreq);
    const logRange = logMax - logMin;
    return Math.exp(logMin + (index / totalBands) * logRange);
  }

  processFrame(): ProcessedFrame | null {
    if (!this.audioData || this.currentPosition + this.fftSize > this.audioData.samples.length) {
      return null;
    }

    const frame = this.audioData.samples.slice(this.currentPosition, this.currentPosition + this.fftSize);
    this.currentPosition += this.hopSize;

    const windowed = this.applyWindow(frame);
    const fftResult = ((fft as any).fft as any)(windowed);
    const magnitudes = fftResult.map((complex: [number, number], i: number) => {
      const real = complex[0];
      const imag = complex[1];
      return Math.sqrt(real * real + imag * imag);
    });

    const bars = new Array(this.numBands).fill(0);
    let totalEnergy = 0;

    for (let band = 0; band < this.numBands; band++) {
      const startFreq = this.logScale(band, this.numBands);
      const endFreq = this.logScale(band + 1, this.numBands);
      
      const startBin = this.frequencyToBin(startFreq, this.audioData!.sampleRate, this.fftSize);
      const endBin = this.frequencyToBin(endFreq, this.audioData!.sampleRate, this.fftSize);
      
      let bandEnergy = 0;
      let binCount = 0;
      
      for (let bin = startBin; bin <= endBin && bin < magnitudes.length; bin++) {
        bandEnergy += magnitudes[bin];
        binCount++;
      }
      
      if (binCount > 0) {
        bandEnergy /= binCount;
      }
      
      // Update peak value if this band is higher
      if (bandEnergy > this.peakValue) {
        this.peakValue = bandEnergy;
      }
      
      bars[band] = bandEnergy;
      totalEnergy += bandEnergy;
    }

    const normalizedBars = bars.map(value => {
      const logValue = Math.log10(value + 1);
      const normalized = logValue / Math.log10(this.peakValue + 1);
      return Math.min(1, Math.max(0, normalized));
    });

    // Apply smoothing
    let smoothedBars: number[];
    if (this.previousBars !== null) {
      smoothedBars = normalizedBars.map((current, index) => {
        const prev = this.previousBars![index];
        return prev * this.smoothingFactor + current * (1 - this.smoothingFactor);
      });
    } else {
      smoothedBars = [...normalizedBars];
    }

    // Store current bars for next frame
    this.previousBars = [...smoothedBars];

    return {
      bars: smoothedBars,
      energy: totalEnergy / this.numBands
    };
  }

  getHopSize(): number {
    return this.hopSize;
  }

  getSampleRate(): number {
    return this.audioData?.sampleRate ?? 44100;
  }

  getFFTSize(): number {
    return this.fftSize;
  }

  reset(): void {
    this.currentPosition = 0;
    this.peakValue = 1;
    this.previousBars = null;
  }

  isComplete(): boolean {
    return !this.audioData || this.currentPosition + this.fftSize >= this.audioData.samples.length;
  }
}
