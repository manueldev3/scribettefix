import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';
import 'package:scribettefix/feature/auth/presentation/states/auth_state.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/files/domain/entities/file_entity.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:scribettefix/feature/notebooks/domain/entities/notebook.dart';
import 'package:scribettefix/feature/notebooks/presentation/common/new_note_dialog.dart';
import 'package:scribettefix/feature/notebooks/presentation/state/notebook_state.dart';
import 'package:scribettefix/feature/notes/presentation/pages/note_page.dart';
import 'package:scribettefix/feature/notes/presentation/states/note_state.dart';

class NotebooksPage extends ConsumerStatefulWidget {
  const NotebooksPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NotebooksPageState();
}

class _NotebooksPageState extends ConsumerState<NotebooksPage> {
  Notebook? notebook;
  Map<String, List<Map<String, String>>> itemsByCategory = {};
  String name = '';
  List<FileEntity>? filteredItems;

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredItems = null;
      });
      return;
    }

    final notebooks = ref.watch(notebooksStateProvider).value ?? [];
    List<FileEntity> filteredList = [];
    if (notebook == null) {
      for (var notebook in notebooks) {
        final files = notebook.files.where((item) {
          return item.title.toLowerCase().contains(query.toLowerCase());
        });

        if (files.isNotEmpty) {
          filteredList.addAll(files);
        }
      }
    } else {
      final files = notebook!.files.where((item) {
        return item.title.toLowerCase().contains(query.toLowerCase());
      });

      if (files.isNotEmpty) {
        filteredList.addAll(files);
      }
    }
    setState(() {
      filteredItems = filteredList;
    });
  }

  Future<void> _loadData() async {
    final noteNotifier = ref.read(noteStateProvider.notifier);
    await noteNotifier.syncNotesWithSQLite();

    User? user = auth.currentUser;
    final userDoc = await firestore
        .collection(
          Collection.users.name,
        )
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        name = userDoc['name'] ?? '';
      });
    }

    final notebooks = await _dbHelper.getNotebooks();
    final Map<String, List<Map<String, String>>> tempItemsByCategory = {};

    for (var notebook in notebooks) {
      final notebookId = notebook['id'] as int;
      final notebookName = notebook['name'] as String;
      final files = await _dbHelper.getFiles(notebookId);

      tempItemsByCategory[notebookName] = files.map((file) {
        return {
          'title': file['title'] as String,
          'date': file['date'] as String,
        };
      }).toList();
    }

    setState(() {
      itemsByCategory = tempItemsByCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authChanges = ref.watch(authChangesProvider);
    final currentUser = authChanges.value;
    final notebooksState = ref.watch(notebooksStateProvider);

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
                    onChanged: (text) {
                      search(text);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                notebooksState.when(
                  data: (data) {
                    return PopupMenuButton<int>(
                      initialValue: notebook?.id ?? -1,
                      icon: const Icon(
                        MingCuteIcons.mgcFilterFill,
                      ),
                      iconColor: context.colorScheme.primary,
                      itemBuilder: (context) {
                        return List<PopupMenuItem<int>>.from([
                          PopupMenuItem<int>(
                            value: -1,
                            child: Text(context.lang!.filterDropdown),
                          ),
                          ...data.map(
                            (notebook) {
                              return PopupMenuItem<int>(
                                value: notebook.id,
                                child: Text(notebook.name),
                              );
                            },
                          ),
                        ]);
                      },
                      onSelected: (value) {
                        setState(() {
                          notebook = value == -1
                              ? null
                              : data.firstWhere(
                                  (item) => item.id == value,
                                );
                        });
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
      body: filteredItems != null && filteredItems!.isEmpty
          ? Center(
              child: Text(
                context.lang!.notResultsFound,
                style: GoogleFonts.montserrat(
                  color: context.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          : notebooksState.when(
              data: (data) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: filteredItems != null && filteredItems!.isNotEmpty
                      ? filteredItems!.length
                      : notebook != null
                          ? 1
                          : data.length,
                  separatorBuilder: (context, index) {
                    return const Divider();
                  },
                  itemBuilder: (context, index) {
                    if (filteredItems != null && filteredItems!.isNotEmpty) {
                      final file = filteredItems![index];
                      return ListTile(
                        title: Text(file.title),
                        subtitle: Text(file.date),
                        onTap: () {},
                      );
                    }

                    final book = notebook ?? data[index];
                    return InkWell(
                      onLongPress: () {
                        _showNotebookDialog(book.name);
                      },
                      child: ExpansionTile(
                        title: Text(book.name),
                        children: List<Widget>.from(
                          book.files.map(
                            (file) {
                              return ListTile(
                                title: Text(file.title),
                                subtitle: Text(file.date),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) {
                                      return NotePage(note: file);
                                    }),
                                  );
                                },
                                onLongPress: () {
                                  _showNoteDialog(
                                    file: file,
                                    notebooks: data,
                                  );
                                },
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

  void _showNotebookDialog(String title) async {
    final notebookNotifier = ref.read(notebooksStateProvider.notifier);
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1e2337),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.lang!
                      .titleInAlertDialogOptionsNotebook, //  'Choose an action for this notebook.' // titleInAlertDialogOptionsNotebook
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF545A78),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop('rename');
                  },
                  icon: const Icon(MingCuteIcons.mgcEdit2Fill),
                  label: Text(context.lang!.editLabel),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop('delete');
                  },
                  icon: const Icon(MingCuteIcons.mgcDelete3Fill),
                  label: Text(context.lang!.deleteLabel),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      if (context.mounted) {
        final ctxt = context;
        switch (result) {
          case 'rename':
            showDialog(
              context: ctxt,
              builder: (BuildContext context) {
                final notebookNameControllerEdit = TextEditingController();
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  backgroundColor: Colors.white,
                  title: Text(
                    ctxt.lang!.renameNotebook(title),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1e2337),
                    ),
                  ),
                  content: TextField(
                    controller: notebookNameControllerEdit,
                    cursorColor: const Color(0xFF1e2337),
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF1e2337),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      hintText: context.lang!.newNameHint,
                      hintStyle: GoogleFonts.montserrat(
                        color: const Color(0xFF545A78),
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF545A78),
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showNotebookDialog(title);
                            },
                            icon: const Icon(Icons.cancel),
                            label: Text(context.lang!.cancelLabel),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              await notebookNotifier.rename(
                                notebookNameControllerEdit.text.trim(),
                                title: title,
                              );

                              notebookNameControllerEdit.clear();

                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(MingCuteIcons.mgcEdit2Fill),
                            label: Text(context.lang!.renameLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
            break;
          case 'delete':
            final ctxt = context;
            showDialog(
              context: ctxt,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  backgroundColor: Colors.white,
                  title: Text(
                    ctxt.lang!.confirmDeleteTitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1e2337),
                    ),
                  ),
                  content: Text(
                    ctxt.lang!.sureAboutDelete(title),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: const Color(0xFF545A78),
                    ),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showNotebookDialog(title);
                            },
                            icon: const Icon(Icons.cancel),
                            label: Text(ctxt.lang!.cancelLabel),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              notebookNotifier.delete(title);
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.delete),
                            label: Text(context.lang!.deleteLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
            break;
        }
      }
    }
  }

  Future<void> _showNoteDialog({
    required FileEntity file,
    required List<Notebook> notebooks,
  }) async {
    final notebooksNotifier = ref.read(notebooksStateProvider.notifier);
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            file.title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1e2337),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.lang!.titleInAlertDialogOptionsNote,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF545A78),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return NotePage(note: file);
                        },
                      ),
                    );
                  },
                  icon: const Icon(MingCuteIcons.mgcEdit2Fill),
                  label: Text(context.lang!.editLabel),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop('move');
                  },
                  icon: const Icon(MingCuteIcons.mgcRightFill),
                  label: Text(context.lang!.moveLabel),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop('delete');
                  },
                  icon: const Icon(Icons.delete),
                  label: Text(context.lang!.deleteLabel),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      switch (result) {
        case 'move':
          if (context.mounted) {
            final ctxt = context;
            showDialog(
              context: ctxt,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  backgroundColor: Colors.white,
                  title: Text(
                    ctxt.lang!.moveNoteTitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1e2337),
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: notebooks.length,
                      itemBuilder: (context, index) {
                        final book = notebooks[index];
                        return ListTile(
                          title: Text(
                            book.name == "(Not Assignment)"
                                ? ctxt.lang!.notAssignmentCategory
                                : book.name,
                          ),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await notebooksNotifier.moveToFolder(file, book);
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
          break;
        case 'delete':
          if (context.mounted) {
            final ctxt = context;
            showDialog(
              context: ctxt,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  backgroundColor: Colors.white,
                  title: Text(
                    ctxt.lang!.confirmDeleteTitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1e2337),
                    ),
                  ),
                  content: Text(
                    ctxt.lang!.sureAboutDelete(file.title),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: const Color(0xFF545A78),
                    ),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showNoteDialog(
                                file: file,
                                notebooks: notebooks,
                              );
                            },
                            icon: const Icon(Icons.cancel),
                            label: Text(ctxt.lang!.cancelLabel),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await notebooksNotifier.deleteNote(file);
                            },
                            icon: const Icon(Icons.delete),
                            label: Text(ctxt.lang!.deleteLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }
          break;
      }
    }
  }
}
