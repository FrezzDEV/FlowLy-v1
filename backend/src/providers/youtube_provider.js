import { Innertube } from 'youtubei.js';

export class YouTubeProvider {
  constructor({ apiKey = '' } = {}) {
    this.apiKey = apiKey;
    this.youtubePromise = null;
  }

  async client() {
    this.youtubePromise ??= Innertube.create();
    return this.youtubePromise;
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
