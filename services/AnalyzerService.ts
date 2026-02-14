import { DSPProcessor } from '../src/dsp';
import { BeatDetector } from '../src/beat';
import { collectFrames } from '../src/frameCollector';
import { writeVisualFile } from '../src/visualEncoder';
import { config } from '../config/config';

export interface AnalyzeResult {
  success: boolean;
  visualUrl?: string;
  metaUrl?: string;
  error?: string;
}

export class AnalyzerService {
  async analyzeAudio(inputPath: string): Promise<AnalyzeResult> {
    try {
      const dsp = new DSPProcessor();
      const beatDetector = new BeatDetector({
        threshold: 1.3,
        minInterval: 0.1,
        decayRate: 0.98
      });

      await dsp.loadAudioFile(inputPath);
      const collectedData = collectFrames(dsp, beatDetector);

      // Generate output path
      const outputFileName = inputPath.replace(/\.[^/.]+$/, '');
      const visualPath = `${config.visualOutputDir}/${outputFileName.split('/').pop()}.visual`;

      writeVisualFile(visualPath, collectedData.fps, collectedData.durationMs, collectedData.frames);

      return {
        success: true,
        visualUrl: `/files/${outputFileName.split('/').pop()}.visual`,
        metaUrl: `/files/${outputFileName.split('/').pop()}.visual.meta.json` 
      };
    } catch (error) {
      console.error('AnalyzerService error:', error);
      return {
        success: false,
        error: (error as Error).message || 'Unknown error'
      };
    }
  }
}
