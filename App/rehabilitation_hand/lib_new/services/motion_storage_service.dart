import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';

// Key for storing data in SharedPreferences
const String _customTemplatesKey = 'custom_motion_templates';
const String _defaultTemplatesOrderKey =
    'default_templates_order'; // Key for default order
const String _playlistsKey = 'motion_playlists';

class MotionStorageService with ChangeNotifier {
  List<MotionTemplate> _customTemplates = [];
  List<MotionPlaylist> _playlists = [];
  // Make default templates mutable for reordering
  final List<MotionTemplate> _defaultTemplates = [
    MotionTemplate(
      id: 'default_fist',
      name: '握拳',
      createdAt: DateTime.now(),
      positions: [
        FingerPosition(
          thumb: FingerState.contracted,
          index: FingerState.contracted,
          middle: FingerState.contracted,
          ring: FingerState.contracted,
          pinky: FingerState.contracted,
        ),
      ],
    ),
    MotionTemplate(
      id: 'default_open',
      name: '張開',
      createdAt: DateTime.now(),
      positions: [
        FingerPosition(
          thumb: FingerState.extended,
          index: FingerState.extended,
          middle: FingerState.extended,
          ring: FingerState.extended,
          pinky: FingerState.extended,
        ),
      ],
    ),
    MotionTemplate(
      id: 'default_relax',
      name: '放鬆',
      createdAt: DateTime.now(),
      positions: [
        FingerPosition(
          thumb: FingerState.relaxed,
          index: FingerState.relaxed,
          middle: FingerState.relaxed,
          ring: FingerState.relaxed,
          pinky: FingerState.relaxed,
        ),
      ],
    ),
    MotionTemplate(
      id: 'default_ok',
      name: 'OK手勢',
      createdAt: DateTime.now(),
      positions: [
        FingerPosition(
          thumb: FingerState.contracted,
          index: FingerState.contracted,
          middle: FingerState.extended,
          ring: FingerState.extended,
          pinky: FingerState.extended,
        ),
      ],
    ),
  ];

  MotionStorageService() {
    _loadData();
  }

  // Getters
  List<MotionTemplate> get customTemplates => _customTemplates;
  List<MotionTemplate> get defaultTemplates => _defaultTemplates;
  List<MotionPlaylist> get playlists => _playlists;

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load custom templates
    final templatesJson = prefs.getString(_customTemplatesKey);
    if (templatesJson != null) {
      final List<dynamic> decodedList = jsonDecode(templatesJson);
      _customTemplates =
          decodedList.map((item) => _templateFromJson(item)).toList();
    }

    // Load default templates order
    final defaultOrder = prefs.getStringList(_defaultTemplatesOrderKey);
    if (defaultOrder != null) {
      _defaultTemplates.sort((a, b) {
        final aIndex = defaultOrder.indexOf(a.id);
        final bIndex = defaultOrder.indexOf(b.id);
        // If an item is not in the saved order, keep it at the end
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
    }

    // Load playlists
    final playlistsJson = prefs.getString(_playlistsKey);
    if (playlistsJson != null) {
      final List<dynamic> decodedList = jsonDecode(playlistsJson);
      _playlists = decodedList.map((item) => _playlistFromJson(item)).toList();
    }

    notifyListeners();
  }

  Future<void> _saveCustomTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encodedList =
        _customTemplates.map((t) => _templateToJson(t)).toList();
    await prefs.setString(_customTemplatesKey, jsonEncode(encodedList));
    notifyListeners();
  }

  Future<void> _saveDefaultTemplateOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = _defaultTemplates.map((t) => t.id).toList();
    await prefs.setStringList(_defaultTemplatesOrderKey, order);
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encodedList =
        _playlists.map((p) => _playlistToJson(p)).toList();
    await prefs.setString(_playlistsKey, jsonEncode(encodedList));
    notifyListeners();
  }

  // --- Template Management ---

  MotionTemplate? getTemplateById(String id) {
    try {
      return [
        ..._defaultTemplates,
        ..._customTemplates,
      ].firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  bool isNameTaken(String name, {String? excludeId}) {
    return _customTemplates.any((t) => t.name == name && t.id != excludeId);
  }

  Future<void> saveTemplate(MotionTemplate template) async {
    final index = _customTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _customTemplates[index] = template;
    } else {
      _customTemplates.add(template);
    }
    await _saveCustomTemplates();
  }

  Future<void> saveAllCustomTemplates(List<MotionTemplate> templates) async {
    _customTemplates = templates;
    await _saveCustomTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    _customTemplates.removeWhere((t) => t.id == id);
    await _saveCustomTemplates();
  }

  Future<void> reorderTemplate(int oldIndex, int newIndex) async {
    final item = _customTemplates.removeAt(oldIndex);
    _customTemplates.insert(newIndex, item);
    await _saveCustomTemplates();
    notifyListeners();
  }

  Future<void> reorderDefaultTemplate(int oldIndex, int newIndex) async {
    final item = _defaultTemplates.removeAt(oldIndex);
    _defaultTemplates.insert(newIndex, item);
    await _saveDefaultTemplateOrder();
    notifyListeners();
  }

  // --- Playlist Management ---

  bool isPlaylistNameTaken(String name, {String? excludeId}) {
    return _playlists.any((p) => p.name == name && p.id != excludeId);
  }

  Future<void> savePlaylist(MotionPlaylist playlist) async {
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      _playlists[index] = playlist;
    } else {
      _playlists.add(playlist);
    }
    await _savePlaylists();
  }

  Future<void> saveAllPlaylists(List<MotionPlaylist> playlists) async {
    _playlists = playlists;
    await _savePlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await _savePlaylists();
  }

  // --- JSON Serialization/Deserialization ---

  Map<String, dynamic> _templateToJson(MotionTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'createdAt': template.createdAt.toIso8601String(),
      'positions': template.positions.map((p) => _positionToJson(p)).toList(),
    };
  }

  MotionTemplate _templateFromJson(Map<String, dynamic> json) {
    return MotionTemplate(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      positions:
          (json['positions'] as List).map((p) => _positionFromJson(p)).toList(),
    );
  }

  Map<String, dynamic> _positionToJson(FingerPosition position) {
    return {
      'thumb': position.thumb.index,
      'index': position.index.index,
      'middle': position.middle.index,
      'ring': position.ring.index,
      'pinky': position.pinky.index,
      'holdDuration': position.holdDuration,
    };
  }

  FingerPosition _positionFromJson(Map<String, dynamic> json) {
    return FingerPosition(
      thumb: FingerState.values[json['thumb']],
      index: FingerState.values[json['index']],
      middle: FingerState.values[json['middle']],
      ring: FingerState.values[json['ring']],
      pinky: FingerState.values[json['pinky']],
      holdDuration: json['holdDuration'] ?? 1,
    );
  }

  Map<String, dynamic> _playlistToJson(MotionPlaylist playlist) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'createdAt': playlist.createdAt.toIso8601String(),
      'items': playlist.items.map((i) => _playlistItemToJson(i)).toList(),
    };
  }

  MotionPlaylist _playlistFromJson(Map<String, dynamic> json) {
    return MotionPlaylist(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      items:
          (json['items'] as List).map((i) => _playlistItemFromJson(i)).toList(),
    );
  }

  Map<String, dynamic> _playlistItemToJson(PlaylistItem item) {
    return {'templateId': item.templateId, 'duration': item.duration};
  }

  PlaylistItem _playlistItemFromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      templateId: json['templateId'],
      duration: json['duration'],
    );
  }
}
