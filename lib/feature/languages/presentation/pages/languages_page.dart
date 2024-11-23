import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/locale/presentation/state/locale_state.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguagesPage extends ConsumerStatefulWidget {
  const LanguagesPage({super.key});

  static String path = 'languages';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LanguagesPageState();
}

class _LanguagesPageState extends ConsumerState<LanguagesPage> {
  bool showSearchBar = false;
  List<Locale>? filteredLanguage;

  Future<void> search(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredLanguage = null;
      });
      return;
    }

    const supportedLocales = AppLocalizations.supportedLocales;

    final locales = [];

    for (final locale in supportedLocales) {
      final lang = await AppLocalizations.delegate.load(locale);
      locales.add({
        'locale': locale,
        'name': lang.lang,
        'countryName': lang.countryName,
      });
    }

    final result = locales
        .where((element) {
          return element['name']!.toLowerCase().contains(query.toLowerCase()) ||
              element['countryName']!
                  .toLowerCase()
                  .contains(query.toLowerCase());
        })
        .map((element) => element['locale'] as Locale)
        .toList();

    setState(() {
      filteredLanguage = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    const supportedLocales = AppLocalizations.supportedLocales;
    final selectedLocale = ref.watch(localeStateProvider);
    final localeNotifier = ref.read(localeStateProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            MingCuteIcons.mgcLeftFill,
            color: Color(0xFFC9CAD1),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(context.lang!.languageName),
        backgroundColor: Colors.white,
        actions: [
          if (!showSearchBar)
            IconButton(
              icon: Icon(
                MingCuteIcons.mgcSearch2Fill,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  showSearchBar = !showSearchBar;
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(showSearchBar ? 56 : 0),
          child: showSearchBar
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: context.lang!.searchBarText,
                      prefixIcon: const Icon(MingCuteIcons.mgcSearch2Fill),
                      suffixIcon: IconButton(
                        icon: Icon(
                          MingCuteIcons.mgcCloseFill,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            showSearchBar = false;
                            filteredLanguage = null;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      search(value);
                    },
                  ),
                )
              : Container(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLanguage?.length ?? supportedLocales.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final locale = filteredLanguage?[index] ?? supportedLocales[index];
          return FutureBuilder<AppLocalizations>(
            future: AppLocalizations.delegate.load(locale),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final lang = snapshot.data!;
                return ListTile(
                  onTap: () {},
                  title: Text('${lang.lang} ${lang.countryName}'),
                  trailing: Switch(
                    value:
                        (selectedLocale ?? Locale(context.lang!.localeName)) ==
                            locale,
                    onChanged: (value) {
                      localeNotifier.change(locale);
                    },
                  ),
                );
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        },
      ),
    );
  }
}
