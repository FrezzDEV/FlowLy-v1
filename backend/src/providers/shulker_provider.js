const DEFAULT_TIMEOUT_MS = 12_000;

function parseDuration(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.round(value);
  if (typeof value !== 'string') return undefined;

  const parts = value.trim().split(':').map(Number);
  if (parts.some((part) => Number.isNaN(part))) return undefined;
  if (parts.length === 2) return parts[0] * 60 + parts[1];
  if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
  return undefined;
}

function firstArtist(item) {
  if (typeof item.artist === 'string') return item.artist;
  if (typeof item.author === 'string') return item.author;
  if (typeof item.artistName === 'string') return item.artistName;
  if (Array.isArray(item.artists)) {
    return item.artists.map((artist) => artist?.name).filter(Boolean).join(', ') || 'Unknown artist';
  }
  return 'Unknown artist';
}

function firstThumbnail(item) {
  if (typeof item.thumbnail === 'string') return item.thumbnail;
  if (typeof item.artwork === 'string') return item.artwork;
  if (typeof item.artworkUrl === 'string') return item.artworkUrl;
  if (typeof item.thumbnailUrl === 'string') return item.thumbnailUrl;
  if (Array.isArray(item.thumbnails)) {
    const image = item.thumbnails.find((entry) => entry?.url)?.url;
    if (image) return image;
  }
  return undefined;
}

function normalizeTrack(item) {
  const videoId = item?.videoId ?? item?.video_id ?? item?.trackId ?? item?.track_id ?? item?.id;
  if (!videoId) return null;

  return {
    videoId: String(videoId),
    title: item.title ?? item.name ?? 'Unknown track',
    artist: firstArtist(item),
    thumbnail: firstThumbnail(item),
    durationSeconds: item.durationSeconds ?? item.duration_seconds ?? parseDuration(item.duration),
  };
}

function extractResults(body) {
  if (Array.isArray(body)) return body;
  return body?.results ?? body?.tracks ?? body?.data ?? body?.items ?? [];
}

export class ShulkerProvider {
  constructor({ baseUrl, timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
    this.baseUrl = String(baseUrl || '').replace(/\/$/, '');
    this.timeoutMs = timeoutMs;
  }

  apiUrl(path) {
    return `${this.baseUrl}/api${path}`;
  }

  async request(path, options = {}) {
    if (!this.baseUrl) throw new Error('SHULKER_API_URL is not configured');

    const response = await fetch(this.apiUrl(path), {
      ...options,
      signal: AbortSignal.timeout(this.timeoutMs),
      headers: {
        Accept: 'application/json',
        ...(options.headers ?? {}),
      },
    });

    if (!response.ok) {
      const body = await response.text().catch(() => '');
      throw new Error(`Shulker API ${response.status}: ${body.slice(0, 300)}`);
    }

    return response;
  }

  async health() {
    try {
      const response = await this.request('/health');
      const body = await response.json();
      return {
        ok: body?.ok !== false,
        provider: 'shulker',
        baseUrl: this.baseUrl,
      };
    } catch (error) {
      return {
        ok: false,
        provider: 'shulker',
        baseUrl: this.baseUrl,
        error: error.message,
      };
    }
  }

  async search(query) {
    const url = new URL(this.apiUrl('/search'));
    url.searchParams.set('q', query);
    url.searchParams.set('filter', 'songs');

    const response = await this.request(`/search?${url.searchParams.toString()}`);
    const body = await response.json();

    return extractResults(body)
      .map(normalizeTrack)
      .filter(Boolean)
      .slice(0, 20);
  }

  async getSong(videoId) {
    const response = await this.request(`/tracks/${encodeURIComponent(videoId)}`);
    const body = await response.json();
    const track = normalizeTrack(body?.track ?? body?.data ?? body);
    if (!track) throw new Error(`Shulker returned no track for ${videoId}`);
    return track;
  }

  async getStream(videoId) {
    return {
      url: `${this.apiUrl(`/stream/${encodeURIComponent(videoId)}/audio`)}`,
      provider: 'shulker',
      mimeType: 'audio/*',
      bitrate: null,
    };
  }
}
