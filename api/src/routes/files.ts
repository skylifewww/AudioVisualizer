import { Router } from 'express';
import path from 'path';
import fs from 'fs';

const router = Router();

// Serve .visual and .meta.json files
router.get('/:filename', (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(__dirname, '..', '..', 'visuals', filename);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  res.sendFile(filePath);
});

export default router;
