// Lightweight CRC32 implementation
export class CRC32 {
  private static table: number[] | null = null;

  private static makeTable(): void {
    const table = new Array(256);
    for (let i = 0; i < 256; i++) {
      let c = i;
      for (let j = 0; j < 8; j++) {
        c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      }
      table[i] = c;
    }
    CRC32.table = table;
  }

  static compute(buffer: Buffer): number {
    if (!CRC32.table) {
      CRC32.makeTable();
    }

    let crc = 0 ^ (-1);
    
    for (let i = 0; i < buffer.length; i++) {
      crc = (crc >>> 8) ^ CRC32.table![ (crc ^ buffer[i]) & 0xFF ];
    }
    
    return (crc ^ (-1)) >>> 0; // Convert to unsigned 32-bit
  }
}
