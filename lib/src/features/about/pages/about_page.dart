import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<PackageInfo> _info() => PackageInfo.fromPlatform();

  void _launchUri(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Header card dengan logo aset =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(.5) : Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ganti ke logo kamu: assets/images/logo.png
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(Icons.image_not_supported,
                          color: cs.primary, size: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder<PackageInfo>(
                    future: _info(),
                    builder: (context, snap) {
                      final name = 'SIP Kabel App';
                      final version = snap.hasData
                          ? 'v${snap.data!.version} (${snap.data!.buildNumber})'
                          : 'Memuat versi…';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Aplikasi untuk mempermudah pemesanan kabel & aksesoris listrik.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            version,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Informasi Perusahaan',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const _InfoTile(
            icon: Icons.business,
            title: 'PT Sutanto ArifChandra Elektronik',
            subtitle: 'Ajibarang, Banyumas, Jawa Tengah',
          ),
          _InfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'cs@kitani.co.id',
            onTap: () => _launchUri(Uri.parse('mailto:cs@kitani.co.id')),
          ),
          _InfoTile(
            icon: Icons.phone_outlined,
            title: 'Telepon / WhatsApp',
            subtitle: '+62 812-3456-7890',
            onTap: () => _launchUri(Uri.parse('https://wa.me/6281234567890')),
          ),
          _InfoTile(
            icon: Icons.language,
            title: 'Website',
            subtitle: 'https://kitani.co.id',
            onTap: () => _launchUri(Uri.parse('https://kitani.co.id')),
          ),

          const SizedBox(height: 24),
          Text('Legal',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Kebijakan Privasi',
            subtitle: 'Baca kebijakan privasi aplikasi',
            onTap: () => _launchUri(Uri.parse('https://kitani.co.id/privacy')),
          ),
          _InfoTile(
            icon: Icons.description_outlined,
            title: 'Syarat & Ketentuan',
            subtitle: 'Ketentuan penggunaan layanan',
            onTap: () => _launchUri(Uri.parse('https://kitani.co.id/terms')),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${DateTime.now().year} PT Sutanto ArifChandra Elektronik.\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                theme.textTheme.bodySmall?.color?.withOpacity(.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(.7),
          ),
        ),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
