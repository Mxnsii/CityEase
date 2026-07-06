import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/area_suggestions.dart';
import '../models/survey_criteria.dart';
import '../services/google_places_service.dart';
import '../utils/app_theme.dart';
import '../utils/google_api_keys.dart';
import 'ai_loading_screen.dart';
import 'office_map_screen.dart';

class ChatOnboardingScreen extends StatefulWidget {
  const ChatOnboardingScreen({super.key});

  @override
  State<ChatOnboardingScreen> createState() => _ChatOnboardingScreenState();
}

class _ChatOnboardingScreenState extends State<ChatOnboardingScreen> {
  final List<Map<String, dynamic>> _steps = [
    {
      'prompt': 'Hi! I\'m your CityEase AI assistant. Let\'s find the perfect stay for you. What is your monthly rent budget?',
      'options': ['₹5k - ₹10k', '₹10k - ₹15k', '₹15k - ₹25k', 'All'],
      'key': 'budget',
    },
    {
      'prompt': 'Great! Where is your office located? Please search and select from suggestions.',
      'options': areaSuggestions,
      'key': 'officeArea',
    },
    {
      'prompt': 'Got it! Whom are you looking for? (Gender preference)',
      'options': ['Male Only', 'Female Only', 'Co-living'],
      'key': 'gender',
    },
    {
      'prompt': 'Do you need meals/food included in your PG stay?',
      'options': ['Food Included', 'No Food Preference'],
      'key': 'foodIncluded',
    },
    {
      'prompt': 'Would you like an AC room or is a Non-AC room fine?',
      'options': ['AC Room Required', 'Non-AC is Fine'],
      'key': 'acRequired',
    },
    {
      'prompt': 'How close to your office would you like to stay?',
      'options': ['Walking distance (<1km)', 'Short drive (<4km)', 'Any (<10km)'],
      'key': 'distancePref',
    },
  ];

