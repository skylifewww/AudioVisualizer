import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { AnalyzerService } from '../../services/AnalyzerService';

const router = Router();
const upload = multer({ dest: 'uploads/' });

router.post('/analyze', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No audio file provided' });
  }

  const filePath = req.file.path;
  const analyzer = new AnalyzerService();

  try {
    const result = await analyzer.analyzeAudio(filePath);

    if (result.success) {
      res.json({
        status: 'success',
        visualUrl: result.visualUrl,
        metaUrl: result.metaUrl
      });
    } else {
      res.status(500).json({ error: result.error });
    }
  } catch (error) {
    console.error('Error during preprocessing:', error);
    res.status(500).json({ error: 'Internal server error during preprocessing' });
  } finally {
    // Clean up uploaded file
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }
});

export default router;
