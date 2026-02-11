import 'package:flutter/material.dart';
import '../widgets/site_work_detail_flutter.dart';

class SiteManagementFlutter extends StatelessWidget {
  const SiteManagementFlutter({
    super.key,
    required this.sites,
    required this.onVerify,
    required this.onApprove,
    required this.onReject,
  });

  final List<Map<String, dynamic>> sites;
  final ValueChanged<String> onVerify;
  final ValueChanged<String> onApprove;
  final void Function(String id, String reason) onReject;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: sites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final site = sites[index];
        return SiteWorkDetailFlutter(
          site: site,
          onVerify: () => onVerify(site['id'] as String),
          onApprove: () => onApprove(site['id'] as String),
          onReject: (reason) => onReject(site['id'] as String, reason),
        );
      },
    );
  }
}
