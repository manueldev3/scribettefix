import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_state.g.dart';

/// Locale State
@riverpod
class LocaleState extends _$LocaleState {
  @override
  Locale? build() {
    return null;
  }

  void change(Locale locale) {
    state = locale;
  }
}
