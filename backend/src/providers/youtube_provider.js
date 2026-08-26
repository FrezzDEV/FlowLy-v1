import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

import { Innertube } from 'youtubei.js';

const execFileAsync = promisify(execFile);

export class YouTubeProvider {
  constructor({ apiKey = '', ytDlpPath = 'yt-dlp', preferYtDlp = true } = {}) {
    this.apiKey = apiKey;
    this.ytDlpPath = ytDlpPath;
    this.preferYtDlp = preferYtDlp;
    this.youtubePromise = null;
  }

  async client() {
    this.youtubePromise ??= Innertube.create();
    return this.youtubePromise;
  }

  async health() {
    try {
      const { stdout } = await execFileAsync(
        this.ytDlpPath,
        ['--version'],
        { timeout: 5_000, maxBuffer: 64 * 1024 },
      );

      return {
        ok: true,
        ytDlp: true,
        ytDlpVersion: stdout.trim(),
        preferredProvider: this.preferYtDlp ? 'yt-dlp' : 'youtubei.js',
      };
    } catch (error) {
      return {
        ok: false,
        ytDlp: false,
        preferredProvider: this.preferYtDlp ? 'yt-dlp' : 'youtubei.js',
        error: error.message,
      };
    }
  }

  async search(query) {
    if (this.apiKey) return this.searchDataApi(query);

    const yt = await this.client();
    const result = await yt.search(query, { type: 'video' });
    return (result.results ?? [])
      .filter((item) => item.video_id)
      .slice(0, 12)
      .map((item) => ({
        videoId: item.video_id,
        title: item.title ?? 'Unknown track',
        artist: item.author?.name ?? item.owner?.name ?? 'Unknown artist',
        thumbnail: item.best_thumbnail?.url ?? item.thumbnails?.[0]?.url,
        durationSeconds: item.duration?.seconds,
      }));
  }

  async getSong(videoId) {
    const yt = await this.client();
    const info = await yt.getBasicInfo(videoId);
    return {
      videoId,
      title: info.basic_info?.title ?? 'Unknown track',
      artist: info.basic_info?.author ?? 'Unknown artist',
      thumbnail: info.basic_info?.thumbnail?.[0]?.url,
      durationSeconds: info.basic_info?.duration,
    };
  }

  async getStream(videoId) {
    if (this.preferYtDlp) {
      try {
        return await this.getStreamWithYtDlp(videoId);
      } catch (error) {
        console.warn(`yt-dlp stream resolution failed for ${videoId}: ${error.message}`);
      }
    }

    return this.getStreamWithInnertube(videoId);
  }

  async getStreamWithYtDlp(videoId) {
    const url = `https://www.youtube.com/watch?v=${encodeURIComponent(videoId)}`;
    const { stdout } = await execFileAsync(
      this.ytDlpPath,
      [
        '--no-playlist',
        '--no-warnings',
        '--quiet',
        '--skip-download',
        '-f',
        'bestaudio/best',
        '-g',
        url,
      ],
      {
        timeout: 20_000,
        maxBuffer: 1024 * 1024,
      },
    );

    const streamUrl = stdout
      .split(/\r?\n/)
      .map((line) => line.trim())
      .find(Boolean);

    if (!streamUrl) throw new Error('yt-dlp returned no audio URL');

    return {
      url: streamUrl,
      provider: 'yt-dlp',
      mimeType: null,
      bitrate: null,
    };
  }

  async getStreamWithInnertube(videoId) {
    const yt = await this.client();
    const info = await yt.getBasicInfo(videoId);
    const format = info.chooseFormat({ type: 'audio', quality: 'best' });
    if (!format) throw new Error('No compatible audio format found');

    const url = typeof format.decipher === 'function'
      ? format.decipher(yt.session.player)
      : format.url;
    if (!url) throw new Error('Unable to resolve audio stream URL');

    return {
      url: String(url),
      provider: 'youtubei.js',
      mimeType: format.mime_type,
      bitrate: format.bitrate,
    };
  }

  async searchDataApi(query) {
    const url = new URL('https://www.googleapis.com/youtube/v3/search');
    url.searchParams.set('part', 'snippet');
    url.searchParams.set('q', query);
    url.searchParams.set('type', 'video');
    url.searchParams.set('maxResults', '12');
    url.searchParams.set('key', this.apiKey);

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`YouTube Data API failed: ${response.status}`);
    }

    const data = await response.json();
    return data.items.map((item) => ({
      videoId: item.id.videoId,
      title: item.snippet.title,
      artist: item.snippet.channelTitle,
      thumbnail: item.snippet.thumbnails?.high?.url ?? item.snippet.thumbnails?.default?.url,
    }));
  }
}
