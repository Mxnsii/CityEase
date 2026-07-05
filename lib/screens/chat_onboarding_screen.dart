import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

import '../data/area_suggestions.dart';
import '../models/survey_criteria.dart';
import '../services/google_places_service.dart';
import '../utils/google_api_keys.dart';
import 'office_map_screen.dart';
import 'results_screen.dart';

class ChatOnboardingScreen extends StatefulWidget {
  const ChatOnboardingScreen({super.key});

  @override
  State<ChatOnboardingScreen> createState() => _ChatOnboardingScreenState();
}

class _ChatOnboardingScreenState extends State<ChatOnboardingScreen> {
  final List<Map<String, dynamic>> _steps = [
    {
      'prompt': 'Hi there! I\'m your CityEase AI assistant. What\'s your monthly rent budget?',
      'options': ['₹15k - ₹25k', '₹25k - ₹35k', '₹35k+', 'All'],
      'key': 'budget',
    },
    {
      'prompt': 'Great! Type your preferred city or area in India and choose one from the list below.',
      'options': areaSuggestions,
      'key': 'officeArea',
    },
    {
      'prompt': 'What\'s your lifestyle preference?',
      'options': ['Vibrant nightlife', 'Quiet comfort', 'Co-living energy', 'Premium lifestyle'],
      'key': 'lifestyle',
    },
    {
      'prompt': 'What\'s your maximum acceptable commute time?',
      'options': ['15 min max', '30 min max', '45 min max', '1 hour is fine'],
      'key': 'commute',
    },
  ];

  final List<Map<String, String>> _messages = [
    {
      'text': 'Hi there! 👋 I\'m your CityEase AI assistant. What\'s your monthly rent budget?',
      'sender': 'bot',
    },
  ];

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _officeSearchController = TextEditingController();
  late final GooglePlacesService _placesService;

  int _currentStep = 0;
  String _budget = '₹15k - ₹25k';
  String _officeArea = 'Koramangala';
  String _officeLocation = 'Koramangala office';
  double _officeLat = 12.9352;
  double _officeLng = 77.6245;
  String _lifestyle = 'Vibrant nightlife';
  String _commute = '30 min max';
  String? _selectedPlaceId;
  List<AutocompletePrediction> _placePredictions = [];
  List<String> _localSuggestions = [];
  bool _isLoadingPredictions = false;

