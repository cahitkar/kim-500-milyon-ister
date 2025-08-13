import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = <_GameEntry>[
      _GameEntry(
        title: 'Oyun 1',
        subtitle: 'Bilgi yarışması - yeni sürüm',
        url: 'https://example.com/oyun1',
      ),
      _GameEntry(
        title: 'Oyun 2',
        subtitle: 'Kelime oyunu',
        url: 'https://example.com/oyun2',
      ),
      _GameEntry(
        title: 'Oyun 3',
        subtitle: 'Hız testi',
        url: 'https://example.com/oyun3',
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF2C3E50),
              Color(0xFF1B263B),
              Color(0xFF0D1B2A),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Mağaza',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.videogame_asset, color: Colors.amber, size: 28),
                        title: Text(
                          game.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          game.subtitle,
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                        trailing: const Icon(Icons.open_in_new, color: Colors.white70),
                        onTap: () async {
                          if (game.url != null) {
                            final uri = Uri.parse(game.url!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } else if (game.routeBuilder != null) {
                            Navigator.push(context, MaterialPageRoute(builder: game.routeBuilder!));
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameEntry {
  final String title;
  final String subtitle;
  final String? url;
  final WidgetBuilder? routeBuilder;
  const _GameEntry({
    required this.title,
    required this.subtitle,
    this.url,
    this.routeBuilder,
  });
}