  final List<Map<String, String>> _messages = [
    {
      'text': 'Hi! 👋 I\'m your CityEase AI assistant. Let\'s find the perfect stay for you. What is your monthly rent budget?',
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
  String _gender = 'Co-living';
  bool _foodIncluded = true;
  String _distancePref = 'Any (<10km)';
  bool _acRequired = true;

  String? _selectedPlaceId;
  List<AutocompletePrediction> _placePredictions = [];
  List<String> _localSuggestions = [];
  bool _isLoadingPredictions = false;
  bool _isTyping = false;

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

    final suggestions = areaSuggestions
        .where((area) => area.toLowerCase().contains(typed))
        .toList();

    setState(() {
      _isLoadingPredictions = true;
      _localSuggestions = suggestions;
    });

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

    _officeLocation = selectedOffice.label;
    _officeLat = selectedOffice.latitude;
    _officeLng = selectedOffice.longitude;
    
    await _advanceStep('Set office coordinates');
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

    _officeLocation = selectedOffice.label;
    _officeLat = selectedOffice.latitude;
    _officeLng = selectedOffice.longitude;

    await _advanceStep('Set office coordinates');
  }

  LatLng _coordsForArea(String area) {
    if (areaCoordinates.containsKey(area)) {
      return areaCoordinates[area]!;
    }
    final query = area.toLowerCase();
    for (var entry in areaCoordinates.entries) {
      if (entry.key.toLowerCase().contains(query) || query.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    if (query.contains('koramangala')) return const LatLng(12.9352, 77.6245);
    if (query.contains('indiranagar')) return const LatLng(12.9719, 77.6412);
    if (query.contains('whitefield')) return const LatLng(12.9690, 77.7493);
    if (query.contains('electronic city') || query.contains('ecity')) return const LatLng(12.8400, 77.6600);
    if (query.contains('bits goa')) return const LatLng(15.3919, 73.8782);
    if (query.contains('vasco')) return const LatLng(15.3979, 73.8150);
    if (query.contains('goa')) return const LatLng(15.4909, 73.8278);
    if (query.contains('panaji')) return const LatLng(15.4909, 73.8278);
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
      if (key == 'gender') _gender = answer;
      if (key == 'foodIncluded') _foodIncluded = answer.contains('Included');
      if (key == 'acRequired') _acRequired = answer.contains('Required');
      if (key == 'distancePref') _distancePref = answer;
    });

    _controller.clear();
    await _advanceStep(answer);
  }

  Future<void> _advanceStep(String lastAnswer) async {
    setState(() {
      _currentStep += 1;
    });

    if (_currentStep < _steps.length) {
      // Trigger dynamic chatbot typing state
      setState(() {
        _isTyping = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': _steps[_currentStep]['prompt'] as String,
          'sender': 'bot',
        });
      });
    }
  }

  void _sendCustomAnswer() {
    final answer = _controller.text.trim();
    if (answer.isEmpty || _currentStep >= _steps.length) return;
    _handleReply(answer);
  }

  Future<void> _savePreferencesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_budget', _budget);
    await prefs.setString('saved_office_area', _officeArea);
    await prefs.setString('saved_office_location', _officeLocation);
    await prefs.setDouble('saved_office_lat', _officeLat);
    await prefs.setDouble('saved_office_lng', _officeLng);
    await prefs.setString('saved_gender', _gender);
    await prefs.setBool('saved_food_included', _foodIncluded);
    await prefs.setString('saved_distance_pref', _distancePref);
    await prefs.setBool('saved_ac_required', _acRequired);
  }

  Future<void> _finishConversation() async {
    final criteria = SurveyCriteria(
      budget: _budget,
      officeArea: _officeArea,
      officeLocation: _officeLocation,
      officeLat: _officeLat,
      officeLng: _officeLng,
      lifestyle: 'Quiet Comfort',
      commute: 'Any',
      gender: _gender,
      foodIncluded: _foodIncluded,
      distancePref: _distancePref,
      acRequired: _acRequired,
    );
    final navigator = Navigator.of(context);
    await _savePreferencesToStorage();
    final shouldReset = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => AiLoadingScreen(criteria: criteria),
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
      backgroundColor: AppTheme.primaryBackground,
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
                        'Let\'s find your perfect neighborhood',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forum_rounded, color: AppTheme.accentColorLight, size: 24),
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
                  color: AppTheme.secondaryBackground,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.borderTranslucent),
                ),
                child: Stack(
                  children: [
                    ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.only(bottom: 220, top: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        final isBot = message['sender'] == 'bot';
                        final isMe = !isBot;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Align(
                            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? AppTheme.primaryGradient
                                    : const LinearGradient(
                                        colors: [AppTheme.cardBackground, AppTheme.secondaryBackground],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(AppTheme.cardRadius),
                                  topRight: Radius.circular(AppTheme.cardRadius),
                                  bottomLeft: isMe ? Radius.circular(AppTheme.cardRadius) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : Radius.circular(AppTheme.cardRadius),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(color: AppTheme.borderTranslucent),
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

                    // Typing Indicator
                    if (_isTyping)
                      Positioned(
                        left: 0,
                        bottom: 90,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1D2248), Color(0xFF131732)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.accentColorLight,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'AI is compiling matching stays...',
                                style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
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
                                child: CircularProgressIndicator(color: AppTheme.accentColor),
                              ),
                            if (_placePredictions.isNotEmpty || _localSuggestions.isNotEmpty)
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.elevatedCardBackground.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                    border: Border.all(color: AppTheme.borderTranslucent),
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
                                                    const Icon(Icons.location_on, size: 18, color: AppTheme.accentColorLight),
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
                                                    const Icon(Icons.search, size: 18, color: AppTheme.accentColorLight),
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
                          if (currentOptions.isNotEmpty && !_isTyping) ...[
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
                                    backgroundColor: AppTheme.secondaryBackground,
                                    side: BorderSide(color: AppTheme.borderTranslucent),
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
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                              border: Border.all(color: AppTheme.borderTranslucent),
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
                                    color: AppTheme.accentColor,
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
                                    backgroundColor: AppTheme.accentColor,
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
