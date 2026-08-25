export class SongService {
  constructor({ provider, songModel = null }) {
    this.provider = provider;
    this.songModel = songModel;
  }

  async search(query) {
    const results = await this.provider.search(query);
    await this.cache(results);
    return results;
  }

  async getByVideoId(videoId) {
    if (this.songModel) {
      const cached = await this.songModel.findOne({ videoId }).lean();
      if (cached) return cached;
    }

    const song = await this.provider.getSong(videoId);
    if (this.songModel) {
      await this.songModel.findOneAndUpdate(
        { videoId },
        song,
        { upsert: true, new: true },
      );
    }
    return song;
  }

  async cache(songs) {
    if (!this.songModel || !songs.length) return;
    await this.songModel.bulkWrite(
      songs.map((song) => ({
        updateOne: {
          filter: { videoId: song.videoId },
          update: { $set: song },
          upsert: true,
        },
      })),
      { ordered: false },
    );
  }
}
