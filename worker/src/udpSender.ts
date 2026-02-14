import * as dgram from 'dgram';

export interface UDPPacket {
  frame: number;
  bars: number[];
  beat: boolean;
}

export class UDPSender {
  private client: dgram.Socket;
  private readonly targetHost: string;
  private readonly targetPort: number;
  private frameCounter: number = 0;

  constructor(host: string = '192.168.4.1', port: number = 7777) {
    this.targetHost = host;
    this.targetPort = port;
    this.client = dgram.createSocket('udp4');
    
    this.client.on('error', (err) => {
      console.error('UDP client error:', err);
      this.client.close();
    });

    this.client.on('connect', () => {
      console.log(`UDP client connected to ${this.targetHost}:${this.targetPort}`);
    });

    console.log(`UDP sender configured for ${this.targetHost}:${this.targetPort}`);
  }

  sendPacket(bars: number[], beat: boolean): Promise<void> {
    return new Promise((resolve, reject) => {
      const packet: UDPPacket = {
        frame: this.frameCounter++,
        bars: bars,
        beat: beat
      };

      const message = JSON.stringify(packet);
      const buffer = Buffer.from(message);

      this.client.send(buffer, this.targetPort, this.targetHost, (err) => {
        if (err) {
          console.error('Failed to send UDP packet:', err);
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }

  close(): void {
    this.client.close();
    console.log('UDP sender closed');
  }

  resetFrameCounter(): void {
    this.frameCounter = 0;
  }

  getFrameCount(): number {
    return this.frameCounter;
  }
}
