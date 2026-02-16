export interface Track {
  id: string;
  title: string;
  artist: string;
  album?: string;
  durationMs: number;
  fps: number;
  audioPath: string;
  visualPath: string;
  metaPath: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface NewTrackInput {
  title: string;
  artist: string;
  album?: string;
  durationMs: number;
  fps: number;
  audioPath: string;
  visualPath: string;
  metaPath: string;
}

export function createTrack(input: NewTrackInput): Track {
  const now = new Date();
  return {
    id: generateId(),
    ...input,
    createdAt: now,
    updatedAt: now
  };
}

function generateId(): string {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}
