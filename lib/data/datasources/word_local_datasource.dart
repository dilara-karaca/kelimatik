import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/word_pair.dart';

/// Loads word pairs from the bundled JSON asset.
class WordLocalDataSource {
  Future<List<WordPair>> loadWords() async {
    final raw = await rootBundle.loadString(AppConstants.wordsAssetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .cast<Map<String, dynamic>>()
        .map(WordPair.fromJson)
        .where((pair) => pair.correct != pair.wrong)
        .toList(growable: false);
  }
}
