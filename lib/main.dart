import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const PagailleApp());

const ink = Color(0xff19162e);
const gold = Color(0xffffd66c);
const cardColors = <Color>[
  Color(0xff9250d5),
  Color(0xff2d91ee),
  Color(0xff46b954),
  Color(0xffffce3c),
  Color(0xffff9239),
  Color(0xfff25567),
];
const decoColors = <Color>[
  Color(0xff155c53),
  Color(0xff1b4670),
  Color(0xff643668),
  Color(0xff863c45),
  Color(0xff234765),
  Color(0xffae7824),
];
const comicColors = <Color>[
  Color(0xff9c4ed6),
  Color(0xff3d94e8),
  Color(0xff5ab83e),
  Color(0xffffc52b),
  Color(0xfff47b25),
  Color(0xffdb3c42),
];
const cardMascots = <String>['La tortue', 'Le lapin', 'Le renard', 'La poule', 'Le raton', 'Le chat'];
const themeKeys = <String>['colore', 'deco', 'bd'];
String cardArtwork(int theme, int value) => 'imprimable/illustrations/${themeKeys[theme]}_$value.jpg';

class VisualSpec {
  const VisualSpec({
    required this.name,
    required this.preview,
    required this.badge,
    required this.surface,
    required this.panel,
    required this.panel2,
    required this.accent,
    required this.accent2,
    required this.textDark,
    required this.cardPalette,
    required this.flair,
  });

  final String name;
  final String preview;
  final String badge;
  final Color surface;
  final Color panel;
  final Color panel2;
  final Color accent;
  final Color accent2;
  final Color textDark;
  final List<Color> cardPalette;
  final String flair;
}

const specs = <VisualSpec>[
  VisualSpec(
    name: 'Coloré',
    preview: 'assets/themes/colore.jpg',
    badge: 'Fun, lumineux et accrocheur',
    surface: Color(0xff201736),
    panel: Color(0xff33244e),
    panel2: Color(0xff40295f),
    accent: Color(0xffffd66c),
    accent2: Color(0xff63e1dc),
    textDark: Color(0xff19162e),
    cardPalette: cardColors,
    flair: 'Confettis et bonne humeur',
  ),
  VisualSpec(
    name: 'Art déco',
    preview: 'assets/themes/deco.jpg',
    badge: 'Chic, malin et raffiné',
    surface: Color(0xff062628),
    panel: Color(0xff0d3538),
    panel2: Color(0xff103e42),
    accent: Color(0xffffd38a),
    accent2: Color(0xffd54f7d),
    textDark: Color(0xff082022),
    cardPalette: decoColors,
    flair: 'Élégance et géométrie',
  ),
  VisualSpec(
    name: 'BD explosive',
    preview: 'assets/themes/bd.jpg',
    badge: 'Punchy, drôle et énergique',
    surface: Color(0xff2c1331),
    panel: Color(0xff481f54),
    panel2: Color(0xff5a2669),
    accent: Color(0xffffc436),
    accent2: Color(0xfffb5b49),
    textDark: Color(0xff23142d),
    cardPalette: comicColors,
    flair: 'Bulles, éclats et impact',
  ),
];

class PagailleApp extends StatelessWidget {
  const PagailleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pagaille ! Le compte est piégé',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Random random = Random();

  int playerCount = 4;
  int target = 10;
  int current = 0;
  int selected = -1;
  int turn = 1;
  int visualTheme = 0;
  bool diceMode = false;
  bool started = false;
  bool finished = false;
  int discarded = 0;
  String message = 'Prépare tes meilleurs calculs.';

  late List<List<int>> hands;
  late List<int> scores;
  late List<String> names;
  late List<List<int>> piles;
  final List<int> drawPile = <int>[];

  VisualSpec get spec => specs[visualTheme];

  void newGame() {
    setState(() {
      target = diceMode ? 9 + random.nextInt(3) : 10;
      drawPile
        ..clear()
        ..addAll(List<int>.generate(48, (i) => (i % 6) + 1))
        ..shuffle(random);
      hands = List<List<int>>.generate(playerCount, (_) => <int>[]);
      for (var i = 0; i < 4; i++) {
        for (var j = 0; j < playerCount; j++) {
          if (drawPile.isNotEmpty) {
            hands[j].add(drawPile.removeLast());
          }
        }
      }
      scores = List<int>.filled(playerCount, 0);
      names = List<String>.generate(playerCount, (i) => 'Joueur ${i + 1}');
      piles = List<List<int>>.generate(3, (_) => <int>[]);
      current = 0;
      selected = -1;
      turn = 1;
      discarded = 0;
      started = true;
      finished = false;
      message = 'Choisis une carte puis une pile. Atteins $target exactement !';
    });
  }

