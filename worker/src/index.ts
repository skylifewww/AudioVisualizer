import { DSPProcessor } from './dsp';
import { BeatDetector } from './beat';
import { UDPSender } from './udpSender';
import { collectFrames } from './frameCollector';
import { writeVisualFile } from './visualEncoder';

const TARGET_FPS = 60;
const FRAME_INTERVAL = 1000 / TARGET_FPS;

class AudioVisualizer {
  private dsp: DSPProcessor;
  private beatDetector: BeatDetector;
  private udpSender: UDPSender;
  private isRunning: boolean = false;
  private startTime: number = 0;

  constructor() {
    this.dsp = new DSPProcessor();
    this.beatDetector = new BeatDetector({
      threshold: 1.3,
      minInterval: 0.1,
      decayRate: 0.98
    });
    this.udpSender = new UDPSender('192.168.4.1', 7777);
  }

  async start(wavFilePath: string): Promise<void> {
    try {
      console.log('Starting AudioVisualizer...');
      
      await this.dsp.loadAudioFile(wavFilePath);
      this.isRunning = true;
      this.startTime = Date.now();

      console.log(`Processing at ${TARGET_FPS} FPS...`);
      await this.processLoop();
      
    } catch (error) {
      console.error('Failed to start AudioVisualizer:', error);
      this.stop();
    }
  }

  private async processLoop(): Promise<void> {
    let frameCount = 0;
    const targetFrameTime = FRAME_INTERVAL;

    while (this.isRunning) {
      const frameStartTime = Date.now();

      const frame = this.dsp.processFrame();
      
      if (!frame) {
        console.log('Audio processing complete.');
        break;
      }

      const currentTime = (Date.now() - this.startTime) / 1000;
      const beat = this.beatDetector.detectBeat(frame.energy, currentTime);

      try {
        await this.udpSender.sendPacket(frame.bars, beat);
        frameCount++;

        if (frameCount % TARGET_FPS === 0) {
          const elapsed = (Date.now() - this.startTime) / 1000;
          console.log(`Processed ${frameCount} frames in ${elapsed.toFixed(2)}s (${(frameCount / elapsed).toFixed(1)} FPS)`);
        }
      } catch (udpError) {
        console.error('UDP send failed:', udpError);
      }

      const frameProcessingTime = Date.now() - frameStartTime;
      const remainingTime = targetFrameTime - frameProcessingTime;

      if (remainingTime > 0) {
        await this.sleep(remainingTime);
      }
    }

    console.log(`Total frames processed: ${frameCount}`);
    this.stop();
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  stop(): void {
    this.isRunning = false;
    this.udpSender.close();
    console.log('AudioVisualizer stopped.');
  }

  reset(): void {
    this.dsp.reset();
    this.beatDetector.reset();
    this.udpSender.resetFrameCounter();
    this.startTime = Date.now();
  }
}

async function runPreprocess(audioFilePath: string): Promise<void> {
  console.log('Preprocess mode - generating .visual file...');
  console.log(`Audio file: ${audioFilePath}`);
  
  try {
    const dsp = new DSPProcessor();
    const beatDetector = new BeatDetector({
      threshold: 1.3,
      minInterval: 0.1,
      decayRate: 0.98
    });
    
    await dsp.loadAudioFile(audioFilePath);
    
    // Collect all frames deterministically
    const collectedData = collectFrames(dsp, beatDetector);
    
    // Generate binary .visual file
    const outputPath = audioFilePath.replace(/\.[^/.]+$/, '') + '.visual';
    writeVisualFile(outputPath, collectedData.fps, collectedData.durationMs, collectedData.frames);
    
  } catch (error) {
    console.error('Preprocess failed:', error);
    process.exit(1);
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error('Usage:');
    console.error('  npm run dev <audio-file>     - UDP streaming mode');
    console.error('  npm run preprocess <file>   - Generate .visual file');
    process.exit(1);
  }

  const mode = args[0];
  const filePath = args[1];
  
  if (!filePath) {
    console.error(`Error: Missing file path for ${mode} mode`);
    process.exit(1);
  }
  
  if (!require('fs').existsSync(filePath)) {
    console.error(`Error: File not found: ${filePath}`);
    process.exit(1);
  }

  if (mode === 'preprocess') {
    await runPreprocess(filePath);
  } else {
    // Default UDP streaming mode
    const visualizer = new AudioVisualizer();

    process.on('SIGINT', () => {
      console.log('\nReceived SIGINT, stopping...');
      visualizer.stop();
      process.exit(0);
    });

    process.on('SIGTERM', () => {
      console.log('\nReceived SIGTERM, stopping...');
      visualizer.stop();
      process.exit(0);
    });

    await visualizer.start(filePath);
  }
}

if (require.main === module) {
  main().catch(error => {
    console.error('Application error:', error);
    process.exit(1);
  });
}

export { AudioVisualizer };
export { runPreprocess };
