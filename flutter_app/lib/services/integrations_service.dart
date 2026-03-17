/// A lightweight model representing an external integration connection.
class Integration {
  final String service; // 'github', 'figma', 'slack', 'trello'
  final String? connectionUrl;
  final bool isConnected;
  final String? displayInfo;
  final DateTime? lastSynced;

  const Integration({
    required this.service,
    this.connectionUrl,
    required this.isConnected,
    this.displayInfo,
    this.lastSynced,
  });
}

/// Stub service for external integrations.
///
/// Real implementations would call each service's OAuth flow or API.
class IntegrationsService {
  static Future<List<Integration>> getIntegrations(String projectId) async {
    // Placeholder: in production this would query stored OAuth tokens.
    return [
      const Integration(service: 'github', isConnected: false),
      const Integration(service: 'figma', isConnected: false),
      const Integration(service: 'slack', isConnected: false),
      const Integration(service: 'trello', isConnected: false),
    ];
  }

  static Future<void> connectGitHub(
      String projectId, String repoUrl) async {
    // TODO: implement OAuth flow
    throw UnimplementedError('GitHub integration not yet implemented');
  }

  static Future<void> connectFigma(
      String projectId, String fileUrl) async {
    throw UnimplementedError('Figma integration not yet implemented');
  }

  static Future<void> connectSlack(
      String projectId, String channelUrl) async {
    throw UnimplementedError('Slack integration not yet implemented');
  }

  static Future<void> connectTrello(
      String projectId, String boardUrl) async {
    throw UnimplementedError('Trello integration not yet implemented');
  }
}
