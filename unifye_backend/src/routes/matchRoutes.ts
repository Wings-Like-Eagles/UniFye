import express from 'express';
import { swipe, getPotentialMatches, getMatches, unmatch } from '../controllers/matchController';
import { asyncHandler } from '../utils/asyncHandler';

const router = express.Router();

router.post('/swipe', asyncHandler(swipe));
router.get('/potential', asyncHandler(getPotentialMatches));
router.get('/', asyncHandler(getMatches));
router.delete('/:matchId', asyncHandler(unmatch));

export default router;