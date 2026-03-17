import '../models/project_model.dart';

/// Stub service for exporting project reports.
///
/// A real implementation would use a PDF generation package such as
/// `pdf` (pub.dev/packages/pdf) and `printing`.
class ExportService {
  /// Returns a summary string for the project (placeholder for PDF export).
  static String generateTextReport(Project project) {
    final buffer = StringBuffer();
    buffer.writeln('PROJECT REPORT');
    buffer.writeln('==============');
    buffer.writeln('Title: ${project.title}');
    buffer.writeln('Owner: ${project.ownerName}');
    buffer.writeln('Stage: ${project.stage.displayName}');
    buffer.writeln('Status: ${project.status}');
    buffer.writeln('Description: ${project.description}');
    buffer.writeln('');
    buffer.writeln('ENGAGEMENT');
    buffer.writeln('Views: ${project.viewsCount ?? 0}');
    buffer.writeln('Likes: ${project.likesCount ?? 0}');
    buffer.writeln('Applications: ${project.applicationsCount ?? 0}');
    buffer.writeln('');
    buffer.writeln('TEAM');
    buffer.writeln(
        'Roles filled: ${project.rolesFilled}/${project.totalRolesNeeded}');
    return buffer.toString();
  }

  /// Stub: export as PDF bytes.
  static Future<List<int>> exportAsPdf(Project project) async {
    // TODO: implement using the `pdf` package
    throw UnimplementedError('PDF export not yet implemented');
  }
}
