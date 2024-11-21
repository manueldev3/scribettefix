import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:markdown/markdown.dart' as md;

class ChatbotPage extends StatefulWidget {
  final String content;

  const ChatbotPage({super.key, required this.content});

  @override
  ChatbotPageState createState() => ChatbotPageState();
}

class ChatbotPageState extends State<ChatbotPage> {
  final GlobalKey _globalKey = GlobalKey();

  final List<Map<String, String>> _messages = [];
  final WebViewController _webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onHttpError: (HttpResponseError error) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse('https://flutter.dev'));

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Add this
  GenerativeModel? model;

  @override
  void initState() {
    super.initState();

    _messageController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
    });
    _messageController.clear();

    final response = await model?.generateContent([
      Content.text(context.lang!.indicateContext +
          _messages
              .toString()), // 'This is the context:' + _messages.toString() // indicateContext
      Content.text(userMessage)
    ]);
    String? botMessage = response?.text!.replaceAll("* ", "- ");
    botMessage = botMessage?.replaceAll("", "*");

    setState(() {
      _messages.add({'role': 'bot', 'content': botMessage!});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> suggestions = [
      {
        'text': context.lang!.keyPointsQuestion,
        'icon': MingCuteIcons.mgc_key_2_line,
      },
      {
        'text': context.lang!.summaryQuestion,
        'icon': MingCuteIcons.mgc_sparkles_2_line,
      },
      {
        'text': context.lang!.explainLikeChildQuestion,
        'icon': MingCuteIcons.mgc_baby_line,
      },
      {
        'text': context.lang!.generateOutlineQuestion,
        'icon': MingCuteIcons.mgc_task_2_line,
      },
    ];

    model = GenerativeModel(
        model: "gemini-1.5-pro",
        apiKey: 'AIzaSyDI7w8xqOS-8FrVzrHLTCdKTJilTd-pYh0',
        systemInstruction: Content.system(context.lang!.systemInstruction(widget
                .content) //  "You are a helpful assistant about this note, keep your answers short: {noteContent}" // systemInstruction
            ));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            MingCuteIcons.mgc_left_fill,
            color: Color(0xFFC9CAD1),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message['role'] == 'user';

                return RepaintBoundary(
                  key: !isUserMessage ? _globalKey : null,
                  child: ListTile(
                    title: Align(
                      alignment: isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isUserMessage
                              ? Colors.transparent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16.0),
                          border: isUserMessage
                              ? Border.all(
                                  color: const Color(0xFFA9ACBB), width: 2)
                              : null,
                        ),
                        child: message['content']!.contains('mermaid')
                            ? _buildMermaidDiagram(message['content']!)
                            : Column(
                                children: [
                                  MarkdownBody(
                                    selectable: false,
                                    data: message['content']!.trim(),
                                    builders: {
                                      'latex': LatexElementBuilder(
                                        textStyle: TextStyle(
                                            color: Colors.black,
                                            fontFamily: GoogleFonts.notoSerif()
                                                .fontFamily),
                                        textScaleFactor: 1.2,
                                      ),
                                    },
                                    extensionSet: md.ExtensionSet(
                                      [
                                        ...md.ExtensionSet.gitHubWeb
                                            .blockSyntaxes,
                                        ...md.ExtensionSet.gitHubFlavored
                                            .blockSyntaxes,
                                        ...md.ExtensionSet.commonMark
                                            .blockSyntaxes,
                                        LatexBlockSyntax(), // LaTeX block syntax
                                      ],
                                      [
                                        ...md.ExtensionSet.gitHubWeb
                                            .inlineSyntaxes,
                                        ...md.ExtensionSet.gitHubFlavored
                                            .inlineSyntaxes,
                                        ...md.ExtensionSet.commonMark
                                            .inlineSyntaxes,
                                        LatexInlineSyntax(), // LaTeX inline syntax
                                      ],
                                    ),
                                    styleSheet: MarkdownStyleSheet(
                                      h1: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                      p: const TextStyle(fontSize: 16),
                                      tableHead: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      tableBody: const TextStyle(fontSize: 14),
                                      // Personaliza otros estilos según sea necesario
                                    ),
                                  ),
                                  !isUserMessage
                                      ? Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {},
                                                icon: Icon(MdiIcons.camera)),
                                            IconButton(
                                                onPressed: () {
                                                  // Lógica para copiar el contenido
                                                  Clipboard.setData(
                                                      ClipboardData(
                                                          text: message[
                                                              'content']!));
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Contenido copiado al portapapeles')),
                                                  );
                                                },
                                                icon: Icon(
                                                    MdiIcons.clipboardText))
                                          ],
                                        )
                                      : const SizedBox()
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _messages.isEmpty
              ? Column(
                  children: suggestions.map((suggestion) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _messageController.text = suggestion['text'];
                          _sendMessage();
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 4.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          color: const Color(0xFFE8EFFF),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 8.0, right: 8.0, top: 16.0, bottom: 16.0),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                Icon(
                                  suggestion['icon'],
                                  color: const Color(0xFF262D47),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  suggestion['text'],
                                  style: const TextStyle(
                                      color: Color(0xFF262D47),
                                      fontWeight: FontWeight.w400),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Container(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    cursorColor: const Color(0xFF262D47),
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: context.lang!
                          .typeMessage, // Type a message... // typeMessage
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF262D47),
                          width: 2.0, // Border width
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(
                          color: Color(0xFFA9ACBB),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                    onSubmitted: (text) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _messageController.text.isNotEmpty
                        ? const Color(0xFF262D47)
                        : const Color(0xFFA9ACBB),
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMermaidDiagram(String content) {
    try {
      log("Este esel texto crudo: $content");

      // Extraer el código Mermaid del mensaje
      String mermaidCode = content..trim();
      RegExp regExp = RegExp(r'mermaid([\s\S]*?)```');

      // Find the first match
      final Match? match = regExp.firstMatch(mermaidCode);
      if (match != null) {
        // Extract the code without the backticks
        mermaidCode = match.group(1)?.trim() ?? '';
        log('Extracted Mermaid Code:\n$mermaidCode');
      } else {}

      log("Este ese el mermaid: $mermaidCode");

      mermaidCode = cleanMermaid(mermaidCode);

      // Cargar el HTML directamente en el WebView
      return FutureBuilder<String>(
        future: _generateHtml(mermaidCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text('Error loading diagram');
          } else {
            // Cargar el contenido HTML directamente como una cadena
            _webViewController.loadHtmlString(snapshot.data!);
            return SizedBox(
              height: 300, // Establecer un tamaño fijo para el WebView
              child: WebViewWidget(controller: _webViewController),
            );
          }
        },
      );
    } catch (e) {
      // Imprimir cualquier error de sintaxis u otro tipo de error
      return const Text('Ocurrió un error al generar el diagrama');
    }
  }

  Future<String> _generateHtml(String mermaidCode) async {
    // Crear el contenido HTML con el marcador adecuado
    log("antes del mermaid:ß $mermaidCode");
    String templateHtml = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mermaid Diagram</title>
    <script type="module">
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.esm.min.mjs';
        mermaid.initialize({ startOnLoad: true });
    </script>
</head>
<body>
    <div class="mermaid">
        $mermaidCode
    </div>
</body>
</html>
""";
    log(templateHtml);
    return templateHtml; // Devolver el HTML generado
  }
}

String cleanMermaid(String mermaidCode) {
  // Eliminar líneas vacías
  mermaidCode = mermaidCode
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .join('\n');

  // Eliminar comentarios (suponiendo que los comentarios empiezan con %%)
  mermaidCode = mermaidCode
      .split('\n')
      .where((line) => !line.trim().startsWith('%%'))
      .join('\n');

  // Agregar comillas a los elementos dentro de () y {} de forma independiente
  // Para los paréntesis ()
  mermaidCode = mermaidCode.replaceAllMapped(RegExp(r'\((.*?)\)'), (match) {
    String content = match.group(1) ?? '';
    // Eliminar comillas internas antes de añadir las externas
    content = content.replaceAll('"', '');
    return '("$content")';
  });

  // Para las llaves {}
  mermaidCode = mermaidCode.replaceAllMapped(RegExp(r'\{(.*?)\}'), (match) {
    String content = match.group(1) ?? '';
    // Eliminar comillas internas antes de añadir las externas
    content = content.replaceAll('"', '');
    return '{"$content"}';
  });

  return mermaidCode.trim();
}
