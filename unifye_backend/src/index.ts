import express from 'express';

const app = express();
const port = 3000;

app.use(express.json());

app.get('/', (_req, res) => {
  res.send('Hello from TypeScript backend!');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