  @override
  void initState() {
    super.initState();
    _placesService = GooglePlacesService(kGoogleMapsApiKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    _officeSearchController.dispose();
    super.dispose();
  }

  Future<void> _onOfficeSearchChanged(String value) async {
    if (_steps[_currentStep]['key'] != 'officeArea') return;
    _selectedPlaceId = null;
    final typed = value.trim().toLowerCase();
    if (typed.isEmpty) {
      setState(() {
        _placePredictions = [];
        _localSuggestions = [];
      });
      return;
    }

    // 1. Instant case-insensitive substring search matching ANY location containing the text
    final suggestions = areaSuggestions
        .where((area) => area.toLowerCase().contains(typed))
        .toList();

    setState(() {
      _isLoadingPredictions = true;
      _localSuggestions = suggestions;
    });

    // 2. Fetch from Google Places API if configured
    final results = await _placesService.autocomplete(value);
    if (!mounted) return;
    setState(() {
      _placePredictions = results;
      _isLoadingPredictions = false;
    });
  }

  Future<void> _selectOfficePrediction(AutocompletePrediction prediction) async {
    final placeId = prediction.placeId;
    final userText = prediction.description ?? '';
    final navigator = Navigator.of(context);
    setState(() {
      _messages.add({'text': userText, 'sender': 'user'});
      _officeArea = userText;
      _officeSearchController.text = userText;
      _placePredictions = [];
      _localSuggestions = [];
      _selectedPlaceId = placeId;
    });

    if (placeId == null) {
      await _openMapForArea(userText);
      return;
    }

    final details = await _placesService.getPlaceDetails(placeId);
    if (details == null || details.geometry?.location == null) {
      await _openMapForArea(userText);
      return;
    }

    final lat = details.geometry!.location!.lat!;
    final lng = details.geometry!.location!.lng!;
    final selectedOffice = await navigator.push<OfficeSelection?>(
      MaterialPageRoute(
        builder: (_) => OfficeMapScreen(
          area: _officeArea,
          placeName: userText,
          initialPosition: LatLng(lat, lng),
        ),
      ),
    );

    if (selectedOffice == null) {
      setState(() {
        _messages.add({
          'text': 'Select your office on the map to continue.',
          'sender': 'bot',
        });
      });
      return;
    }

    setState(() {
      _officeLocation = selectedOffice.label;
      _officeLat = selectedOffice.latitude;
      _officeLng = selectedOffice.longitude;
      _currentStep += 1;
      _messages.add({
        'text': 'Great! I set your office at ${selectedOffice.label}.',
        'sender': 'bot',
      });
      if (_currentStep < _steps.length) {
        _messages.add({
          'text': _steps[_currentStep]['prompt'] as String,
          'sender': 'bot',
        });
      }
    });
  }

  Future<void> _selectLocalSuggestion(String suggestion) async {
    setState(() {
      _messages.add({'text': suggestion, 'sender': 'user'});
      _officeArea = suggestion;
      _officeSearchController.text = suggestion;
      _placePredictions = [];
      _localSuggestions = [];
      _selectedPlaceId = null;
    });
    await _openMapForArea(suggestion);
  }

  Future<void> _openMapForArea(String area) async {
    final coords = _coordsForArea(area);
    final navigator = Navigator.of(context);
    final selectedOffice = await navigator.push<OfficeSelection?>(
      MaterialPageRoute(
        builder: (_) => OfficeMapScreen(
          area: area,
          placeName: area,
          initialPosition: coords,
        ),
      ),
    );

    if (selectedOffice == null) {
      setState(() {
        _messages.add({
          'text': 'Select your office on the map to continue.',
          'sender': 'bot',
        });
      });
      return;
    }

    setState(() {
      _officeLocation = selectedOffice.label;
      _officeLat = selectedOffice.latitude;
      _officeLng = selectedOffice.longitude;
      _currentStep += 1;
      _messages.add({
        'text': 'Great! I set your office at ${selectedOffice.label}.',
        'sender': 'bot',
      });
      if (_currentStep < _steps.length) {
        _messages.add({
          'text': _steps[_currentStep]['prompt'] as String,
          'sender': 'bot',
        });
      }
    });
  }

  LatLng _coordsForArea(String area) {
    // 1. Check coordinates map from areaSuggestions
    if (areaCoordinates.containsKey(area)) {
      return areaCoordinates[area]!;
    }
    
    // 2. Perform case-insensitive search in keys
    final query = area.toLowerCase();
    for (var entry in areaCoordinates.entries) {
      if (entry.key.toLowerCase().contains(query) || query.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // 3. Fallback logic
    if (query.contains('koramangala')) return const LatLng(12.9352, 77.6245);
    if (query.contains('indiranagar')) return const LatLng(12.9719, 77.6412);
    if (query.contains('whitefield')) return const LatLng(12.9690, 77.7493);
    if (query.contains('electronic city') || query.contains('ecity')) return const LatLng(12.8400, 77.6600);
    if (query.contains('bits goa')) return const LatLng(15.3919, 73.8782);
    if (query.contains('vasco')) return const LatLng(15.3979, 73.8150);
    if (query.contains('goa')) return const LatLng(15.4909, 73.8278);
    if (query.contains('panaji')) return const LatLng(15.4909, 73.8278);
    if (query.contains('margao')) return const LatLng(15.2993, 73.9643);
    if (query.contains('calangute')) return const LatLng(15.5450, 73.7570);
    if (query.contains('juhu')) return const LatLng(19.0986, 72.8263);
    if (query.contains('bandra')) return const LatLng(19.0514, 72.8402);
    if (query.contains('pune')) return const LatLng(18.5204, 73.8567);
    if (query.contains('connaught place') || query.contains('cp')) return const LatLng(28.6315, 77.2167);
    if (query.contains('bits pilani')) return const LatLng(28.3639, 75.5880);
    if (query.contains('bits hyderabad')) return const LatLng(17.5449, 78.5717);
    return const LatLng(20.5937, 78.9629);
  }

  Future<void> _handleReply(String answer) async {
    if (_currentStep >= _steps.length) return;

    final key = _steps[_currentStep]['key'] as String;
    if (key == 'officeArea') {
      if (_selectedPlaceId == null) {
        setState(() {
          _messages.add({
            'text': 'Please select one of the dropdown suggestions so I can open the map for you.',
            'sender': 'bot',
          });
        });
      }
      return;
    }

    setState(() {
      _messages.add({'text': answer, 'sender': 'user'});
      if (key == 'budget') _budget = answer;
      if (key == 'lifestyle') _lifestyle = answer;
      if (key == 'commute') _commute = answer;
      _currentStep += 1;
      if (_currentStep < _steps.length) {
        _messages.add({
          'text': _steps[_currentStep]['prompt'] as String,
          'sender': 'bot',
        });
      }
      _controller.clear();
    });
  }

  void _sendCustomAnswer() {
    final answer = _controller.text.trim();
    if (answer.isEmpty || _currentStep >= _steps.length) return;
    _handleReply(answer);
  }

  Future<void> _finishConversation() async {
    final criteria = SurveyCriteria(
      budget: _budget,
      officeArea: _officeArea,
      officeLocation: _officeLocation,
      officeLat: _officeLat,
      officeLng: _officeLng,
      lifestyle: _lifestyle,
      commute: _commute,
    );
    final shouldReset = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(criteria: criteria),
      ),
    );

    if (shouldReset == true) {
      setState(() {
        _currentStep = 0;
        _messages.clear();
        _messages.add({
          'text': 'Let\'s try expanding your search! What\'s your new monthly rent budget?',
          'sender': 'bot',
        });
        _officeSearchController.clear();
        _placePredictions.clear();
        _localSuggestions.clear();
        _selectedPlaceId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = _currentStep >= _steps.length;
    final currentKey = isCompleted ? 'completed' : _steps[_currentStep]['key'] as String;
    final currentOptions = !isCompleted && currentKey != 'officeArea'
        ? List<String>.from(_steps[_currentStep]['options'] as List)
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CityEase AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Let\'s find your perfect stay stay',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6F5CFF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forum_rounded, color: Color(0xFF8C88FF), size: 24),
                  ),
                ],
              ),
            ),

