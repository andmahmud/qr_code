import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Code Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QRCodeGenerator(),
    );
  }
}

class QRCodeGenerator extends StatefulWidget {
  const QRCodeGenerator({super.key});

  @override
  State<QRCodeGenerator> createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<QRCodeGenerator> {
  final TextEditingController _controller = TextEditingController();
  String? _qrImageUrl;

  Future<void> _generateQRCode(String data) async {
    final baseUrl = 'https://api.qrserver.com/v1/create-qr-code/';
    final url = Uri.parse('$baseUrl?data=$data&size=200x200');

    setState(() {
      _qrImageUrl = url.toString();
    });
  }

  Future<void> _pasteFromClipboard() async {
    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null) {
      setState(() {
        _controller.text = clipboardData.text!;
      });
    }
  }

  Future<void> _downloadQRCodeAsPDF() async {
    if (_qrImageUrl == null) return;

    try {
      // Fetch the QR code image
      final response = await http.get(Uri.parse(_qrImageUrl!));
      if (response.statusCode == 200) {
        // Create a PDF document
        final pdf = pw.Document();

        // Add the QR code image to the PDF
        final image = pw.MemoryImage(response.bodyBytes);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(
              child: pw.Image(image),
            ),
          ),
        );

        // Get the application's documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/qr_code.pdf';

        // Save the PDF
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        // Show success message
        Fluttertoast.showToast(
          msg: 'QR Code saved as PDF: $filePath',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to download QR Code.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('QR Code Generator')),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Paste The Link',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste from clipboard',
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _generateQRCode(_controller.text);
                }
              },
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 40),
            if (_qrImageUrl != null)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0), // Space between QR and border
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 4),
                      borderRadius: BorderRadius.circular(8), // Optional rounded border
                    ),
                    child: Image.network(
                      _qrImageUrl!,
                      height: 200,
                      width: 200,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const CircularProgressIndicator();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _downloadQRCodeAsPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Download as PDF'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
