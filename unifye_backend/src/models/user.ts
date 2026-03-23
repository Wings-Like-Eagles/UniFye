import mongoose, { Schema, Model, Types } from 'mongoose';
import bcrypt from 'bcryptjs';

// Define the interface for User document
export interface IUser {
  email: string;
  password: string;
  name: string;
  dateOfBirth: Date;
  gender: 'male' | 'female';
  interestedIn: ('male' | 'female')[];
  verified: boolean;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Define the interface for User document methods
export interface IUserMethods {
  comparePassword(candidatePassword: string): Promise<boolean>;
}

// Create a type that includes the document, methods, and virtuals
export type UserDocument = mongoose.Document<Types.ObjectId, {}, IUser> & IUser & IUserMethods;

// Define the model type
export type UserModel = Model<IUser, {}, IUserMethods>;

const userSchema = new Schema<IUser, UserModel, IUserMethods>(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
      minlength: 6,
      select: false, // Don't return password by default
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    dateOfBirth: {
      type: Date,
      required: true,
    },
    gender: {
      type: String,
      enum: ['male', 'female'],
      required: true,
    },
    interestedIn: [{
      type: String,
      enum: ['male', 'female'],
    }],
    verified: {
      type: Boolean,
      default: false,
    },
    active: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Method to compare passwords
userSchema.methods.comparePassword = async function (candidatePassword: string): Promise<boolean> {
  return bcrypt.compare(candidatePassword, this.password);
};

const User = mongoose.model<IUser, UserModel>('User', userSchema);

export default User;
