import mongoose, { Document, Schema } from 'mongoose';

export interface IMatch extends Document {
  sender: mongoose.Types.ObjectId;
  receiver: mongoose.Types.ObjectId;
  status: 'active' | 'unmatched';
  matchedAt: Date;
  lastMessageAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const matchSchema = new Schema<IMatch>(
  {
    sender: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    receiver: {
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
matchSchema.index({ sender: 1, receiver: 1 }, { unique: true });

// Index for querying user matches
matchSchema.index({ sender: 1, status: 1 });
matchSchema.index({ receiver: 1, status: 1 });

export default mongoose.model<IMatch>('Match', matchSchema);
