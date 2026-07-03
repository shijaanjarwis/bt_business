import 'item_unit_library.dart';

/// Unit presets for Maal shortcuts (Bikri/Kharid entry helpers).
abstract final class ItemUnits {
  static List<String> get presets => ItemUnitLibrary.presets;

  static String get defaultUnit => ItemUnitLibrary.defaultUnit;
}