  bool canPlace(int value, int pileIndex) {
    return sumPile(pileIndex) + value <= target;
  }

  bool get hasMove {
    return hands[current].any(
      (v) => List<int>.generate(3, (i) => i).any((i) => canPlace(v, i)),
    );
  }

  int sumPile(int pileIndex) {
    return piles[pileIndex].fold<int>(0, (a, b) => a + b);
  }

  void play(int pileIndex) {
    if (finished || selected < 0 || selected >= hands[current].length) return;
    final value = hands[current][selected];
    if (!canPlace(value, pileIndex)) {
      setState(() {
        message = 'Impossible : cette pile dépasserait $target.';
      });
      return;
    }

    setState(() {
      hands[current].removeAt(selected);
      piles[pileIndex].add(value);
      if (sumPile(pileIndex) == target) {
        final points = piles[pileIndex].length + 2;
        scores[current] += points;
        piles[pileIndex].clear();
        message = 'BINGO ! ${names[current]} marque $points points et vide la pile ${pileIndex + 1}.';
      } else {
        message = '${names[current]} pose $value sur la pile ${pileIndex + 1}.';
      }
      advance();
    });
  }

  void discardBlocked() {
    if (selected < 0 || hasMove || finished) return;
    setState(() {
      final value = hands[current].removeAt(selected);
      discarded++;
      message = 'Aucun coup possible : ${names[current]} défausse $value.';
      advance();
    });
  }

  void advance() {
    if (drawPile.isNotEmpty) {
      hands[current].add(drawPile.removeLast());
    }
    selected = -1;

    if (hands.every((h) => h.isEmpty)) {
      finished = true;
      return;
    }

    do {
      current = (current + 1) % playerCount;
      turn++;
    } while (hands[current].isEmpty);
  }

  String winners() {
    final maxScore = scores.reduce(max);
    final champs = List<int>.generate(playerCount, (i) => i)
        .where((i) => scores[i] == maxScore)
        .map((i) => names[i])
        .join(' et ');
    return '$champs — $maxScore points';
  }

