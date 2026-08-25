export const env = {
  port: Number(process.env.PORT || 4000),
  mongoUri: process.env.MONGODB_URI || '',
  youtubeApiKey: process.env.YOUTUBE_API_KEY || '',
  corsOrigin: process.env.CORS_ORIGIN || '*',
};
