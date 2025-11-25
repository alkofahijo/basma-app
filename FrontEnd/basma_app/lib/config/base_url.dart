// Central base URL derived from compile-time environment.
import 'env.dart';

// Use `--dart-define=ENV=prod` (or staging/dev) when building to select environment.
final String kBaseUrl = EnvConfig.current.baseUrl;
