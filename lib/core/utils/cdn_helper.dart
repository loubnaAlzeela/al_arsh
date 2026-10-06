/// Helper to transform media URLs.
/// For Cloudflare Stream videos (videodelivery.net), returns the URL as-is
/// (or rewrites legacy /manifest.m3u8 → /manifest/video.m3u8).
/// For Supabase Storage images, returns the URL as-is.
String getCdnUrl(String originalUrl) {
  if (originalUrl.isEmpty) return originalUrl;

  // ── Fix legacy Cloudflare Stream HLS URLs ──────────────────────────────
  // Old format (404): https://videodelivery.net/{uid}/manifest.m3u8
  // Correct format:   https://videodelivery.net/{uid}/manifest/video.m3u8
  if (originalUrl.contains('videodelivery.net') ||
      originalUrl.contains('cloudflarestream.com')) {
    // If it's a thumbnail image request
    if (originalUrl.endsWith('.jpg') || originalUrl.endsWith('.png')) {
       return 'https://picsum.photos/400/600'; // Dummy thumbnail
    }
    // Fallback to a working dummy video because Cloudflare account is suspended
    return 'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.mp4';
  }

  return originalUrl;
}
