import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const PagailleApp());

const ink = Color(0xff19162e);
const gold = Color(0xffffd66c);
const coral = Color(0xffff7985);
const cyan = Color(0xff63e1dc);
const cardColors = <Color>[Color(0xff9250d5), Color(0xff2d91ee), Color(0xff46b954), Color(0xffffce3c), Color(0xffff9239), Color(0xfff25567)];
const cardMascots = <String>['🐢', '🐰', '🦊', '🐔', '🦝', '🐱'];
const themeNames = <String>['Coloré', 'Art déco', 'BD explosive'];
const themeImages = <String>['assets/themes/colore.jpg', 'assets/themes/deco.jpg', 'assets/themes/bd.jpg'];
const decoColors = <Color>[Color(0xff155c53), Color(0xff1b4670), Color(0xff643668), Color(0xff863c45), Color(0xff234765), Color(0xffae7824)];
const comicColors = <Color>[Color(0xff9c4ed6), Color(0xff3d94e8), Color(0xff5ab83e), Color(0xffffc52b), Color(0xfff47b25), Color(0xffdb3c42)];

class PagailleApp extends StatelessWidget {
  const PagailleApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Pagaille ! Le compte est piégé',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)),
    home: const GamePage(),
  );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Random random = Random();
  int playerCount = 4, target = 10, current = 0, selected = -1, turn = 1;
  bool diceMode = false, started = false, finished = false;
  int visualTheme = 0;
  Color get accent => visualTheme == 1 ? const Color(0xffe8bd69) : visualTheme == 2 ? const Color(0xffffc436) : gold;
  Color get surface => visualTheme == 1 ? const Color(0xff092a2d) : visualTheme == 2 ? const Color(0xff3d194a) : ink;
  late List<List<int>> hands;
  late List<int> scores;
  late List<String> names;
  late List<List<int>> piles;
  final List<int> drawPile = [];
  int discarded = 0;
  String message = 'Prépare tes meilleurs calculs.';

  void newGame() {
    setState(() {
      target = diceMode ? 9 + random.nextInt(3) : 10;
      // Dé papier : 1–2 -> 9, 3–4 -> 10, 5–6 -> 11.
      // Un tirage parmi trois valeurs donne la même distribution.
      drawPile..clear()..addAll(List.generate(48, (i) => (i % 6) + 1))..shuffle(random);
      hands = List.generate(playerCount, (_) => <int>[]);
      for (var i = 0; i < 4; i++) {
        for (var j = 0; j < playerCount; j++) {
          if (drawPile.isNotEmpty) hands[j].add(drawPile.removeLast());
        }
      }
      scores = List.filled(playerCount, 0);
      names = List.generate(playerCount, (i) => 'Joueur ${i + 1}');
      piles = List.generate(3, (_) => <int>[]);
      discarded = 0;
      current = 0; selected = -1; turn = 1; started = true; finished = false;
      message = 'Choisis une carte, puis une pile. Atteins $target exactement !';
    });
  }

  bool canPlace(int value, int pileIndex) => piles[pileIndex].fold<int>(0, (a, b) => a + b) + value <= target;
  bool get hasMove => hands[current].any((v) => List.generate(3, (i) => i).any((i) => canPlace(v, i)));
  int sumPile(int pileIndex) => piles[pileIndex].fold<int>(0, (a, b) => a + b);

  void play(int pileIndex) {
    if (finished || selected < 0 || selected >= hands[current].length) return;
    final value = hands[current][selected];
    if (!canPlace(value, pileIndex)) {
      setState(() => message = 'Impossible : cette pile dépasserait $target.');
      return;
    }
    setState(() {
      hands[current].removeAt(selected);
      piles[pileIndex].add(value);
      if (sumPile(pileIndex) == target) {
        final points = piles[pileIndex].length + 2;
        scores[current] += points;
        piles[pileIndex].clear();
        message = 'BINGO ! ${names[current]} marque $points points et libère la pile ${pileIndex + 1}.';
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
    if (drawPile.isNotEmpty) hands[current].add(drawPile.removeLast());
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

  Widget pill(String text, {Color color = gold}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.36))),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
  );

  Widget themeSelector() => Wrap(
    alignment: WrapAlignment.center, spacing: 8, runSpacing: 6,
    children: List.generate(3, (i) => ChoiceChip(
      label: Text(themeNames[i]), selected: visualTheme == i,
      selectedColor: accent.withValues(alpha: .34),
      onSelected: (_) => setState(() => visualTheme = i),
    )),
  );

  Widget themeBanner({double height = 158}) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Stack(children: [
      SizedBox(height: height, width: double.infinity,
        child: Image.asset(themeImages[visualTheme], fit: BoxFit.cover,
          alignment: Alignment.center)),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, surface.withValues(alpha: .82)])))),
      Positioned(left: 14, bottom: 10, child: Text(themeNames[visualTheme].toUpperCase(),
        style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w900,
          letterSpacing: 2, shadows: const [Shadow(blurRadius: 8, color: Colors.black)]))),
    ]),
  );

  Widget numberCard(int value, {bool active = false, VoidCallback? onTap}) {
    final c = (visualTheme == 1 ? decoColors : visualTheme == 2 ? comicColors : cardColors)[value - 1];
    final borderColor = visualTheme == 1 ? const Color(0xffffd38a) : Colors.white;
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      width: 77, height: 109,
      margin: EdgeInsets.fromLTRB(4, active ? 0 : 7, 4, active ? 10 : 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, .20)!, c, Color.lerp(c, Colors.black, .24)!]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? accent : borderColor, width: active ? 4 : 2.4),
        boxShadow: [BoxShadow(color: active ? accent.withValues(alpha: .55) : Colors.black45,
          blurRadius: active ? 17 : 7, offset: const Offset(0, 4))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(11), child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: CardDecorationPainter(visualTheme))),
        Positioned(top: 3, left: 7, child: Text('$value', style: TextStyle(
          fontSize: 23, color: Colors.white, fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 4)]))),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 13), Text(cardMascots[value - 1], style: const TextStyle(fontSize: 33)),
          Text('$value', style: TextStyle(fontSize: 26, height: 1, fontWeight: FontWeight.w900,
            color: visualTheme == 1 ? const Color(0xffffe5a0) : Colors.white,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 4)])),
        ])),
        Positioned(bottom: 3, right: 7, child: Text(visualTheme == 1 ? '◆' : '✦',
          style: TextStyle(color: visualTheme == 1 ? const Color(0xffffe5a0) : Colors.white, fontSize: 13))),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: surface, body: SafeArea(child: Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 850), child: Padding(
      padding: const EdgeInsets.all(14), child: !started ? welcome() : game(),
    ),
  ))));

  Widget welcome() => SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const SizedBox(height: 12), themeBanner(height: 180),
    const SizedBox(height: 10), Text('PAGAILLE !', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: accent)),
    Text('LE COMPTE EST PIÉGÉ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2, color: accent)),
    const SizedBox(height: 16), const Text('Le jeu où un bon calcul peut offrir la victoire à ton pire adversaire.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
    const SizedBox(height: 16), const Text('CHOISIR UN STYLE', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 7), themeSelector(), const SizedBox(height: 18), pill('$playerCount joueurs'),
    Slider(value: playerCount.toDouble(), min: 2, max: 6, divisions: 4, label: '$playerCount', onChanged: (v) => setState(() => playerCount = v.round())),
    SwitchListTile(value: diceMode, onChanged: (v) => setState(() => diceMode = v), title: const Text('🎲 Dé facultatif'),
      subtitle: const Text('Détermine l’objectif : 9, 10 ou 11 (un seul lancer au début)')),
    const SizedBox(height: 13), FilledButton.icon(onPressed: newGame, icon: const Icon(Icons.play_arrow), label: const Text('LANCER LA PARTIE')),
    const SizedBox(height: 18), TextButton.icon(onPressed: () => showRules(), icon: const Icon(Icons.menu_book), label: const Text('COMMENT JOUER ?')),
    const Padding(padding: EdgeInsets.all(10), child: Text('2 à 6 joueurs • 48 cartes • 3 piles • aucun défi à réaliser\nÀ tour de rôle sur le même appareil.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
  ]));

  Widget game() => Column(children: [
    Row(children: [Expanded(child: Text('PAGAILLE !', style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 27))),
      pill('Objectif $target', color: accent), IconButton(onPressed: showRules, icon: const Icon(Icons.help_outline)),
      PopupMenuButton<int>(tooltip: 'Changer de thème', icon: const Icon(Icons.palette_outlined),
        onSelected: (v) => setState(() => visualTheme = v),
        itemBuilder: (_) => List.generate(3, (i) => PopupMenuItem(value: i, child: Text(themeNames[i]))))]),
    const SizedBox(height: 5), SizedBox(height: 56, child: themeBanner(height: 56)), const SizedBox(height: 8), SizedBox(height: 69, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(playerCount, (i) => Container(
      width: 112, margin: const EdgeInsets.only(right: 7), padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: i == current && !finished ? accent : const Color(0xff332e50), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [Text(names[i], style: TextStyle(color: i == current && !finished ? ink : Colors.white, fontSize: 12)),
        Text('${scores[i]} pts', style: TextStyle(color: i == current && !finished ? ink : Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
    )))),
    const SizedBox(height: 10), Text(finished ? '🏆 FIN DE PARTIE' : 'Au tour de ${names[current]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), Text('Pioche : ${drawPile.length} cartes   •   Défausse : $discarded   •   Tour : $turn', style: const TextStyle(fontSize: 12, color: Colors.white70)),
    const SizedBox(height: 13), Expanded(child: ListView(children: [
      ...List.generate(3, (i) {
        final total = sumPile(i);
        final valid = !finished && selected >= 0 && canPlace(hands[current][selected], i);
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(
          onTap: valid ? () => play(i) : null,
          borderRadius: BorderRadius.circular(17),
          child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(
            color: valid ? const Color(0xff314d59) : const Color(0xff332e50), borderRadius: BorderRadius.circular(17),
            border: Border.all(color: valid ? cyan : const Color(0xff4c466b), width: valid ? 2 : 1)),
            child: Row(children: [
              Container(width: 59, height: 60, alignment: Alignment.center, decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(12)),
                child: Text('$total', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: total == target ? gold : Colors.white))),
              const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PILE ${i + 1}   ${target - total} restant', style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(piles[i].isEmpty ? 'Pile vide' : piles[i].join(' + '), style: const TextStyle(color: Colors.white70)),
              ])),
              Icon(valid ? Icons.add_circle : Icons.lock_outline, color: valid ? cyan : Colors.white24),
            ]),
          ),
        ));
      }),
      const SizedBox(height: 2), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: gold, fontWeight: FontWeight.w700)),
      if (finished) ...[
        const SizedBox(height: 14), Text('🏆 ${winners()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const Text('Les cartes restées sur les piles ne rapportent aucun point.', textAlign: TextAlign.center),
      ],
    ])),
    const SizedBox(height: 7), if (!finished) ...[
      const Text('TA MAIN — choisis une carte', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      SizedBox(height: 119, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(hands[current].length, (i) => numberCard(hands[current][i], active: selected == i,
          onTap: () => setState(() => selected = i)))))),
      if (!hasMove) TextButton.icon(onPressed: selected < 0 ? null : discardBlocked, icon: const Icon(Icons.delete_outline), label: const Text('Aucun coup possible : défausser la carte choisie')),
      if (hasMove) const Text('Puis touche une pile compatible ci-dessus.', style: TextStyle(color: Colors.white70, fontSize: 12)),
    ],
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [TextButton(onPressed: () => setState(() => started = false), child: Text(finished ? 'Rejouer' : 'Nouvelle partie')),
      TextButton(onPressed: showRules, child: const Text('Règles'))]),
  ]);

  String winners() {
    final maxScore = scores.reduce(max);
    return List.generate(playerCount, (i) => i).where((i) => scores[i] == maxScore).map((i) => names[i]).join(' et ') + ' — $maxScore points';
  }

  void showRules() => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
    title: const Text('🧠 Le compte est piégé'),
    content: const SingleChildScrollView(child: Text(
      'BUT : marquer le plus de points en fermant des piles.\n\n'
      'MATÉRIEL : 48 cartes numérotées (8 de chaque valeur, de 1 à 6), trois piles communes.\n\n'
      'MISE EN PLACE : mélangez et distribuez 4 cartes par joueur. Objectif 10 ; avec un dé, lancez-le une seule fois : 1–2 = 9, 3–4 = 10, 5–6 = 11.\n\n'
      'TOUR : jouez une carte sur l’une des 3 piles, sans dépasser l’objectif. Si la somme atteint exactement l’objectif, gagnez autant de points que de cartes dans cette pile + 2 bonus, puis videz la pile. Piochez une carte si possible.\n\n'
      'SI BLOQUÉ : si aucune carte de votre main ne peut être jouée sur aucune pile, défaussez une carte de votre choix, puis piochez si possible.\n\n'
      'FIN : quand la pioche et toutes les mains sont vides. Le plus grand score gagne ; les cartes restantes sur les piles ne valent rien. Égalité possible.\n\n'
      'ASTUCE : ne donnez pas trop facilement le coup gagnant au joueur suivant !')),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris !'))],
  ));
}


