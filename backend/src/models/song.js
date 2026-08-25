import mongoose from 'mongoose';

const SongSchema = new mongoose.Schema(
  {
    videoId: { type: String, unique: true, index: true },
    title: String,
    artist: String,
    thumbnail: String,
    durationSeconds: Number,
  },
  { timestamps: true },
);

export const Song = mongoose.models.Song || mongoose.model('Song', SongSchema);
