import { Router } from 'express';
import multer from 'multer';
import { runPreprocess } from '../../src/index'; // путь к функции preprocess из основного index.ts
import path from 'path';
import fs from 'fs';

const router = Router();
const upload = multer({ dest: 'uploads/' });

router.post('/analyze', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No audio file provided' });
  }

  const filePath = req.file.path;
  const outputFileName = filePath.replace(/\.[^/.]+$/, '') + '.visual';
  const outputMetaName = outputFileName + '.meta.json';

  try {
    // Вызов обработки
    await runPreprocess(filePath);

    // Проверяем, существует ли файл
    if (!fs.existsSync(outputFileName)) {
      return res.status(500).json({ error: 'Failed to generate visual file' });
    }

    res.json({
      status: 'success',
      visualUrl: `/files/${path.basename(outputFileName)}`,
      metaUrl: `/files/${path.basename(outputMetaName)}`,
      fileName: path.basename(outputFileName)
    });
  } catch (error) {
    console.error('Error during preprocessing:', error);
    res.status(500).json({ error: 'Internal server error during preprocessing' });
  } finally {
    // Удаляем временный файл
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }
});

export default router;