            // Main chat container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF11142B),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF20254D)),
                ),
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 220),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isBot = message['sender'] == 'bot';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Align(
                            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: isBot
                                    ? const LinearGradient(
                                        colors: [Color(0xFF1D2248), Color(0xFF131732)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFF6F5CFF), Color(0xFF5038FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                border: isBot
                                    ? Border.all(color: const Color(0xFF2E356A).withValues(alpha: 0.4))
                                    : null,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(24),
                                  topRight: const Radius.circular(24),
                                  bottomLeft: Radius.circular(isBot ? 6 : 24),
                                  bottomRight: Radius.circular(isBot ? 24 : 6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                message['text']!,
                                style: TextStyle(
                                  color: isBot ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Inputs & Autocomplete Dropdowns
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentKey == 'officeArea') ...[
                            if (_isLoadingPredictions)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: CircularProgressIndicator(color: Color(0xFF6F5CFF)),
                              ),
                            if (_placePredictions.isNotEmpty || _localSuggestions.isNotEmpty)
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F1225).withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: const Color(0xFF262C54)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        ..._placePredictions.map((prediction) => InkWell(
                                              onTap: () => _selectOfficePrediction(prediction),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.location_on, size: 18, color: Color(0xFF8C88FF)),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        prediction.description ?? '',
                                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                        ..._localSuggestions.map((suggestion) => InkWell(
                                              onTap: () => _selectLocalSuggestion(suggestion),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.search, size: 18, color: Color(0xFF8C88FF)),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        suggestion,
                                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          if (currentOptions.isNotEmpty) ...[
                            SizedBox(
                              height: 42,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: currentOptions.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final option = currentOptions[index];
                                  return ActionChip(
                                    label: Text(
                                      option,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    backgroundColor: const Color(0xFF161A36),
                                    side: const BorderSide(color: Color(0xFF333966)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                    onPressed: () => _handleReply(option),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1225),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF262C54)),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: currentKey == 'officeArea'
                                        ? _officeSearchController
                                        : _controller,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: currentKey == 'officeArea'
                                          ? 'Search city, landmark, or neighborhood...'
                                          : 'Type your answer...',
                                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                                    ),
                                    onChanged: currentKey == 'officeArea'
                                        ? _onOfficeSearchChanged
                                        : null,
                                    onSubmitted: (_) => _sendCustomAnswer(),
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6F5CFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                    onPressed: _sendCustomAnswer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_currentStep >= _steps.length)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: const Color(0xFF6F5CFF),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _finishConversation,
                                  child: const Text(
                                    'See AI matches + nearby PG stays',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
