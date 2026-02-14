import express from 'express';
import cors from 'cors';
import analyzeRoute from './routes/analyze';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use('/api', analyzeRoute);

app.listen(PORT, () => {
  console.log(`API server running on http://localhost:${PORT}`);
});
