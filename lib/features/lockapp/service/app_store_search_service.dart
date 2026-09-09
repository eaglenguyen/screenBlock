import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_store_search_result.dart';


class AppStoreSearchService {
  static List<AppStoreSearchResult>? _cachedPopularApps;

  Future<List<AppStoreSearchResult>> search(String term) async {
    if (term.trim().isEmpty) return [];
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'media': 'software',
      'entity': 'software',
      'limit': '25',
      'country': 'us',
    });
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>? ?? [])
          .map((r) => AppStoreSearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
      return results;
    } catch (e) {
      return [];
    }
  }

  static const _popularAppNames = [
    'Instagram',
    'TikTok',
    'YouTube',
    'Facebook',
    'X',
    'Snapchat',
    'Reddit',
    'WhatsApp',
    'Netflix',
    'Spotify',
    'Discord',
    'Pinterest',
  ];

  Future<List<AppStoreSearchResult>> fetchPopularApps({int limit = 15}) async {
    if (_cachedPopularApps != null) {
      return _cachedPopularApps!; // 👈 only fetch once per app session
    }
    final futures = _popularAppNames.take(limit).map((name) async {
      final results = await search(name);
      return results.isNotEmpty ? results.first : null;
    });
    final resolved = await Future.wait(futures);
    final apps = resolved.whereType<AppStoreSearchResult>().toList();
    _cachedPopularApps = apps;
    return apps;
  }
}