export interface BeatDetectorConfig {
  threshold: number;
  minInterval: number;
  decayRate: number;
}

export class BeatDetector {
  private energyHistory: number[] = [];
  private lastBeatTime: number = -1;
  private averageEnergy: number = 0;
  private readonly config: BeatDetectorConfig;

  constructor(config: Partial<BeatDetectorConfig> = {}) {
    this.config = {
      threshold: 1.3,
      minInterval: 0.1,
      decayRate: 0.98,
      ...config
    };
  }

  detectBeat(energy: number, currentTime: number): boolean {
    this.energyHistory.push(energy);
    
    if (this.energyHistory.length > 43) {
      this.energyHistory.shift();
    }

    if (this.energyHistory.length < 43) {
      this.updateAverageEnergy();
      return false;
    }

    this.updateAverageEnergy();
    
    const recentAverage = this.energyHistory.slice(-43).reduce((sum, e) => sum + e, 0) / 43;
    const isAboveThreshold = energy > recentAverage * this.config.threshold;
    const timeSinceLastBeat = currentTime - this.lastBeatTime;
    const isMinIntervalPassed = timeSinceLastBeat >= this.config.minInterval;

    if (isAboveThreshold && isMinIntervalPassed) {
      this.lastBeatTime = currentTime;
      return true;
    }

    return false;
  }

  private updateAverageEnergy(): void {
    if (this.energyHistory.length === 0) return;
    
    const sum = this.energyHistory.reduce((acc, val) => acc + val, 0);
    this.averageEnergy = sum / this.energyHistory.length;
  }

  reset(): void {
    this.energyHistory = [];
    this.lastBeatTime = -1;
    this.averageEnergy = 0;
  }

  getAverageEnergy(): number {
    return this.averageEnergy;
  }

  setThreshold(threshold: number): void {
    this.config.threshold = threshold;
  }

  setMinInterval(interval: number): void {
    this.config.minInterval = interval;
  }
}
