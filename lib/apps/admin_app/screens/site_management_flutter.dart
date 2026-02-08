import 'package:flutter/material.dart';
import '../widgets/site_work_detail_flutter.dart';

class SiteManagementFlutter extends StatelessWidget {
  const SiteManagementFlutter({super.key, required this.sites});

  final List<Map<String, String>> sites;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: sites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final site = sites[index];
        return SiteWorkDetailFlutter(site: site);
      },
    );
  }
}
