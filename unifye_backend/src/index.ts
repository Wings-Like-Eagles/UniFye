import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDatabase } from './config/database';
import { errorHandler } from './middleware/errorHandler';

// Import routes
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import profileRoutes from './routes/profileRoutes';
import matchRoutes from './routes/matchRoutes';
import messageRoutes from './routes/messageRoutes';

// Load environment variables
dotenv.config();

const app: Application = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files (uploaded images)
app.use('/uploads', express.static('uploads'));

// Routes
app.get('/', (_req, res) => {
  res.json({
    message: 'Dating App API',
    version: '1.0.0',
    status: 'active'
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/profiles', profileRoutes);
app.use('/api/matches', matchRoutes);
app.use('/api/messages', messageRoutes);

// Error handling middleware (must be last)
app.use(errorHandler);

// Database connection and server start
const startServer = async () => {
  try {
    await connectDatabase();
    app.listen(port, () => {
      console.log(`🚀 Server running at http://localhost:${port}`);
      console.log(`📝 Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app;
