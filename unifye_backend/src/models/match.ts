import mongoose, { Document, Schema } from 'mongoose';

export interface IMatch extends Document {
  user1: mongoose.Types.ObjectId;
  user2: mongoose.Types.ObjectId;
  status: 'active' | 'unmatched';
  matchedAt: Date;
  lastMessageAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const matchSchema = new Schema<IMatch>(
  {
    user1: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    user2: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    status: {
      type: String,
      enum: ['active', 'unmatched'],
      default: 'active',
    },
    matchedAt: {
      type: Date,
      default: Date.now,
    },
    lastMessageAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure unique matches between two users
matchSchema.index({ user1: 1, user2: 1 }, { unique: true });

// Index for querying user matches
matchSchema.index({ user1: 1, status: 1 });
matchSchema.index({ user2: 1, status: 1 });

export default mongoose.model<IMatch>('Match', matchSchema);
