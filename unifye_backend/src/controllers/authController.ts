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
/**
 * Register a new user.
 *
 * Validates request body, enforces age restriction, creates the user and an associated basic profile,
 * then responds with the created user summary and an authentication token.
 *
 * Expected req.body:
 * - email: string
 * - password: string
 * - name: string
 * - dateOfBirth: string | Date (ISO date string accepted)
 * - gender: string
 * - interestedIn: string
 *
 * Behavior:
 * - Checks if a user with the provided email already exists and returns 400 if so.
 * - Calculates age from dateOfBirth (year difference) and returns 400 if age < 18.
 * - Creates a User document and a corresponding Profile document with default location { type: 'Point', coordinates: [0, 0] } and empty photos array.
 * - Generates an authentication token for the created user.
 * - On success, sends HTTP 201 with JSON: { success: true, data: { user: { id, email, name }, token } }.
 * - Any unexpected errors are forwarded to the next(error) error-handling middleware.
 *
 * @param req - Express Request. Contains the registration payload in req.body.
 * @param res - Express Response. Used to send JSON responses with appropriate HTTP status codes.
 * @param next - Express NextFunction. Called with an error to delegate to error-handling middleware.
 *
 * @returns Promise<void> Sends an HTTP response; does not return a value to the caller.
 */
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
/**
 * Authenticate a user using email and password, then return a JWT token and basic user info.
 *
 * This handler expects an Express Request containing `email` and `password` in the request body.
 * It performs the following steps:
 * 1. Validates that `email` and `password` are present; responds with 400 if missing.
 * 2. Loads the user by email including the hashed password; responds with 401 if no user is found.
 * 3. Compares the provided password to the stored hash; responds with 401 on mismatch.
 * 4. Generates a JWT access token for the authenticated user and responds with 200 and the user data.
 *
 * The function is asynchronous and forwards unexpected errors to the next error handler.
 *
 * @param req - Express Request. Expects `{ email: string, password: string }` in `req.body`.
 * @param res - Express Response. On success responds with status 200 and a JSON payload:
 *              `{ success: true, data: { user: { id, email, name }, token } }`.
 *              On validation or auth failure responds with appropriate status (400 or 401) and an error message.
 * @param next - Express NextFunction. Called with the caught Error on unexpected failures.
 *
 * @returns A Promise that resolves when the response has been sent. Errors are passed to `next`.
 *
 * @remarks
 * - The implementation relies on a `User` model with a `comparePassword` instance method and a `generateToken` helper.
 * - Sensitive information (such as the password hash) is excluded from the response.
 *
 * @example
 * // Request body:
 * // { "email": "user@example.com", "password": "s3cr3t" }
 *
 * // Successful response (200):
 * // {
 * //   "success": true,
 * //   "data": {
 * //     "user": { "id": "abc123", "email": "user@example.com", "name": "Jane Doe" },
 * //     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6..."
 * //   }
 * // }
 */
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
