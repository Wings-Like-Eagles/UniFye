import express from 'express';

const router = express.Router();

// TODO: Add message routes
router.get('/:matchId', (req, res) => {
  res.send('Get messages for a match');
});


// GET /api/messages/:matchId - Get messages for a match
// POST /api/messages - Send message
// PUT /api/messages/:messageId/read - Mark message as read
// GET /api/messages/unread - Get unread message count

export default router;