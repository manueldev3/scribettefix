import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_tab_state.g.dart';

@riverpod
class CurrentTabState extends _$CurrentTabState {
  @override
  int build() {
    return 0;
  }

  void change(int value) {
    state = value;
  }
}
