export const env = {
  port: Number(process.env.PORT || 4000),
  mongoUri: process.env.MONGODB_URI || '',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  shulkerApiUrl: process.env.SHULKER_API_URL || 'http://127.0.0.1:8000',
  shulkerTimeoutMs: Number(process.env.SHULKER_TIMEOUT_MS || 12000),
  shulkerFallbackYoutube: process.env.SHULKER_FALLBACK_YOUTUBE === 'true',
  youtubeApiKey: process.env.YOUTUBE_API_KEY || '',
  ytDlpPath: process.env.YTDLP_PATH || 'yt-dlp',
  preferYtDlp: process.env.PREFER_YTDLP !== 'false',
};
