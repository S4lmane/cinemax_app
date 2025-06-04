import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../models/person_details.dart';
import '../../../models/person_credits.dart';

class PeopleProvider extends ChangeNotifier {
  PersonDetails? _currentPersonDetails;
  PersonCredits? _currentPersonCredits;
  bool _isLoadingPersonDetails = false;
  bool _isLoadingPersonCredits = false;
  String? _personDetailsError;
  String? _personCreditsError;

  // Getters
  PersonDetails? get currentPersonDetails => _currentPersonDetails;
  PersonCredits? get currentPersonCredits => _currentPersonCredits;
  bool get isLoadingPersonDetails => _isLoadingPersonDetails;
  bool get isLoadingPersonCredits => _isLoadingPersonCredits;
  String? get personDetailsError => _personDetailsError;
  String? get personCreditsError => _personCreditsError;

  Future<void> fetchPersonDetails(int personId) async {
    _isLoadingPersonDetails = true;
    _personDetailsError = null;
    notifyListeners();

    try {
      // Using your API constants for the TMDB API
      final url = '${ApiConstants.baseUrl}/person/$personId?api_key=${ApiConstants.apiKey}&language=en-US';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Here we would add awards if available from an API
        // For now, we'll add some mock awards for popular actors
        final mockAwards = await _getMockAwards(personId, data['name']);
        if (mockAwards.isNotEmpty) {
          data['awards'] = mockAwards;
        }

        _currentPersonDetails = PersonDetails.fromJson(data);
      } else {
        _personDetailsError = 'Failed to load person details: ${response.statusCode}';
      }
    } catch (e) {
      _personDetailsError = 'Error fetching person details: $e';
    } finally {
      _isLoadingPersonDetails = false;
      notifyListeners();
    }
  }

  Future<void> fetchPersonCredits(int personId) async {
    _isLoadingPersonCredits = true;
    _personCreditsError = null;
    notifyListeners();

    try {
      // Using your API constants for the TMDB API
      final url = '${ApiConstants.baseUrl}/person/$personId/combined_credits?api_key=${ApiConstants.apiKey}&language=en-US';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentPersonCredits = PersonCredits.fromJson(data);
      } else {
        _personCreditsError = 'Failed to load person credits: ${response.statusCode}';
      }
    } catch (e) {
      _personCreditsError = 'Error fetching person credits: $e';
    } finally {
      _isLoadingPersonCredits = false;
      notifyListeners();
    }
  }

  // This is a mock method that would be replaced with actual API data
  // Unfortunately TMDB API doesn't provide awards data directly,
  // so we need to mock it for now
  Future<List<Map<String, dynamic>>> _getMockAwards(int personId, String name) async {
    // Some famous actors and their awards (mock data)
    final awardsMap = {
      // Leonardo DiCaprio
      '6193': [
        {
          'name': 'Academy Award',
          'year': '2016',
          'category': 'Best Actor',
          'won': true
        },
        {
          'name': 'Golden Globe',
          'year': '2016',
          'category': 'Best Actor - Drama',
          'won': true
        }
      ],
      // Meryl Streep
      '5064': [
        {
          'name': 'Academy Award',
          'year': '2012',
          'category': 'Best Actress',
          'won': true
        },
        {
          'name': 'Academy Award',
          'year': '1983',
          'category': 'Best Actress',
          'won': true
        },
        {
          'name': 'Academy Award',
          'year': '1980',
          'category': 'Best Supporting Actress',
          'won': true
        },
      ],
      // Robert Downey Jr.
      '3223': [
        {
          'name': 'Golden Globe',
          'year': '2010',
          'category': 'Best Actor - Comedy or Musical',
          'won': true
        },
      ],
      // Tom Hanks
      '31': [
        {
          'name': 'Academy Award',
          'year': '1994',
          'category': 'Best Actor',
          'won': true
        },
        {
          'name': 'Academy Award',
          'year': '1995',
          'category': 'Best Actor',
          'won': true
        },
      ],
      // Add more for other famous personalities
    };

    return awardsMap[personId.toString()] ?? [];
  }
}