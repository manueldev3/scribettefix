import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/feature/auth/presentation/states/auth_state.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:scribettefix/feature/notebooks/domain/entities/notebook.dart';
import 'package:scribettefix/feature/notebooks/presentation/common/new_note_dialog.dart';
import 'package:scribettefix/feature/notebooks/presentation/state/notebook_state.dart';

class NotebooksPage extends ConsumerStatefulWidget {
  const NotebooksPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NotebooksPageState();
}

class _NotebooksPageState extends ConsumerState<NotebooksPage> {
  Notebook? notebook;

  @override
  Widget build(BuildContext context) {
    final authChanges = ref.watch(authChangesProvider);
    final currentUser = authChanges.value;
    final notebooksState = ref.watch(notebooksStateProvider);
    final notebooksNotifier = ref.read(notebooksStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            CircleAvatar(
              backgroundColor: context.colorScheme.onSurface,
              backgroundImage: authChanges.isLoading
                  ? null
                  : const AssetImage('assets/logo_login.png'),
              foregroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: authChanges.isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFF7BD03)),
                    )
                  : null,
            ),
            SizedBox(
              width: context.mediaQuery.size.width * 0.6,
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: GoogleFonts.montserrat(
                    color: context.colorScheme.primary,
                    fontSize: 20,
                  ),
                  children: [
                    TextSpan(
                      text: currentUser?.displayName != null
                          ? context.lang!.helloThere1Notebook
                          : context.lang!.helloNotebook,
                    ),
                    TextSpan(
                      text: currentUser?.displayName ??
                          context.lang!.helloThere2Notebook,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const WidgetSpan(child: SizedBox(width: 8)),
                    const WidgetSpan(
                      child: Icon(
                        Icons.waving_hand,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size(
            context.mediaQuery.size.width,
            64,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: context.lang!.searchBarText,
                      prefixIcon: Icon(
                        MingCuteIcons.mgcSearch2Fill,
                        color: context.colorScheme.secondary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                notebooksState.when(
                  data: (data) {
                    return PopupMenuButton<int>(
                      initialValue: data.first.id,
                      icon: const Icon(
                        MingCuteIcons.mgcFilterFill,
                      ),
                      iconColor: context.colorScheme.primary,
                      itemBuilder: (context) {
                        return List<PopupMenuItem<int>>.from(
                          data.map(
                            (notebook) {
                              return PopupMenuItem<int>(
                                value: notebook.id,
                                child: Text(notebook.name),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  error: (error, stackTrace) {
                    log(
                      error.toString(),
                      error: error,
                      stackTrace: stackTrace,
                    );
                    return const IconButton.filled(
                      onPressed: null,
                      icon: Icon(
                        MingCuteIcons.mgcFilterFill,
                      ),
                    );
                  },
                  loading: () {
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: notebooksState.when(
        data: (data) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: data.length,
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemBuilder: (context, index) {
              final notebook = data[index];
              return Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {},
                      icon: MingCuteIcons.mgcEdit2Fill,
                      backgroundColor: context.colorScheme.secondary,
                      label: 'Update',
                    ),
                    SlidableAction(
                      onPressed: (context) {},
                      icon: MingCuteIcons.mgcDelete2Fill,
                      backgroundColor: Colors.red,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ExpansionTile(
                  title: Text(notebook.name),
                  children: List<Widget>.from(
                    notebook.files.map(
                      (file) {
                        return ListTile(
                          title: Text(file.title),
                          subtitle: Text(file.date),
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        error: (error, stackTrace) {
          log(
            error.toString(),
            error: error,
            stackTrace: stackTrace,
          );
          return Container();
        },
        loading: () {
          return Center(
            child: CircularProgressIndicator(
              color: context.colorScheme.primary,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: NewNotebookDialog(),
              );
            },
          );
        },
        child: const Icon(
          MingCuteIcons.mgcAddFill,
          size: 32,
        ),
      ),
    );
  }
}
