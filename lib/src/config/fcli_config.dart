/// State management options supported by fcli.
enum StateManagement {
  riverpod('riverpod'),
  bloc('bloc'),
  provider('provider');

  const StateManagement(this.value);
  final String value;

  static StateManagement fromString(String value) {
    return StateManagement.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => StateManagement.riverpod,
    );
  }
}

/// Router options supported by fcli.
enum RouterOption {
  goRouter('go_router'),
  autoRoute('auto_route');

  const RouterOption(this.value);
  final String value;

  static RouterOption fromString(String value) {
    return RouterOption.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => RouterOption.goRouter,
    );
  }
}

/// Platform options for Flutter projects.
enum Platform {
  android('android'),
  ios('ios'),
  web('web'),
  macos('macos'),
  windows('windows'),
  linux('linux');

  const Platform(this.value);
  final String value;

  static Platform fromString(String value) {
    return Platform.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => Platform.android,
    );
  }

  static List<Platform> fromStringList(List<dynamic> values) {
    return values.map((v) => fromString(v.toString())).toList();
  }
}

/// Configuration model for fcli projects.
class FcliConfig {
  const FcliConfig({
    required this.projectName,
    this.org = 'com.example',
    this.stateManagement = StateManagement.riverpod,
    this.router = RouterOption.goRouter,
    this.useFreezed = true,
    this.useDioClient = true,
    this.platforms = const [Platform.android, Platform.ios],
    this.features = const ['home'],
    this.generateTests = true,
    this.l10n = false,
  });

  /// Creates a config from JSON map.
  factory FcliConfig.fromJson(Map<String, dynamic> json) {
    return FcliConfig(
      projectName: json['projectName'] as String? ?? 'my_app',
      org: json['org'] as String? ?? 'com.example',
      stateManagement: StateManagement.fromString(
        json['stateManagement'] as String? ?? 'riverpod',
      ),
      router: RouterOption.fromString(
        json['router'] as String? ?? 'go_router',
      ),
      useFreezed: json['useFreezed'] as bool? ?? true,
      useDioClient: json['useDioClient'] as bool? ?? true,
      platforms: json['platforms'] != null
          ? Platform.fromStringList(json['platforms'] as List<dynamic>)
          : const [Platform.android, Platform.ios],
      features: json['features'] != null
          ? (json['features'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : const ['home'],
      generateTests: json['generateTests'] as bool? ?? true,
      l10n: json['l10n'] as bool? ?? false,
    );
  }

  /// Default configuration.
  factory FcliConfig.defaults(String projectName) => FcliConfig(
        projectName: projectName,
      );

  final String projectName;
  final String org;
  final StateManagement stateManagement;
  final RouterOption router;
  final bool useFreezed;
  final bool useDioClient;
  final List<Platform> platforms;
  final List<String> features;
  final bool generateTests;
  final bool l10n;

  /// Converts config to JSON map.
  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'org': org,
        'stateManagement': stateManagement.value,
        'router': router.value,
        'useFreezed': useFreezed,
        'useDioClient': useDioClient,
        'platforms': platforms.map((p) => p.value).toList(),
        'features': features,
        'generateTests': generateTests,
        'l10n': l10n,
      };

  /// Creates a copy with updated values.
  FcliConfig copyWith({
    String? projectName,
    String? org,
    StateManagement? stateManagement,
    RouterOption? router,
    bool? useFreezed,
    bool? useDioClient,
    List<Platform>? platforms,
    List<String>? features,
    bool? generateTests,
    bool? l10n,
  }) =>
      FcliConfig(
        projectName: projectName ?? this.projectName,
        org: org ?? this.org,
        stateManagement: stateManagement ?? this.stateManagement,
        router: router ?? this.router,
        useFreezed: useFreezed ?? this.useFreezed,
        useDioClient: useDioClient ?? this.useDioClient,
        platforms: platforms ?? this.platforms,
        features: features ?? this.features,
        generateTests: generateTests ?? this.generateTests,
        l10n: l10n ?? this.l10n,
      );

  /// Platform strings for flutter create command.
  List<String> get platformStrings => platforms.map((p) => p.value).toList();

  /// Whether the project uses Riverpod.
  bool get usesRiverpod => stateManagement == StateManagement.riverpod;

  /// Whether the project uses Bloc.
  bool get usesBloc => stateManagement == StateManagement.bloc;

  /// Whether the project uses Provider.
  bool get usesProvider => stateManagement == StateManagement.provider;

  /// Whether the project uses GoRouter.
  bool get usesGoRouter => router == RouterOption.goRouter;

  /// Whether the project uses AutoRoute.
  bool get usesAutoRoute => router == RouterOption.autoRoute;

  @override
  String toString() => 'FcliConfig(projectName: $projectName, org: $org, '
      'stateManagement: ${stateManagement.value}, router: ${router.value}, '
      'useFreezed: $useFreezed, platforms: $platformStrings)';
}
