import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import Swipe from '../models/swipe';
import Match from '../models/match';
import Profile from '../models/profile';

// @desc    Swipe on a user
// @route   POST /api/matches/swipe
export const swipe = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { swipedUserId, type } = req.body; // type: 'like', 'pass', 'superlike'
    const swiperId = req.user?._id;

    if (!swiperId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    if (swiperId.toString() === swipedUserId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot swipe on yourself',
      });
    }

    // Check if already swiped
    const existingSwipe = await Swipe.findOne({
      swiper: swiperId,
      swiped: swipedUserId,
    });

    if (existingSwipe) {
      return res.status(400).json({
        success: false,
        message: 'Already swiped on this user',
      });
    }

    // Create swipe
    const swipe = await Swipe.create({
      swiper: swiperId,
      swiped: swipedUserId,
      type,
    });

    // Check if it's a match (if they liked and the other person also liked)
    if (type === 'like' || type === 'superlike') {
      const reciprocalSwipe = await Swipe.findOne({
        swiper: swipedUserId,
        swiped: swiperId,
        type: { $in: ['like', 'superlike'] },
      });

      if (reciprocalSwipe) {
        // Create match
        const match = await Match.create({
          user1: swiperId,
          user2: swipedUserId,
        });

        return res.status(201).json({
          success: true,
          message: "It's a match!",
          data: {
            swipe,
            match,
            isMatch: true,
          },
        });
      }
    }

    res.status(201).json({
      success: true,
      data: {
        swipe,
        isMatch: false,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get potential matches
// @route   GET /api/matches/potential
export const getPotentialMatches = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    // Get user's profile to check preferences
    const userProfile = await Profile.findOne({ user: userId });
    if (!userProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profile not found',
      });
    }

    // Get users already swiped on
    const swipedUsers = await Swipe.find({ swiper: userId }).select('swiped');
    const swipedUserIds = swipedUsers.map(s => s.swiped);

    // Find potential matches based on preferences
    const potentialMatches = await Profile.find({
      user: { $nin: [...swipedUserIds, userId] },
      age: {
        $gte: userProfile.preferences.ageRange.min,
        $lte: userProfile.preferences.ageRange.max,
      },
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: userProfile.location.coordinates,
          },
          $maxDistance: userProfile.preferences.maxDistance * 1000, // convert km to meters
        },
      },
    })
      .populate('user', 'name')
      .limit(20);

    res.status(200).json({
      success: true,
      data: potentialMatches,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's matches
// @route   GET /api/matches
export const getMatches = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    const matches = await Match.find({
      $or: [{ user1: userId }, { user2: userId }],
      status: 'active',
    })
      .populate('user1', 'name')
      .populate('user2', 'name')
      .sort('-matchedAt');

    res.status(200).json({
      success: true,
      data: matches,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Unmatch
// @route   DELETE /api/matches/:matchId
export const unmatch = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { matchId } = req.params;
    const userId = req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    const match = await Match.findOne({
      _id: matchId,
      $or: [{ user1: userId }, { user2: userId }],
    });

    if (!match) {
      return res.status(404).json({
        success: false,
        message: 'Match not found',
      });
    }

    match.status = 'unmatched';
    await match.save();

    res.status(200).json({
      success: true,
      message: 'Unmatched successfully',
    });
  } catch (error) {
    next(error);
  }
};
