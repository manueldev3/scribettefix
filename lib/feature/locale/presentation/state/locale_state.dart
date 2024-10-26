import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_state.g.dart';

/// Locale State
@riverpod
class LocaleState extends _$LocaleState {
  @override
  Locale? build() {
    return null;
  }

  void change(BuildContext context) {
    final currentLocale = AppLocalizations.of(context)?.localeName ?? "";
    if (currentLocale.isNotEmpty && currentLocale == "en") {
      state = const Locale("es", "CO");
    } else {
      state = const Locale("en", "US");
    }
  }
}
