import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../services/projects_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/skeleton_project_card.dart';
import '../../widgets/common/load_more_indicator.dart';
import 'widgets/project_card.dart';

class ProjectsFeedScreen extends StatefulWidget {
  const ProjectsFeedScreen({super.key});

  @override
  State<ProjectsFeedScreen> createState() => ProjectsFeedScreenState();
}

class ProjectsFeedScreenState extends State<ProjectsFeedScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final projects = await ProjectsService.getProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e is AppError ? e : ErrorHandler.handleError(e);
        });
      }
    }
  }

  Future<void> refreshProjects() => _loadProjects();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Projects'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => const SkeletonProjectCard(),
      );
    }

    if (_error != null && _projects.isEmpty) {
      return ErrorStateWidget(error: _error!, onRetry: _loadProjects);
    }

    if (_projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.work_outline,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Projects Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check back later for new projects',
                style: TextStyle(fontSize: 14, color: AppColors.grey500),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProjects,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: _projects.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(
          height: 8,
          thickness: 8,
          color: AppColors.scaffoldBackground,
        ),
        itemBuilder: (context, index) {
          if (index == _projects.length) {
            return const LoadMoreIndicator();
          }
          return ProjectCard(
            key: ValueKey(_projects[index].id),
            project: _projects[index],
          );
        },
      ),
    );
  }
}
