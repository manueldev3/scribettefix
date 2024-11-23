import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/notebooks/presentation/state/notebook_state.dart';

class NewNotebookDialog extends ConsumerStatefulWidget {
  const NewNotebookDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NewNotebookDialogState();
}

class _NewNotebookDialogState extends ConsumerState<NewNotebookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newNoteController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final notebooksNotifier = ref.read(notebooksStateProvider.notifier);

    return Form(
      key: _formKey,
      child: Wrap(
        direction: Axis.vertical,
        spacing: 8,
        children: [
          SizedBox(
            width: context.mediaQuery.size.width - 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.lang!.createNotebook,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.primary,
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    minimumSize: const Size(16, 16),
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          SizedBox(
            width: context.mediaQuery.size.width - 128,
            child: TextFormField(
              controller: _newNoteController,
              decoration: InputDecoration(
                hintText: context.lang!.notebookNameHint,
              ),
              validator: ValidationBuilder(
                requiredMessage: 'this field is required',
              ).build(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(
                context.mediaQuery.size.width - 128,
                44,
              ),
            ),
            onPressed: () async {
              await notebooksNotifier.insertName(_newNoteController.text);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(context.lang!.createLabel),
          ),
        ],
      ),
    );
  }
}
