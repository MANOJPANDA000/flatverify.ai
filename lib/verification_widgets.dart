part of 'main.dart';

class _DraftHeader extends StatelessWidget {
  final bool showProfile;
  const _DraftHeader({this.showProfile = false});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const FLogo(size: 32),
      const SizedBox(width: 9),
      const Expanded(
        child: Text(
          'Flatverify.ai',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
      ),
      if (showProfile)
        IconButton(
          tooltip: 'Your account',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Account')),
                body: const AccountScreen(),
              ),
            ),
          ),
          icon: ListenableBuilder(
            listenable: SessionController.instance,
            builder: (context, _) =>
                ProfileAvatar(user: SessionController.instance.user, size: 36),
          ),
        ),
    ],
  );
}

class _VerificationProgress extends StatelessWidget {
  final int current;
  final bool manual;
  const _VerificationProgress({required this.current, required this.manual});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < current
                      ? const Color(0xFF16805D)
                      : index == current
                      ? AppColors.primary
                      : AppColors.lightBlue,
                ),
                child: Center(
                  child: index < current
                      ? const Icon(Icons.check, size: 19, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: index == current
                                ? Colors.white
                                : AppColors.secondaryText,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [manual ? 'Rooms' : 'Plan', 'Review', 'Results'][index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: index == current
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: index == current
                      ? AppColors.primary
                      : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AreaSummaryBar extends StatelessWidget {
  final String? area;
  final bool photoMode;
  final VoidCallback onResults;
  const _AreaSummaryBar({
    required this.area,
    required this.photoMode,
    required this.onResults,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 8,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photoMode ? 'Confirmed area' : 'Calculated area',
                    style: const TextStyle(
                      color: Color(0xFF16805D),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.centerLeft,
                    child: area == null
                        ? const SizedBox(height: 8)
                        : Text(
                            area!,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: AppColors.dark,
                            ),
                          ),
                  ),
                  Text(
                    photoMode
                        ? 'Only confirmed or completed rooms'
                        : 'Completed rooms only',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onResults,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('View results'),
            ),
          ],
        ),
      ),
    ),
  );
}
