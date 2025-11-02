import express from 'express'; 
import { register,login, getMe } from '../controllers/authController';
import { asyncHandler } from '../utils/asyncHandler';

const router = express.Router();

// Routes are defined relative to the base path set in the main server file
router.post('/register', asyncHandler(register));
router.post('/login',asyncHandler(login));
router.get('me', asyncHandler(getMe))

export default router; 
