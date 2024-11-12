import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/feature/auth/presentation/states/current_user_state.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final currentUserNotifier = ref.read(
      currentUserStateProvider.notifier,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang!.settingsTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    context.lang!.accountTitle,
                    style: context.textTheme.headlineSmall,
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.lang!.editProfileLabel),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.lang!.changePassword),
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    context.lang!.notificationsName,
                    style: context.textTheme.headlineSmall,
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.lang!.noteNotifications),
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.lang!.appNotifications),
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    context.lang!.othersOptions,
                    style: context.textTheme.headlineSmall,
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.lang!.languageName),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                onTap: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.lang!.logOut),
                      content: Text(context.lang!.logOutAlert),
                      actions: [
                        TextButton(
                          onPressed: Navigator.of(context).pop,
                          child: Text(
                            context.lang!.cancelLabel,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text(
                            context.lang!.logOut,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (result != null && context.mounted) {
                    currentUserNotifier.signOut();
                  }
                },
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  MingCuteIcons.mgcExitFill,
                  color: context.colorScheme.primary,
                ),
                title: Text(context.lang!.logOut),
                titleTextStyle: GoogleFonts.montserrat(
                  color: context.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
