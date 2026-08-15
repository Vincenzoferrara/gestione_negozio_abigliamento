import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final inventoryQuickLoadSettings = InventoryQuickLoadSettings();

class InventoryQuickLoadSettings extends ChangeNotifier {
  static const _warehouseOptionsKey = 'inventory_quick_load_warehouses';
  static const _roomOptionsKey = 'inventory_quick_load_rooms';
  static const _rackOptionsKey = 'inventory_quick_load_racks';
  static const _shelfOptionsKey = 'inventory_quick_load_shelves';
  static const _reasonOptionsKey = 'inventory_quick_load_reasons';
  static const _defaultWarehouseKey = 'inventory_quick_load_default_warehouse';
  static const _defaultRoomKey = 'inventory_quick_load_default_room';
  static const _defaultRackKey = 'inventory_quick_load_default_rack';
  static const _defaultShelfKey = 'inventory_quick_load_default_shelf';
  static const _defaultReasonKey = 'inventory_quick_load_default_reason';
  static const _defaultReasons = <String>[
    'Carico merce',
    'Carico scaffale',
    'Rettifica positiva',
  ];

  List<String> _warehouseOptions = <String>[];
  List<String> _roomOptions = <String>[];
  List<String> _rackOptions = <String>[];
  List<String> _shelfOptions = <String>[];
  List<String> _reasonOptions = List<String>.from(_defaultReasons);
  String? _defaultWarehouse;
  String? _defaultRoom;
  String? _defaultRack;
  String? _defaultShelf;
  String _defaultReason = _defaultReasons.first;
  bool _initialized = false;

  List<String> get warehouseOptions => List.unmodifiable(_warehouseOptions);
  List<String> get roomOptions => List.unmodifiable(_roomOptions);
  List<String> get rackOptions => List.unmodifiable(_rackOptions);
  List<String> get shelfOptions => List.unmodifiable(_shelfOptions);
  List<String> get reasonOptions => List.unmodifiable(_reasonOptions);
  bool get warehouseEnabled => _warehouseOptions.isNotEmpty;
  bool get roomEnabled => _roomOptions.isNotEmpty;
  bool get rackEnabled => _rackOptions.isNotEmpty;
  bool get shelfEnabled => _shelfOptions.isNotEmpty;
  String? get defaultWarehouse => _defaultWarehouse;
  String? get defaultRoom => _defaultRoom;
  String? get defaultRack => _defaultRack;
  String? get defaultShelf => _defaultShelf;
  String get defaultReason => _defaultReason;

