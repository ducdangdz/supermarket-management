import 'team_api.dart';
import '../../features/auth/data/account_auth_api.dart';

String evidenceUrl(String path) => path.startsWith('/')
    ? Uri.parse(accountApiBaseUrl).resolve(path).toString()
    : path;
Map<String, String>? evidenceHeaders(String path) {
  final uri = Uri.tryParse(evidenceUrl(path));
  final base = Uri.parse(accountApiBaseUrl);
  if (uri == null ||
      !uri.hasScheme ||
      uri.origin != base.origin ||
      TeamApi.active == null)
    return null;
  return {'Authorization': 'Bearer ${TeamApi.active!.token}'};
}
