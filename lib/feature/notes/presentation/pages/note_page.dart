import 'dart:io';
import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';
import 'package:scribettefix/feature/chat_bot/presentation/pages/chat_bot_page.dart';
import 'package:scribettefix/feature/files/domain/entities/file_entity.dart';
import 'package:scribettefix/feature/flash_card/presentation/pages/flash_card_page.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:scribettefix/feature/mock_test/presentation/pages/mock_test_page.dart';
import 'package:scribettefix/feature/notebooks/presentation/state/notebook_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as hpw;
import 'package:pdf/widgets.dart' as pw;

class NotePage extends ConsumerStatefulWidget {
  const NotePage({
    super.key,
    required this.note,
  });

  final FileEntity note;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdatedSubscription;
  List<ProductDetails> _products = [];
  bool _isSubscribed = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isEditing = false;

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();

    _titleController.text = widget.note.title;
    _loadNoteContent();
    _initSubscription();
  }

  @override
  void dispose() {
    if (_purchaseUpdatedSubscription != null) {
      _purchaseUpdatedSubscription!.cancel();
    }
    super.dispose();
  }

  Future<void> _initSubscription() async {
    debugPrint("Iniciando suscripción...");
    final bool available = await _inAppPurchase.isAvailable();
    debugPrint("Disponibilidad de compras dentro de la app: $available");

    if (available) {
      await _getProductDetails();
      _purchaseUpdatedSubscription =
          _inAppPurchase.purchaseStream.listen((purchaseDetailsList) async {
        for (final purchaseDetails in purchaseDetailsList) {
          debugPrint("Estado de la compra: ${purchaseDetails.status}");
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            debugPrint("Compra exitosa, activando suscripción.");
            // Suponiendo que la compra se ha realizado exitosamente
            String? email = auth.currentUser?.email;
            DateTime purchaseDate = DateTime.now();
            DateTime expirationDate = purchaseDate.add(const Duration(
                days: 30)); // Asumiendo que la suscripción dura 30 días

            // Almacena la información de la suscripción en Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(email)
                .collection('subscriptions')
                .doc(
                    'subscriptionInfo') // Puedes usar un ID específico o 'subscriptionInfo'
                .set({
              'isSubscribed': true,
              'purchaseDate': purchaseDate,
              'expirationDate': expirationDate,
            });
            setState(() {
              _isSubscribed = true;
            });
          } else {
            debugPrint("Compra no completada: ${purchaseDetails.status}");
          }
        }
      });
      await _verifyPurchase(); // Verifica si ya hay una suscripción activa
    } else {
      debugPrint("Compras dentro de la app no disponibles.");
    }
  }

  Future<void> _getProductDetails() async {
    debugPrint("Obteniendo detalles del producto...");
    List<String> productIds = ['monthly'];
    ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds.toSet());

    if (response.error != null) {
      debugPrint(
          "Error al recuperar los detalles del producto: ${response.error}");
      return;
    }

    if (response.productDetails.isEmpty) {
      debugPrint("No se encontraron productos disponibles.");
      return;
    }

    debugPrint(
        "Productos obtenidos correctamente: ${response.productDetails.length}");
    setState(() {
      _products = response.productDetails;
    });
  }

  Future<void> _verifyPurchase() async {
    debugPrint("Verificando compras previas...");
    final Stream<List<PurchaseDetails>> purchaseStream =
        _inAppPurchase.purchaseStream;
    final purchases = await purchaseStream.first;

    for (final purchaseDetails in purchases) {
      debugPrint("Verificando compra con estado: ${purchaseDetails.status}");
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        debugPrint("Suscripción encontrada, activando.");
        setState(() {
          _isSubscribed = true;
        });
        return;
      }
    }
    debugPrint("No se encontraron suscripciones activas.");
  }

  Future<void> _purchaseSubscription() async {
    debugPrint("Iniciando proceso de compra...");

    if (_products.isEmpty) {
      debugPrint("No hay productos disponibles para la compra.");
      return;
    }

    ProductDetails productDetails = _products[0];
    PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    try {
      debugPrint("Intentando comprar el producto: ${productDetails.id}");
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint("Proceso de compra iniciado.");
    } catch (e) {
      debugPrint("Error iniciando la compra: $e");
    }

    // Actualiza el estado local
    setState(() {
      _isSubscribed = true;
      // También puedes guardar la fecha de vencimiento si es necesario
    });
  }

  Future<void> _loadNoteContent() async {
    final content = await _dbHelper.getArticleContentByTitle(widget.note.title);
    setState(() {
      _contentController.text = content ?? '';
    });
  }

  Future<void> _saveNoteContent() async {
    String oldTitle = widget.note.title;
    String newTitle = _titleController.text;
    String newContent = _contentController.text;

    await _dbHelper.updateArticle(oldTitle, newTitle, newContent);

    String? email = auth.currentUser?.email;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('notes')
        .where('title', isEqualTo: oldTitle)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot noteDoc = querySnapshot.docs.first;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('notes')
          .doc(noteDoc.id)
          .update({
        'title': newTitle,
        'content': newContent,
      });
    }
  }

  Future<void> shareDocument(BuildContext context) async {
    try {
      log('Starting document sharing process.');
      log(_contentController.text);

      if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
        throw Exception('Title or content is empty.');
      }

      // Convert Markdown to HTML
      final htmlContent = markdownToHtml(_contentController.text);

      // Create PDF
      final pdf = pw.Document();

      try {
        log('Creating PDF content...');

        List<pw.Widget> widgets = await hpw.HTMLToPdf().convert(htmlContent);

        pdf.addPage(
          pw.MultiPage(
            maxPages: 200,
            build: (context) {
              return [
                pw.Text(_titleController.text,
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                ...widgets,
              ];
            },
          ),
        );

        log('PDF content created successfully.');
      } catch (e) {
        log('Error creating PDF content: $e');
        return;
      }

      // Save the PDF
      String filePath;
      try {
        log('Saving the PDF...');
        final directory = await getTemporaryDirectory();
        filePath = '${directory.path}/${_titleController.text}.pdf';
        final file = File(filePath);

        final pdfBytes = await pdf.save();

        await file.writeAsBytes(pdfBytes);
        log('PDF saved to $filePath without encryption.');
      } catch (e) {
        log('Error saving the PDF: $e');
        return;
      }

      // Share the PDF
      try {
        log('Sharing the PDF...');
        await Share.shareXFiles([XFile(filePath)],
            text: 'Sharing ${_titleController.text} note');
        log('PDF shared successfully.');
      } catch (e) {
        log('Error sharing the PDF: $e');
      }
    } catch (e) {
      log('Unexpected error: $e');
    }
  }

  String markdownToHtml(String markdown) {
    final htmlContent = md.markdownToHtml(markdown);
    return '''
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; }
          h1 { font-size: 24px; font-weight: bold; }
          h2 { font-size: 20px; font-weight: bold; }
          ul, ol { padding-left: 20px; }
        </style>
      </head>
      <body>
        $htmlContent
      </body>
    </html>
  ''';
  }

  List<pw.Widget> markdownToPdf(List<md.Node> nodes) {
    List<pw.Widget> widgets = [];

    for (var node in nodes) {
      if (node is md.Element) {
        switch (node.tag) {
          case 'h1':
            widgets.add(pw.Text(node.textContent,
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)));
            break;
          case 'h2':
            widgets.add(pw.Text(node.textContent,
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)));
            break;
          case 'p':
            widgets.add(pw.Text(node.textContent));
            break;
          case 'ul':
            widgets.add(pw.Column(
              children: node.children!.map((child) {
                if (child is md.Element && child.tag == 'li') {
                  return pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(child: pw.Text(child.textContent)),
                    ],
                  );
                }
                return pw.Container();
              }).toList(),
            ));
            break;
          case 'ol':
            int index = 1;
            widgets.add(pw.Column(
              children: node.children!.map((child) {
                if (child is md.Element && child.tag == 'li') {
                  return pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${index++}. ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(child: pw.Text(child.textContent)),
                    ],
                  );
                }
                return pw.Container();
              }).toList(),
            ));
            break;
          // Añade más casos según sea necesario para otros elementos Markdown
        }
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveNoteContent();
        await ref.read(notebooksStateProvider.notifier).refresh();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              MingCuteIcons.mgcLeftFill,
              color: Color(0xFFC9CAD1),
            ),
            onPressed: () async {
              await _saveNoteContent();
              await ref.read(notebooksStateProvider.notifier).refresh();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(
                MingCuteIcons.mgcTargetLine,
                color: Color(0xFFC9CAD1),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashcardsPage(
                      title: _titleController.text,
                      content: _contentController.text,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                MingCuteIcons.mgcTestTubeLine,
                color: Color(0xFFC9CAD1),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MockTestPage(
                      title: _titleController.text,
                      content: _contentController.text,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                  _isEditing
                      ? MingCuteIcons.mgcEye2Line
                      : MingCuteIcons.mgcEdit2Line,
                  color: const Color(0xFFC9CAD1)),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
            ),
            IconButton(
              icon: const Icon(MingCuteIcons.mgcChat3Line,
                  color: Color(0xFFC9CAD1)),
              onPressed: () async {
                if (_isSubscribed) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatbotPage(
                        content:
                            '${_titleController.text}\n\n${_contentController.text}',
                      ),
                    ),
                  );
                } else {
                  _purchaseSubscription();
                }
              },
            ),
            IconButton(
              icon: const Icon(MingCuteIcons.mgcShareForwardLine,
                  color: Color(0xFFC9CAD1)),
              onPressed: () {
                shareDocument(context);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  controller: _titleController,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  onChanged: (text) {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
                _isEditing
                    ? TextFormField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 20),
                        onChanged: (text) {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      )
                    : MarkdownBody(
                        selectable: false,
                        data: _contentController.text.toString(),
                        builders: {
                          'latex': LatexElementBuilder(
                            textStyle: TextStyle(
                                color: Colors.black,
                                fontFamily: GoogleFonts.notoSerif().fontFamily),
                            textScaleFactor: 1.2,
                          ),
                        },
                        extensionSet: md.ExtensionSet(
                          [
                            ...md.ExtensionSet.gitHubWeb.blockSyntaxes,
                            LatexBlockSyntax(), // LaTeX block syntax
                          ],
                          [
                            ...md.ExtensionSet.gitHubWeb.inlineSyntaxes,
                            LatexInlineSyntax(), // LaTeX inline syntax
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          backgroundColor: const Color(0xFFE8EFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF545A78)),
              ),
              Icon(
                icon,
                color: const Color(0xFF545A78),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateNoteContent(String title, String content) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final querySnapshot = await firestore
        .collection('users')
        .doc('yourUserEmail')
        .collection('notes')
        .where('title', isEqualTo: title)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await firestore
          .collection('users')
          .doc('yourUserEmail')
          .collection('notes')
          .doc(querySnapshot.docs.first.id)
          .update({'content': content});
    }
  }

// Nueva función para verificar el estado de la suscripción
  Future<void> _checkSubscriptionStatus() async {
    debugPrint("Verificando el estado de la suscripción...");
    try {
      String? email = auth.currentUser?.email;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection(
              'subscriptions') // Asegúrate de que este sea el nombre correcto de tu colección
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot subscriptionDoc = querySnapshot.docs.first;

        DateTime expirationDate =
            (subscriptionDoc['expirationDate'] as Timestamp).toDate();
        bool isSubscribed = subscriptionDoc['isSubscribed'] ?? false;

        // Verifica si la fecha de vencimiento ha pasado
        if (DateTime.now().isAfter(expirationDate)) {
          // Si ha vencido, actualiza el estado en Firestore y en la app
          await subscriptionDoc.reference
              .update({'isSubscribed': false}); // Actualiza Firestore
          setState(() {
            _isSubscribed =
                false; // Actualiza el estado de la suscripción en la app
          });
        } else {
          // La suscripción está activa
          setState(() {
            _isSubscribed =
                isSubscribed; // Actualiza el estado de la suscripción
          });
        }
      } else {
        setState(() {
          _isSubscribed = false; // No hay suscripción activa
        });
      }
    } catch (e) {
      debugPrint("Error al verificar el estado de la suscripción: $e");
      setState(() {
        _isSubscribed = false; // En caso de error, establece como no suscrito
      });
    }
  }
}
