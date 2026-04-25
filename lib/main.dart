import 'package:flutter/material.dart';

void main() {
  runApp(const MagicBookApp());
}

class MagicBookApp extends StatelessWidget {
  const MagicBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MagicBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6E4CF2)),
        scaffoldBackgroundColor: const Color(0xFFF6F4FB),
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const CreateScreen(),
      const GalleryScreen(),
      const MyWorksScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Create'),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'My Works',
          ),
        ],
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Row(
            children: [
              Icon(Icons.menu, color: Color(0xFF6E4CF2)),
              Expanded(
                child: Text(
                  'Create',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6E4CF2),
                  ),
                ),
              ),
              Icon(Icons.workspace_premium, color: Color(0xFFF6C947)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '1. Upload a picture',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.unsplash.com/photo-1633722715463-d30f4f325e24?w=1200',
              fit: BoxFit.cover,
              height: 260,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6E4CF2),
              minimumSize: const Size.fromHeight(60),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose Photo', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 20),
          const Text(
            '2. Choose complexity',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            segments: const [
              ButtonSegment(value: 'simple', icon: Icon(Icons.sentiment_satisfied), label: Text('Simple')),
              ButtonSegment(value: 'medium', icon: Icon(Icons.sentiment_neutral), label: Text('Medium')),
              ButtonSegment(value: 'detailed', icon: Icon(Icons.star_border), label: Text('Detailed')),
            ],
            selected: const {'simple'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatingScreen()),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF6C947),
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(60),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'Create Coloring',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class CreatingScreen extends StatelessWidget {
  const CreatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Creating...',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6E4CF2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DEFF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.brush, size: 72, color: Color(0xFF6E4CF2)),
              ),
              const SizedBox(height: 24),
              const LinearProgressIndicator(minHeight: 14, borderRadius: BorderRadius.all(Radius.circular(12))),
              const SizedBox(height: 24),
              const Text(
                'Transforming your picture into a number coloring...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'This may take a few seconds.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ColorByNumberScreen()),
                  );
                },
                child: const Text('Preview Result'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorByNumberScreen extends StatelessWidget {
  const ColorByNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFF2CE72),
      Color(0xFFF3A91A),
      Color(0xFFE986A7),
      Color(0xFFDCA228),
      Color(0xFF5BC9A9),
      Color(0xFF5BA34E),
      Color(0xFF8B5A2B),
      Color(0xFF98B8D6),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color by Numbers'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://images.unsplash.com/photo-1633722715463-d30f4f325e24?w=1200',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                colors.length,
                (index) => CircleAvatar(
                  radius: 24,
                  backgroundColor: colors[index],
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GreatJobScreen()),
                      );
                    },
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Hint'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GreatJobScreen extends StatelessWidget {
  const GreatJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Great Job! 🎉'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  'https://images.unsplash.com/photo-1633722715463-d30f4f325e24?w=1200',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6E4CF2),
                minimumSize: const Size.fromHeight(56),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Save to Gallery'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gallery\n(Your generated artworks appear here)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class MyWorksScreen extends StatelessWidget {
  const MyWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'My Works\n(Favorites & saved drawings)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}
