// ignore: deprecated_member_use
import 'dart:html' as html;

void downloadCsv(String name, String content) {
  final blob = html.Blob(['\uFEFF$content'], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = name;
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future.delayed(
    const Duration(seconds: 1),
    () => html.Url.revokeObjectUrl(url),
  );
}