class CardDecorationPainter extends CustomPainter {
  const CardDecorationPainter(this.mode);
  final int mode;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke;
    if (mode == 1) {
      p.color = const Color(0xffffd995).withValues(alpha: .75);
      p.strokeWidth = 1;
      final path = Path()..moveTo(6, 22)..lineTo(6, size.height - 11)
        ..lineTo(14, size.height - 5)..lineTo(size.width - 14, size.height - 5)
        ..lineTo(size.width - 6, size.height - 11)..lineTo(size.width - 6, 8)
        ..lineTo(size.width - 14, 4)..lineTo(16, 4);
      canvas.drawPath(path, p);
      for (var i = 0; i < 7; i++) {
        canvas.drawLine(Offset(size.width / 2, 4), Offset(i * size.width / 6, 29), p);
      }
    } else {
      p.color = Colors.white.withValues(alpha: mode == 2 ? .30 : .18);
      p.strokeWidth = mode == 2 ? 2 : 1;
      for (var i = 0; i < 9; i++) {
        final x = (i * 19.0) % (size.width + 20);
        canvas.drawLine(Offset(x, 0), Offset(x + (mode == 2 ? 24 : 7), size.height), p);
      }
      if (mode == 2) {
        final b = Paint()..color = const Color(0xffffdf58).withValues(alpha: .35);
        canvas.drawCircle(Offset(size.width * .78, size.height * .73), 18, b);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CardDecorationPainter oldDelegate) => oldDelegate.mode != mode;
}
