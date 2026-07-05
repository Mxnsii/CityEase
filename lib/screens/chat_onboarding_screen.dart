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

    final suggestions = areaSuggestions
        .where((area) {
          final normalized = area.toLowerCase();
          return normalized.startsWith(typed) || normalized.contains(' $typed');
        })
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
    final query = area.toLowerCase();
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
    if (query.contains('bits goa')) return const LatLng(15.3919, 73.8782);
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
      // Reset state to ask questions again when returning from an empty state
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('CityEase AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          )),
                      SizedBox(height: 6),
                      Text('Let\'s find your perfect neighborhood',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  const Icon(Icons.location_city, color: Color(0xFFE3D8FF), size: 28),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF12162D),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF2B3052)),
                ),
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 220),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isBot = message['sender'] == 'bot';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Align(
                            alignment:
                                isBot ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isBot
                                    ? const Color(0xFF171B3B)
                                    : const Color(0xFF4D3BFF),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isBot ? 4 : 20),
                                  bottomRight: Radius.circular(isBot ? 20 : 4),
                                ),
                              ),
                              child: Text(
                                message['text']!,
                                style: TextStyle(
                                  color: isBot ? Colors.white70 : Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                                constraints: const BoxConstraints(maxHeight: 220),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10142A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF2D3060)),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        ..._placePredictions
                                            .map((prediction) => InkWell(
                                                  onTap: () => _selectOfficePrediction(prediction),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.location_on,
                                                            size: 18,
                                                            color: Color(0xFF8C88FF)),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            prediction.description ?? '',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )),
                                        ..._localSuggestions
                                            .map((suggestion) => InkWell(
                                                  onTap: () => _selectLocalSuggestion(suggestion),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.search,
                                                            size: 18,
                                                            color: Color(0xFF8C88FF)),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            suggestion,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 14,
                                                            ),
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
                              height: 50,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: currentOptions.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final option = currentOptions[index];
                                  return ActionChip(
                                    label: Text(option,
                                        style: const TextStyle(color: Colors.white)),
                                    backgroundColor: const Color(0xFF1D2243),
                                    onPressed: () => _handleReply(option),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF10142A),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFF2D3161)),
                            ),
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                      hintStyle: const TextStyle(color: Colors.white38),
                                    ),
                                    onChanged: currentKey == 'officeArea'
                                        ? _onOfficeSearchChanged
                                        : null,
                                    onSubmitted: (_) => _sendCustomAnswer(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send, color: Color(0xFF8C88FF)),
                                  onPressed: _sendCustomAnswer,
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
                                  child: const Text('See AI matches + nearby PG stays',
                                      style: TextStyle(fontSize: 16)),
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
