import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TextMessage extends StatefulWidget {
  final String message;

  const TextMessage({Key? key, required this.message}) : super(key: key);

  @override
  _TextMessageState createState() => _TextMessageState();
}

int computeNumberOfLines(String text, double maxWidth, TextStyle style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: null,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);

  return textPainter.computeLineMetrics().length;
}

class _TextMessageState extends State<TextMessage> {
  final RegExp linkRegExp = RegExp(
    r"((https?:\/\/)|www\.)[a-zA-Z0-9-._~:/?#[\]@!$&'()*+,;=%]+",
  );

  int linesToShow = 15;

  @override
  Widget build(BuildContext context) {
    const TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 16);
    const TextStyle linkStyle = TextStyle(
      color: Colors.blue,
      fontSize: 16,
      decoration: TextDecoration.underline,
    );

    return InkWell(
      onTap: () async{
        final directory = await getApplicationDocumentsDirectory();
        final task = DownloadTask(
            // url: 'https://testfile.org/files-5GB',
            url: 'https://www.africau.edu/images/default/sample.pdf',
            // url: 'https://mmg.whatsapp.net/v/t62.7161-24/35081055_886756139427348_3444035716031257052_n.enc?ccb=11-4&oh=01_AdSmbWKKPFRcoZHxqPe_PZfAjFlInO8PG5B7svcosBR8FQ&oe=65AB98EA&_nc_sid=5e03e0&mms3=true',
            // urlQueryParameters: {'q': 'pizza'},
            filename: 'results.pdf',
            // headers: {'myHeader': 'value'},
            directory: directory.path,
            updates: Updates.statusAndProgress,
            // request status and progress updates
            // requiresWiFi: true,
            retries: 5,
            allowPause: true,
            metaData: 'data for me');

// Start download, and wait for result. Show progress and status changes
// while downloading
        final result = await FileDownloader().download(task,
            onProgress: (progress) => print('Progress: ${progress * 100}%'),
            onStatus: (status) => print('Status: $status')
        );
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int totalLines = computeNumberOfLines(
              widget.message, constraints.maxWidth, defaultStyle);

          String displayedMessage;
          List<TextSpan> displayedTextSpans = [];

          if (totalLines <= linesToShow) {
            displayedMessage = widget.message;
          } else {
            List<String> lines = widget.message.split('\n');
            displayedMessage = lines.take(linesToShow).join('\n') + "...";
          }

          Iterable<RegExpMatch> matches = linkRegExp.allMatches(displayedMessage);
          int lastMatchEnd = 0;
          for (var match in matches) {
            displayedTextSpans.add(
              TextSpan(
                text: displayedMessage.substring(lastMatchEnd, match.start),
                style: defaultStyle,
              ),
            );
            displayedTextSpans.add(
              TextSpan(
                text: displayedMessage.substring(match.start, match.end),
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    String url =
                        displayedMessage.substring(match.start, match.end);
                    if (!url.startsWith('http')) {
                      url = 'http://$url';
                    }
                    try {
                      await launchUrl(Uri.parse(url));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not launch $url')),
                      );
                    }
                  },
              ),
            );
            lastMatchEnd = match.end;
          }
          if (lastMatchEnd < displayedMessage.length) {
            displayedTextSpans.add(
              TextSpan(
                text: displayedMessage.substring(lastMatchEnd),
                style: defaultStyle,
              ),
            );
          }

          if (totalLines > linesToShow) {
            return Wrap(
              children: [
                RichText(text: TextSpan(children: displayedTextSpans)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      linesToShow += 30;
                    });
                  },
                  child: const Text(
                    "Read More",
                    style: TextStyle(color: Colors.lightBlue),
                  ),
                ),
              ],
            );
          } else {
            return RichText(text: TextSpan(children: displayedTextSpans));
          }
        },
      ),
    );
  }
}
