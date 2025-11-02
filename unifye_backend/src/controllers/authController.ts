import { Request, Response, NextFunction } from 'express';
import jwt, { Secret } from "jsonwebtoken";
import User, { UserDocument } from '../models/user';
import Profile from '../models/profile';
import { AuthRequest } from '../middleware/auth';

// Generate JWT Token

const generateToken = (id: string): string => {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET is not defined");

  const expiresIn = (process.env.JWT_EXPIRES_IN || "7d") as jwt.SignOptions["expiresIn"];

  return jwt.sign({ id }, secret as Secret, { expiresIn });
};


// @desc    Register user
// @route   POST /api/auth/register
export const register = async (req: Request, res: Response,  next: NextFunction) => {
  try {
    const { email, password, name, dateOfBirth, gender, interestedIn } = req.body;

    // Check if user exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      res.status(400).json({
        success: false,
        message: 'User already exists',
      });
    }

    // Calculate age
    const age = new Date().getFullYear() - new Date(dateOfBirth).getFullYear();
    if (age < 18) {
      return res.status(400).json({
        success: false,
        message: 'Must be at least 18 years old',
      });
    }

    // Create user
    const user: UserDocument = await User.create({
      email,
      password,
      name,
      dateOfBirth,
      gender,
      interestedIn,
    });

    // Create basic profile
    await Profile.create({
      user: user._id,
      age,
      location: {
        type: 'Point',
        coordinates: [0, 0], // Will be updated later
      },
      photos: [],
    });

    const token = generateToken(user._id.toString());

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user._id.toString(),
          email: user.email,
          name: user.name,
        },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Login user
// @route   POST //apiauth/login
export const login = async (req: Request, res: Response,  next: NextFunction) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password',
      });
    }

    // Find user with password
    const user = await User.findOne({ email }).select('+password') as UserDocument | null;
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    const token = generateToken(user._id.toString());

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id.toString(),
          email: user.email,
          name: user.name,
        },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current user
// @route   GET /api/auth/me
export const getMe = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const user = await User.findById(req.user?._id);
    const profile = await Profile.findOne({ user: req.user?._id });

    res.status(200).json({
      success: true,
      data: {
        user,
        profile,
      },
    });
  } catch (error) {
    next(error);
  }
};
