import * as fs from 'fs';
import { CRC32 } from './crc32';

export interface FrameData {
  bars: number[];
  beat: number;
}

export function writeVisualFile(
  outputPath: string,
  fps: number,
  durationMs: number,
  frames: FrameData[],
  compact: boolean = true
): void {
  // Calculate total size needed
  const headerSize = 20; // 5 * uint32 (version + isCompact + fps + totalFrames + durationMs)
  const frameSize = compact ? 32 * 1 + 1 : 32 * 4 + 1; // uint8 vs float32 for bars
  const dataSize = headerSize + frames.length * frameSize;
  const totalSize = dataSize + 4; // +4 for CRC32 checksum

  // Create buffer
  const buffer = Buffer.alloc(totalSize);
  let offset = 0;

  // Write header (little-endian)
  buffer.writeUInt32LE(1, offset); // version
  offset += 4;
  
  buffer.writeUInt32LE(compact ? 1 : 0, offset); // isCompact
  offset += 4;
  
  buffer.writeUInt32LE(Math.floor(fps), offset); // fps
  offset += 4;
  
  buffer.writeUInt32LE(frames.length, offset); // totalFrames
  offset += 4;
  
  buffer.writeUInt32LE(Math.floor(durationMs), offset); // durationMs
  offset += 4;

  // Write frames
  for (const frame of frames) {
    // Write 32 bars (uint8 or float32)
    for (let i = 0; i < 32; i++) {
      const value = frame.bars[i] || 0;
      if (compact) {
        buffer.writeUInt8(Math.round(value * 255), offset); // Convert 0-1 to 0-255
        offset += 1;
      } else {
        buffer.writeFloatLE(value, offset);
        offset += 4;
      }
    }
    
    // Write beat as uint8
    buffer.writeUInt8(frame.beat ? 1 : 0, offset);
    offset += 1;
  }

  // Compute and write CRC32 checksum
  const dataBuffer = buffer.slice(0, dataSize); // All data except checksum
  const checksum = CRC32.compute(dataBuffer);
  buffer.writeUInt32LE(checksum, offset); // Append checksum at end

  // Write to file
  fs.writeFileSync(outputPath, buffer);
  
  // Write metadata JSON file
  const metaPath = outputPath + '.meta.json';
  const metadata = {
    durationSeconds: Math.round(durationMs / 1000 * 100) / 100, // 2 decimal places
    fps: Math.round(fps),
    bands: 32,
    version: 1,
    compact: compact,
    totalFrames: frames.length
  };
  
  fs.writeFileSync(metaPath, JSON.stringify(metadata, null, 2));
  
  console.log(`Binary visual file written: ${outputPath}`);
  console.log(`Metadata file written: ${metaPath}`);
  console.log(`- Header: version=1, compact=${compact}, fps=${fps}, frames=${frames.length}, duration=${durationMs}ms`);
  console.log(`- Frame size: ${frameSize} bytes (${compact ? 'uint8' : 'float32'} bars)`);
  console.log(`- CRC32 checksum: 0x${checksum.toString(16).padStart(8, '0').toUpperCase()}`);
  console.log(`- File size: ${(buffer.length / 1024 / 1024).toFixed(2)} MB`);
}
