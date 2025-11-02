import mongoose, { Document, Schema } from 'mongoose';

export interface IMessage extends Document {
  match: mongoose.Types.ObjectId;
  sender: mongoose.Types.ObjectId;
  receiver: mongoose.Types.ObjectId;
  content: string;
  type: 'text' | 'image' | 'gif';
  read: boolean;
  readAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const messageSchema = new Schema<IMessage>(
  {
    match: {
      type: Schema.Types.ObjectId,
      ref: 'Match',
      required: true,
    },
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
    content: {
      type: String,
      required: true,
      maxlength: 1000,
    },
    type: {
      type: String,
      enum: ['text', 'image', 'gif'],
      default: 'text',
    },
    read: {
      type: Boolean,
      default: false,
    },
    readAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Index for querying messages
messageSchema.index({ match: 1, createdAt: -1 });
messageSchema.index({ receiver: 1, read: 1 });

export default mongoose.model<IMessage>('Message', messageSchema);