  Future<void> init({bool force = false}) async {
    if (_initialized && !force) return;
    final prefs = await SharedPreferences.getInstance();
    _warehouseOptions = _normalizePositiveIds(
      prefs.getStringList(_warehouseOptionsKey) ?? const <String>[],
    );
    _roomOptions = _normalize(
      prefs.getStringList(_roomOptionsKey) ?? const <String>[],
    );
    _rackOptions = _normalize(
      prefs.getStringList(_rackOptionsKey) ?? const <String>[],
    );
    _shelfOptions = _normalize(
      prefs.getStringList(_shelfOptionsKey) ?? const <String>[],
    );
    _reasonOptions = _normalize(
      prefs.getStringList(_reasonOptionsKey) ?? _defaultReasons,
    );
    if (_reasonOptions.isEmpty) {
      _reasonOptions = List<String>.from(_defaultReasons);
    }
    _defaultWarehouse = _validDefault(
      prefs.getString(_defaultWarehouseKey),
      _warehouseOptions,
    );
    _defaultRoom = _validDefault(
      prefs.getString(_defaultRoomKey),
      _roomOptions,
    );
    _defaultRack = _validDefault(
      prefs.getString(_defaultRackKey),
      _rackOptions,
    );
    _defaultShelf = _validDefault(
      prefs.getString(_defaultShelfKey),
      _shelfOptions,
    );
    _defaultReason =
        _validDefault(prefs.getString(_defaultReasonKey), _reasonOptions) ??
        _reasonOptions.first;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setWarehouseOptions(List<String> values) async {
    _warehouseOptions = _normalizePositiveIds(values);
    _defaultWarehouse = _validDefault(_defaultWarehouse, _warehouseOptions);
    await _save();
  }

  Future<void> setRoomOptions(List<String> values) async {
    _roomOptions = _normalize(values);
    _defaultRoom = _validDefault(_defaultRoom, _roomOptions);
    await _save();
  }

  Future<void> setRackOptions(List<String> values) async {
    _rackOptions = _normalize(values);
    _defaultRack = _validDefault(_defaultRack, _rackOptions);
    await _save();
  }

  Future<void> setShelfOptions(List<String> values) async {
    _shelfOptions = _normalize(values);
    _defaultShelf = _validDefault(_defaultShelf, _shelfOptions);
    await _save();
  }

  Future<void> setReasonOptions(List<String> values) async {
    _reasonOptions = _normalize(values);
    if (_reasonOptions.isEmpty) {
      _reasonOptions = List<String>.from(_defaultReasons);
    }
    _defaultReason =
        _validDefault(_defaultReason, _reasonOptions) ?? _reasonOptions.first;
    await _save();
  }

  Future<void> setDefaults({
    String? warehouse,
    String? room,
    String? rack,
    String? shelf,
    String? reason,
  }) async {
    _defaultWarehouse = _validDefault(warehouse, _warehouseOptions);
    _defaultRoom = _validDefault(room, _roomOptions);
    _defaultRack = _validDefault(rack, _rackOptions);
    _defaultShelf = _validDefault(shelf, _shelfOptions);
    _defaultReason =
        _validDefault(reason, _reasonOptions) ?? _reasonOptions.first;
    await _save();
  }

  Future<void> rememberLocation({
    int? warehouseId,
    String? room,
    String? rack,
    String? shelf,
  }) async {
    _warehouseOptions = _remember(_warehouseOptions, warehouseId?.toString());
    _roomOptions = _remember(_roomOptions, room);
    _rackOptions = _remember(_rackOptions, rack);
    _shelfOptions = _remember(_shelfOptions, shelf);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_warehouseOptionsKey, _warehouseOptions);
    await prefs.setStringList(_roomOptionsKey, _roomOptions);
    await prefs.setStringList(_rackOptionsKey, _rackOptions);
    await prefs.setStringList(_shelfOptionsKey, _shelfOptions);
    await prefs.setStringList(_reasonOptionsKey, _reasonOptions);
    await _setOptional(prefs, _defaultWarehouseKey, _defaultWarehouse);
    await _setOptional(prefs, _defaultRoomKey, _defaultRoom);
    await _setOptional(prefs, _defaultRackKey, _defaultRack);
    await _setOptional(prefs, _defaultShelfKey, _defaultShelf);
    await prefs.setString(_defaultReasonKey, _defaultReason);
    notifyListeners();
  }
}

List<String> parseInventoryQuickLoadOptions(String raw) {
  return _normalize(raw.split(RegExp(r'[,;\n]')));
}

List<String> _normalize(Iterable<String> values) {
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

List<String> _normalizePositiveIds(Iterable<String> values) {
  return _normalize(values)
      .where((value) {
        final parsed = int.tryParse(value);
        return parsed != null && parsed > 0;
      })
      .toList(growable: false);
}

String? _validDefault(String? value, List<String> options) {
  final normalized = value?.trim();
  return normalized != null && options.contains(normalized) ? normalized : null;
}

List<String> _remember(List<String> current, String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return current;
  return <String>[
    normalized,
    ...current.where((item) => item != normalized),
  ].take(20).toList(growable: false);
}

Future<void> _setOptional(
  SharedPreferences prefs,
  String key,
  String? value,
) async {
  if (value == null || value.isEmpty) {
    await prefs.remove(key);
  } else {
    await prefs.setString(key, value);
  }
}
