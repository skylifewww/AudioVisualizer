import { Router } from 'express';
import * as fs from 'fs';
import * as path from 'path';
import { collectFrames } from '../../worker/src/frameCollector';
import { writeVisualFile } from '../../worker/src/visualEncoder';
import { DSPProcessor } from '../../worker/src/dsp';
import { BeatDetector } from '../../worker/src/beat';

const router = Router();

// POST /api/generate
router.post('/generate', async (req, res) => {
  try {
    const { trackId, filePath } = req.body;

    if (!trackId || !filePath) {
      return res.status(400).json({ error: 'Missing trackId or filePath' });
    }

    // Check if visual file already exists
    const visualPath = filePath.replace(/\.[^/.]+$/, '') + '.visual';
    
    if (fs.existsSync(visualPath)) {
      return res.json({
        status: 'ready',
        url: `/visual/${trackId}`
      });
    }

    // Process audio file
    const dsp = new DSPProcessor();
    const beatDetector = new BeatDetector({
      threshold: 1.3,
      minInterval: 0.1,
      decayRate: 0.98
    });

    await dsp.loadAudioFile(filePath);
    const collectedData = collectFrames(dsp, beatDetector);
    
    // Generate visual file
    writeVisualFile(visualPath, collectedData.fps, collectedData.durationMs, collectedData.frames);

    res.json({
      status: 'ready',
      url: `/visual/${trackId}`
    });

  } catch (error) {
    console.error('Generate error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/visual/:trackId
router.get('/visual/:trackId', (req, res) => {
  try {
    const { trackId } = req.params;
    
    // For now, assume files are stored with trackId as filename
    const visualPath = path.join(process.cwd(), 'visuals', `${trackId}.visual`);
    
    if (!fs.existsSync(visualPath)) {
      return res.status(404).json({ error: 'Visual file not found' });
    }

    res.setHeader('Content-Type', 'application/octet-stream');
    res.sendFile(visualPath);

  } catch (error) {
    console.error('Visual serve error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
