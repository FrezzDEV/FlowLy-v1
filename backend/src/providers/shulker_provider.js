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

function normalizeArtist(item) {
  const artist = item?.artist;
  if (typeof artist === 'string') return artist;
  if (artist?.name) return String(artist.name);
  if (Array.isArray(item?.artists)) {
    const names = item.artists.map((entry) => entry?.name).filter(Boolean);
    if (names.length) return names.join(', ');
  }
  if (typeof item?.author === 'string') return item.author;
  if (typeof item?.artistName === 'string') return item.artistName;
  return 'Unknown artist';
}

function normalizeThumbnail(item) {
  return item?.artworkUrl
    ?? item?.thumbnail
    ?? item?.artwork
    ?? item?.thumbnailUrl
    ?? item?.album?.artworkUrl
    ?? item?.artist?.imageUrl;
}

function normalizeTrack(item) {
  const track = item?.track ?? item?.data ?? item;
  const videoId = track?.youtubeId
    ?? track?.videoId
    ?? track?.video_id
    ?? track?.trackId
    ?? track?.track_id
    ?? track?.id;

  if (!videoId) return null;

  return {
    videoId: String(videoId),
    title: track.title ?? track.name ?? 'Unknown track',
    artist: normalizeArtist(track),
    thumbnail: normalizeThumbnail(track),
    durationSeconds: track.durationSeconds
      ?? track.duration_seconds
      ?? parseDuration(track.duration),
  };
}

function extractResults(body) {
  if (Array.isArray(body)) return body;
  return body?.tracks ?? body?.results ?? body?.data ?? body?.items ?? [];
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
        ok: response.ok && (body?.status === 'ok' || body?.ok === true),
        provider: 'shulker',
        baseUrl: this.baseUrl,
        version: body?.version,
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
    const response = await this.request(
      `/search?q=${encodeURIComponent(query)}&filter=tracks`,
    );
    const body = await response.json();

    return extractResults(body)
      .map(normalizeTrack)
      .filter(Boolean)
      .slice(0, 20);
  }

  async getSong(videoId) {
    const response = await this.request(`/tracks/${encodeURIComponent(videoId)}`);
    const body = await response.json();
    const track = normalizeTrack(body);
    if (!track) throw new Error(`Shulker returned no track for ${videoId}`);
    return track;
  }

  async getStream(videoId) {
    return {
      url: this.apiUrl(`/stream/${encodeURIComponent(videoId)}/audio`),
      provider: 'shulker',
      proxy: true,
      mimeType: 'audio/*',
      bitrate: null,
    };
  }
}
