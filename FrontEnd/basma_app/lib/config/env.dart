// Environment configuration helper

class EnvConfig {
  final String name;
  final String baseUrl;

  const EnvConfig._(this.name, this.baseUrl);

  static const EnvConfig dev = EnvConfig._('dev', 'http://10.0.2.2:8000');
  static const EnvConfig staging = EnvConfig._(
    'staging',
    'https://staging.example.com',
  );
  static const EnvConfig prod = EnvConfig._('prod', 'https://api.example.com');

  static EnvConfig get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod':
        return EnvConfig.prod;
      case 'staging':
        return EnvConfig.staging;
      case 'dev':
      default:
        return EnvConfig.dev;
    }
  }

  @override
  String toString() => 'EnvConfig(name: $name, baseUrl: $baseUrl)';
}
