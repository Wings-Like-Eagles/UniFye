import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IProfile extends Document {
  _id: Types.ObjectId;
  id: string;
  user: Types.ObjectId;
  bio: string;
  photos: string[];
  location: {
    type: string;
    coordinates: [number, number];
    city?: string;
    country?: string;
  };
  age: number;
  interests: string[];
  occupation?: string;
  education?: string;
  height?: number;
  lookingFor: 'friendship' | 'dating' | 'relationship' | 'casual';
  preferences: {
    ageRange: {
      min: number;
      max: number;
    };
    maxDistance: number;
  };
  socialLinks?: {
    instagram?: string;
    spotify?: string;
  };
  createdAt: Date;
  updatedAt: Date;
}

const profileSchema = new Schema<IProfile>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    bio: {
      type: String,
      maxlength: 500,
      default: '',
    },
    photos: [{
      type: String,
      required: true,
    }],
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number],
        required: true,
      },
      city: String,
      country: String,
    },
    age: {
      type: Number,
      required: true,
      min: 18,
      max: 100,
    },
    interests: [{
      type: String,
      trim: true,
    }],
    occupation: {
      type: String,
      trim: true,
    },
    education: {
      type: String,
      trim: true,
    },
    height: {
      type: Number,
      min: 100,
      max: 250,
    },
    lookingFor: {
      type: String,
      enum: ['friendship', 'dating', 'relationship', 'casual'],
      default: 'dating',
    },
    preferences: {
      ageRange: {
        min: {
          type: Number,
          default: 18,
        },
        max: {
          type: Number,
          default: 99,
        },
      },
      maxDistance: {
        type: Number,
        default: 50, // km
      },
    },
    socialLinks: {
      instagram: String,
      spotify: String,
    },
  },
  {
    timestamps: true,
  }
);

// Create geospatial index for location-based queries
profileSchema.index({ location: '2dsphere' });

export default mongoose.model<IProfile>('Profile', profileSchema);
