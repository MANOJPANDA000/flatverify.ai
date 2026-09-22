part of 'main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, int index) {
    final shell = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (shell != null) {
      shell.selectPage(index);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => switch (index) {
          1 => const StandaloneCalculatorPage(),
          2 => const OcrScannerScreen(initialMode: VerifyInputMode.photo),
          _ => const SavedAuditsScreen(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        children: [
          if (!StudioShellScope.contains(context)) ...[
            const _DraftHeader(showProfile: true),
            const SizedBox(height: 24),
          ],
          Container(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF172B65),
                  Color(0xFF1E3A8A),
                  Color(0xFF2563EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    '✧  AI-Assisted Blueprint Dimension Audit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDBEAFE),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'Understand your true '),
                        TextSpan(
                          text: 'carpet area',
                          style: TextStyle(color: Color(0xFF93C5FD)),
                        ),
                        TextSpan(text: ' before booking.'),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: MediaQuery.sizeOf(context).width < 600
                          ? 26
                          : 36,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const Text(
                    'Extract floor plan dimensions with OCR blueprint scanning, calculate area, inspect wall and loading assumptions, and export audit PDF reports.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: Color(0xFFDBEAFE),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _navigate(context, 2),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF172B65),
                      ),
                      icon: const Icon(
                        Icons.document_scanner_outlined,
                        size: 18,
                      ),
                      label: const Text('Scan Blueprint Plan'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _navigate(context, 1),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .12),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                      ),
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('Manual Calculator'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _dashboardStats(),
          const SizedBox(height: 24),
          StudioPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Property Audits',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Review your saved reports',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _navigate(context, 3),
                      child: const Text('View all →'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const _RecentReports(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          StudioColumns(
            main: _education(
              context,
              Icons.verified_user_outlined,
              'Understanding RERA Carpet Area',
              'What is counted in your carpet area?',
              'Review enclosed spaces, internal partitions, balconies and utility areas separately before comparing a property.',
              'Explore area definitions',
              () => ReraDefinitionsSheet.show(context),
            ),
            aside: _education(
              context,
              Icons.layers_outlined,
              'How Loading Affects Your Area',
              'Why does super built-up area matter?',
              'Inspect the wall and shared-area assumptions behind the saleable area. Adjust them to match your property documents.',
              'Open calculator',
              () => _navigate(context, 1),
            ),
          ),
          if (SessionController.instance.isGuest) ...[
            const SizedBox(height: 24),
            const GuestReportNotice(),
          ],
        ],
      ),
    ),
  );

  Widget _dashboardStats() {
    final session = SessionController.instance;
    final boxName = session.isGuest
        ? 'guest_session_reports'
        : 'account_${session.user!.uid}_reports';
    Widget stats(int count) => LayoutBuilder(
      builder: (context, constraints) {
        final items = [
          StudioStat(
            icon: Icons.task_outlined,
            value: '$count',
            label: 'Audits Documented',
          ),
          const StudioStat(
            icon: Icons.verified_user_outlined,
            value: 'Area definitions',
            label: 'Carpet, built-up & exclusive spaces',
            color: AppColors.green,
          ),
          const StudioStat(
            icon: Icons.tune,
            value: 'Your assumptions',
            label: 'Adjustable walls & common loading',
            color: AppColors.orange,
          ),
        ];
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                items[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: items[i]),
            ],
          ],
        );
      },
    );
    if (!Hive.isBoxOpen(boxName)) return stats(0);
    return ValueListenableBuilder<Box>(
      valueListenable: session.reports.listenable(),
      builder: (_, box, _) => stats(box.length),
    );
  }

  Widget _education(
    BuildContext context,
    IconData icon,
    String label,
    String title,
    String description,
    String action,
    VoidCallback onTap,
  ) => StudioPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            height: 1.7,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

class _RecentReports extends StatelessWidget {
  const _RecentReports();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: StudioSettings.instance,
    builder: (context, _) => _buildReports(context),
  );

  Widget _buildReports(BuildContext context) {
    final session = SessionController.instance;
    final boxName = session.isGuest
        ? 'guest_session_reports'
        : 'account_${session.user!.uid}_reports';
    if (!Hive.isBoxOpen(boxName)) return _empty();

    return ValueListenableBuilder<Box>(
      valueListenable: session.reports.listenable(),
      builder: (context, box, _) {
        final entries = box.values.whereType<Map>().toList()
          ..sort(
            (a, b) => (b['timestamp']?.toString() ?? '').compareTo(
              a['timestamp']?.toString() ?? '',
            ),
          );
        if (entries.isEmpty) return _empty();

        return Column(
          children: entries.take(3).map((data) {
            final rooms = data['rooms'];
            final count = rooms is List ? rooms.length : 0;
            final area = _dynamicDouble(
              data['carpetArea'] ?? data['usableArea'],
            );
            final images = data['imageBytes'];
            final bytes =
                images is List && images.isNotEmpty && images.first is Uint8List
                ? images.first as Uint8List
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: bytes == null
                        ? Container(
                            width: 44,
                            height: 44,
                            color: AppColors.lightBlue,
                            child: const Icon(
                              Icons.description_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          )
                        : Image.memory(
                            bytes,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.description_outlined),
                          ),
                  ),
                  title: Text(
                    data['auditName']?.toString() ?? 'Property report',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    '$count rooms • ${StudioSettings.instance.area(area)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFCBD5E1),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedAuditReportScreen(data: data),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _empty() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
    ),
    child: Column(
      children: [
        Icon(
          Icons.folder_open_rounded,
          color: AppColors.primary.withValues(alpha: 0.4),
          size: 32,
        ),
        const SizedBox(height: 12),
        const Text(
          'No saved reports yet. Start with a scan or manual measurement to see them here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
