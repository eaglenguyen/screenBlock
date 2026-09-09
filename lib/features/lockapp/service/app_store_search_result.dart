// lib/features/lockapp/app_store_search_result.dart
class AppStoreSearchResult {
  final String trackName;
  final String? artworkUrl;
  final String? bundleId;
  final int trackId;

  const AppStoreSearchResult({
    required this.trackName,
    this.artworkUrl,
    this.bundleId,
    required this.trackId,
  });

  factory AppStoreSearchResult.fromJson(Map<String, dynamic> json) {
    final rawName = json['trackName'] as String? ?? 'Unknown';
    return AppStoreSearchResult(
      trackName: _cleanAppName(rawName), // 👈 cleaned here
      artworkUrl: json['artworkUrl100'] as String?,
      bundleId: json['bundleId'] as String?,
      trackId: json['trackId'] as int? ?? 0,
    );
  }

  static String _cleanAppName(String name) {
    // App Store titles commonly append a tagline after " - " or ": "
    final dashIndex = name.indexOf(' - ');
    final colonIndex = name.indexOf(': ');
    int cutIndex = -1;
    if (dashIndex != -1 && colonIndex != -1) {
      cutIndex = dashIndex < colonIndex ? dashIndex : colonIndex;
    } else if (dashIndex != -1) {
      cutIndex = dashIndex;
    } else if (colonIndex != -1) {
      cutIndex = colonIndex;
    }
    if (cutIndex > 0) {
      return name.substring(0, cutIndex).trim();
    }
    return name.trim();
  }
}