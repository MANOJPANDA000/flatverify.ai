part of 'main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, VerifyInputMode mode) {
    final navigation = context
        .findAncestorStateOfType<_MainNavigationScreenState>();
    if (navigation != null) {
      navigation.openVerification(mode);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OcrScannerScreen(initialMode: mode)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        const _DraftHeader(showProfile: true),
        const SizedBox(height: 12),
        const Text(
          'Know your real area.',
          style: TextStyle(
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Clear measurements. Confident decisions.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/branding/floor_plan_hero.png',
          height: 130,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 12),
        _HomeAction(
          icon: Icons.camera_alt_outlined,
          title: 'Scan Floor Plan',
          subtitle: 'Upload a plan. Review each room.',
          primary: true,
          onTap: () => _open(context, VerifyInputMode.photo),
        ),
        const SizedBox(height: 12),
        _HomeAction(
          icon: Icons.straighten,
          title: 'Enter Measurements',
          subtitle: 'Add rooms and calculate area.',
          onTap: () => _open(context, VerifyInputMode.manual),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent reports',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedAuditsScreen()),
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        const _RecentReports(),
        if (SessionController.instance.isGuest) ...[
          const SizedBox(height: 12),
          const GuestReportNotice(),
        ],
      ],
    ),
  );
}

class _HomeAction extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool primary;
  final VoidCallback onTap;
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: primary ? AppColors.primary : Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: primary ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: primary ? Colors.white : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      height: 1.35,
                      fontSize: 11.5,
                      color: primary ? Colors.white : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: primary ? Colors.white : AppColors.primary,
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecentReports extends StatelessWidget {
  const _RecentReports();
  @override
  Widget build(BuildContext context) {
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
            final date = DateTime.tryParse(data['timestamp']?.toString() ?? '');
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
            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: bytes == null
                      ? Image.asset(
                          'assets/branding/floor_plan_hero.png',
                          width: 48,
                          height: 54,
                          fit: BoxFit.cover,
                        )
                      : Image.memory(
                          bytes,
                          width: 48,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.description_outlined),
                        ),
                ),
                title: Text(
                  data['auditName']?.toString() ?? 'Property report',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '$count rooms · ${AreaDisplayUnit.imperial.formatArea(area)}\n'
                  '${date == null ? '' : '${date.day}/${date.month}/${date.year} · '}Open report',
                  style: const TextStyle(fontSize: 11, height: 1.5),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SavedAuditReportScreen(data: data),
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
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: const Row(
      children: [
        Icon(Icons.folder_open, color: AppColors.primary),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            'Your saved reports will appear here. Start with a scan or enter your measurements.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
