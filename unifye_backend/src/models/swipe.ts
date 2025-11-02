import mongoose, { Document, Schema } from 'mongoose';

export interface ISwipe extends Document {
  swiper: mongoose.Types.ObjectId;
  swiped: mongoose.Types.ObjectId;
  type: 'like' | 'pass' | 'superlike';
  createdAt: Date;
}

const swipeSchema = new Schema<ISwipe>(
  {
    swiper: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    swiped: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['like', 'pass', 'superlike'],
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure a user can only swipe once on another user
swipeSchema.index({ swiper: 1, swiped: 1 }, { unique: true });

// Index for querying swipes
swipeSchema.index({ swiper: 1, type: 1 });
swipeSchema.index({ swiped: 1, type: 1 });

export default mongoose.model<ISwipe>('Swipe', swipeSchema);