  Widget pill(String text, {Color? color}) {
    final c = color ?? spec.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: 0.36)),
      ),
      child: Text(
        text,
        style: TextStyle(color: c, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget themeSelector({bool compact = false}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List<Widget>.generate(3, (i) {
        final s = specs[i];
        final selectedTheme = visualTheme == i;
        return InkWell(
          onTap: () => setState(() => visualTheme = i),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: compact ? 148 : 176,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selectedTheme ? s.accent.withValues(alpha: 0.18) : s.panel.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selectedTheme ? s.accent : Colors.white24,
                width: selectedTheme ? 2.6 : 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: compact ? 58 : 72,
                    width: double.infinity,
                    child: Image.asset(s.preview, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selectedTheme ? s.accent : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.badge,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget themeBanner({double height = 160}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: Image.asset(spec.preview, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    spec.surface.withValues(alpha: 0.84),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: pill(spec.name.toUpperCase(), color: spec.accent),
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAGAILLE !',
                  style: TextStyle(
                    fontSize: height > 80 ? 26 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
                Text(
                  spec.flair,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(String label, String value, {bool active = false}) {
    final bg = active ? spec.accent : spec.panel2;
    final fg = active ? spec.textDark : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 118,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? spec.accent : Colors.white12),
        boxShadow: [
          BoxShadow(
            color: active ? spec.accent.withValues(alpha: 0.35) : Colors.black26,
            blurRadius: active ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: fg.withValues(alpha: 0.88), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget pileTile(int index) {
    final total = sumPile(index);
    final selectable = !finished && selected >= 0 && selected < hands[current].length && canPlace(hands[current][selected], index);
    final remaining = target - total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: selectable ? () => play(index) : null,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selectable
                  ? [spec.panel2, spec.panel]
                  : [spec.panel, spec.surface],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selectable ? spec.accent2 : Colors.white12,
              width: selectable ? 2.4 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: selectable ? spec.accent2.withValues(alpha: 0.25) : Colors.black26,
                blurRadius: selectable ? 18 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: spec.surface,
                  border: Border.all(color: selectable ? spec.accent : Colors.white12, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: total == target ? spec.accent : Colors.white,
                      ),
                    ),
                    Text(
                      '/ $target',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PILE ${index + 1}',
                      style: TextStyle(
                        color: spec.accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remaining == 0 ? 'Objectif atteint' : '$remaining restant',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      piles[index].isEmpty ? 'Pile vide' : piles[index].join(' + '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectable ? Icons.ads_click_rounded : Icons.lock_outline,
                    color: selectable ? spec.accent2 : Colors.white24,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectable ? 'Poser' : 'Bloqué',
                    style: TextStyle(
                      color: selectable ? spec.accent2 : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget numberCard(int value, {bool active = false, VoidCallback? onTap}) {
    final c = spec.cardPalette[value - 1];
    final borderColor = visualTheme == 1 ? spec.accent : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        width: 86,
        height: 124,
        margin: EdgeInsets.fromLTRB(5, active ? 0 : 8, 5, active ? 12 : 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(c, Colors.white, 0.22)!,
              c,
              Color.lerp(c, Colors.black, 0.28)!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? spec.accent : borderColor,
            width: active ? 4.0 : 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: active ? spec.accent.withValues(alpha: 0.45) : Colors.black45,
              blurRadius: active ? 18 : 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: CardDecorationPainter(visualTheme))),
              Positioned(
                top: 5,
                left: 8,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
              Positioned(
                top: 7,
                right: 8,
                child: Text(
                  visualTheme == 1 ? '◆' : visualTheme == 2 ? 'BOUM' : '✦',
                  style: TextStyle(
                    fontSize: visualTheme == 2 ? 10 : 13,
                    color: visualTheme == 1 ? spec.accent : Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        cardArtwork(visualTheme, value),
                        width: 65,
                        height: 54,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: visualTheme == 1 ? spec.accent : Colors.white,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visualTheme == 1 ? 'Prestige' : visualTheme == 2 ? 'Impact' : 'Pagaille',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 5,
                right: 8,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 16,
                    color: visualTheme == 1 ? spec.accent : Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget galleryTile(int value) {
    final c = spec.cardPalette[value - 1];
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: spec.surface,
          title: Text('Carte $value — ${cardMascots[value - 1]}',
              style: TextStyle(color: spec.accent)),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(cardArtwork(visualTheme, value),
                width: 290, fit: BoxFit.contain),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'))],
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(aspectRatio: 1,
                  child: Image.asset(cardArtwork(visualTheme, value),
                      fit: BoxFit.cover)),
            ),
            const SizedBox(height: 7),
            Text('CARTE $value', style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(cardMascots[value - 1],
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  void showGallery() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (ctx) => Scaffold(
        backgroundColor: spec.surface,
        appBar: AppBar(
          backgroundColor: spec.panel,
          title: Text('Galerie — ${spec.name}'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: 6,
                itemBuilder: (_, i) => galleryTile(i + 1),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget welcome() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          themeBanner(height: 186),
          const SizedBox(height: 12),
          Text(
            'PAGAILLE !',
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: spec.accent),
          ),
          Text(
            'LE COMPTE EST PIÉGÉ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2, color: spec.accent),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: spec.panel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                const Text(
                  'Le jeu où un bon calcul peut offrir la victoire à ton pire adversaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    pill('$playerCount joueurs'),
                    pill('48 cartes'),
                    pill('3 piles'),
                    pill('Objectif ${diceMode ? '9/10/11' : '10'}', color: spec.accent2),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('CHOISIR UN STYLE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          themeSelector(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: spec.panel,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Nombre de joueurs : $playerCount', style: const TextStyle(fontWeight: FontWeight.w800))),
                    Text('${2 + (playerCount - 2)} / 6', style: TextStyle(color: spec.accent)),
                  ],
                ),
                Slider(
                  value: playerCount.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: '$playerCount',
                  activeColor: spec.accent,
                  onChanged: (v) => setState(() => playerCount = v.round()),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: diceMode,
                  activeColor: spec.accent,
                  onChanged: (v) => setState(() => diceMode = v),
                  title: const Text('🎲 Dé facultatif'),
                  subtitle: const Text('L’objectif est tiré une seule fois : 9, 10 ou 11'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: spec.accent,
              foregroundColor: spec.textDark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: newGame,
            icon: const Icon(Icons.play_arrow),
            label: const Text('LANCER LA PARTIE'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: showGallery,
            icon: const Icon(Icons.collections_outlined),
            label: const Text('GALERIE DES CARTES'),
          ),
          TextButton.icon(
            onPressed: showRules,
            icon: const Icon(Icons.menu_book),
            label: const Text('COMMENT JOUER ?'),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              '2 à 6 joueurs • 48 cartes • 3 piles • aucun défi à réaliser\nÀ tour de rôle sur le même appareil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget game() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAGAILLE !', style: TextStyle(color: spec.accent, fontWeight: FontWeight.w900, fontSize: 28)),
                  Text(spec.badge, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            pill('Objectif $target', color: spec.accent),
            IconButton(onPressed: showGallery, tooltip: 'Galerie des cartes', icon: const Icon(Icons.collections_outlined)),
            IconButton(onPressed: showRules, icon: const Icon(Icons.help_outline)),
            PopupMenuButton<int>(
              tooltip: 'Changer de thème',
              icon: const Icon(Icons.palette_outlined),
              onSelected: (v) => setState(() => visualTheme = v),
              itemBuilder: (_) => List<PopupMenuEntry<int>>.generate(
                3,
                (i) => PopupMenuItem<int>(value: i, child: Text(specs[i].name)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        themeBanner(height: 72),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List<Widget>.generate(
              playerCount,
              (i) => statCard(names[i], '${scores[i]} pts', active: i == current && !finished),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: spec.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Text(
                finished ? '🏆 FIN DE PARTIE' : 'Au tour de ${names[current]}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: finished ? spec.accent : Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                'Pioche : ${drawPile.length} cartes  •  Défausse : $discarded  •  Tour : $turn',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: spec.accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              ...List<Widget>.generate(3, pileTile),
              if (finished)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: spec.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: spec.accent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text('🏆 ${winners()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text(
                        'Les cartes restées sur les piles ne rapportent aucun point.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (!finished) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TA MAIN — choisis une carte',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: spec.accent),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(
                hands[current].length,
                (i) => numberCard(
                  hands[current][i],
                  active: selected == i,
                  onTap: () => setState(() => selected = i),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!hasMove)
            TextButton.icon(
              onPressed: selected < 0 ? null : discardBlocked,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Aucun coup possible : défausser la carte choisie'),
            ),
          if (hasMove)
            Text(
              'Puis touche une pile compatible ci-dessus.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12),
            ),
        ],
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => setState(() => started = false),
              child: Text(finished ? 'Rejouer' : 'Nouvelle partie'),
            ),
            TextButton(onPressed: showRules, child: const Text('Règles')),
            TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: spec.surface,
                  showDragHandle: true,
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Choisir un thème', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: spec.accent)),
                            const SizedBox(height: 12),
                            themeSelector(compact: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Thèmes'),
            ),
          ],
        ),
      ],
    );
  }

  void showRules() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: spec.surface,
          title: Text('🧠 Le compte est piégé', style: TextStyle(color: spec.accent)),
          content: const SingleChildScrollView(
            child: Text(
              'BUT : marquer le plus de points en fermant des piles.\n\n'
              'MATÉRIEL : 48 cartes numérotées (8 de chaque valeur, de 1 à 6), trois piles communes.\n\n'
              'MISE EN PLACE : mélangez et distribuez 4 cartes par joueur. Objectif 10 ; avec un dé, lancez-le une seule fois : 1–2 = 9, 3–4 = 10, 5–6 = 11.\n\n'
              'TOUR : jouez une carte sur l’une des 3 piles, sans dépasser l’objectif. Si la somme atteint exactement l’objectif, gagnez autant de points que de cartes dans cette pile + 2 bonus, puis videz la pile. Piochez une carte si possible.\n\n'
              'SI BLOQUÉ : si aucune carte de votre main ne peut être jouée sur aucune pile, défaussez une carte de votre choix, puis piochez si possible.\n\n'
              'FIN : quand la pioche et toutes les mains sont vides. Le plus grand score gagne ; les cartes restantes sur les piles ne valent rien. Égalité possible.\n\n'
              'ASTUCE : ne donnez pas trop facilement le coup gagnant au joueur suivant !',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris !')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spec.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: !started ? welcome() : game(),
            ),
          ),
        ),
      ),
    );
  }
}

class CardDecorationPainter extends CustomPainter {
  const CardDecorationPainter(this.mode);

  final int mode;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke;
    if (mode == 1) {
      p.color = const Color(0xffffd995).withValues(alpha: 0.75);
      p.strokeWidth = 1;
      final path = Path()
        ..moveTo(6, 22)
        ..lineTo(6, size.height - 11)
        ..lineTo(14, size.height - 5)
        ..lineTo(size.width - 14, size.height - 5)
        ..lineTo(size.width - 6, size.height - 11)
        ..lineTo(size.width - 6, 8)
        ..lineTo(size.width - 14, 4)
        ..lineTo(16, 4);
      canvas.drawPath(path, p);
      for (var i = 0; i < 7; i++) {
        canvas.drawLine(Offset(size.width / 2, 4), Offset(i * size.width / 6, 29), p);
      }
    } else {
      p.color = Colors.white.withValues(alpha: mode == 2 ? 0.30 : 0.18);
      p.strokeWidth = mode == 2 ? 2 : 1;
      for (var i = 0; i < 9; i++) {
        final x = (i * 19.0) % (size.width + 20);
        canvas.drawLine(Offset(x, 0), Offset(x + (mode == 2 ? 24 : 7), size.height), p);
      }
      if (mode == 2) {
        final b = Paint()..color = const Color(0xffffdf58).withValues(alpha: 0.35);
        canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.73), 18, b);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CardDecorationPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}
