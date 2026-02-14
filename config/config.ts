export interface Config {
  port: number;
  uploadDir: string;
  visualOutputDir: string;
  udpHost: string;
  udpPort: number;
  allowedFileTypes: string[];
  maxFileSizeMB: number;
}

export const config: Config = {
  port: parseInt(process.env.PORT || '3000'),
  uploadDir: process.env.UPLOAD_DIR || './uploads',
  visualOutputDir: process.env.VISUAL_OUTPUT_DIR || './visuals',
  udpHost: process.env.UDP_HOST || '192.168.4.1',
  udpPort: parseInt(process.env.UDP_PORT || '7777'),
  allowedFileTypes: ['mp3', 'wav', 'flac'],
  maxFileSizeMB: parseInt(process.env.MAX_FILE_SIZE_MB || '50')
};
