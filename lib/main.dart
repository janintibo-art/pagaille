import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const PagailleApp());

const ink = Color(0xff19162e);
const gold = Color(0xffffd66c);
const coral = Color(0xffff7985);
const cyan = Color(0xff63e1dc);
const cardColors = <Color>[Color(0xffef7596), Color(0xfff6b75c), Color(0xff6edbd1), Color(0xffa99af8), Color(0xff82bbfa), Color(0xffffdb7c)];

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

  Widget numberCard(int value, {bool active = false, VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 64, height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(color: cardColors[value - 1], borderRadius: BorderRadius.circular(13),
        border: Border.all(color: active ? Colors.white : ink, width: active ? 4 : 2),
        boxShadow: [BoxShadow(color: active ? gold.withValues(alpha: .55) : Colors.black38, blurRadius: active ? 17 : 7, offset: const Offset(0, 4))]),
      child: Stack(children: [
        Positioned(top: 5, left: 8, child: Text('$value', style: const TextStyle(color: ink, fontWeight: FontWeight.w900))),
        Center(child: Text('$value', style: const TextStyle(color: ink, fontSize: 44, fontWeight: FontWeight.w900))),
        Positioned(bottom: 5, right: 8, child: Text('$value', style: const TextStyle(color: ink, fontWeight: FontWeight.w900))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 850), child: Padding(
      padding: const EdgeInsets.all(14), child: !started ? welcome() : game(),
    ),
  ))));

  Widget welcome() => SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const SizedBox(height: 22), const Text('🃏 💥 🧠', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 15), const Text('PAGAILLE !', style: TextStyle(fontSize: 47, fontWeight: FontWeight.w900, color: gold)),
    const Text('LE COMPTE EST PIÉGÉ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 2, color: cyan)),
    const SizedBox(height: 16), const Text('Le jeu où un bon calcul peut offrir la victoire à ton pire adversaire.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
    const SizedBox(height: 30), pill('$playerCount joueurs'),
    Slider(value: playerCount.toDouble(), min: 2, max: 6, divisions: 4, label: '$playerCount', onChanged: (v) => setState(() => playerCount = v.round())),
    SwitchListTile(value: diceMode, onChanged: (v) => setState(() => diceMode = v), title: const Text('🎲 Dé facultatif'),
      subtitle: const Text('Détermine l’objectif : 9, 10 ou 11 (un seul lancer au début)')),
    const SizedBox(height: 13), FilledButton.icon(onPressed: newGame, icon: const Icon(Icons.play_arrow), label: const Text('LANCER LA PARTIE')),
    const SizedBox(height: 18), TextButton.icon(onPressed: () => showRules(), icon: const Icon(Icons.menu_book), label: const Text('COMMENT JOUER ?')),
    const Padding(padding: EdgeInsets.all(10), child: Text('2 à 6 joueurs • 48 cartes • 3 piles • aucun défi à réaliser\nÀ tour de rôle sur le même appareil.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
  ]));

  Widget game() => Column(children: [
    Row(children: [const Expanded(child: Text('PAGAILLE !', style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 27))),
      pill('Objectif $target', color: cyan), IconButton(onPressed: showRules, icon: const Icon(Icons.help_outline))]),
    const SizedBox(height: 6), SizedBox(height: 69, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(playerCount, (i) => Container(
      width: 112, margin: const EdgeInsets.only(right: 7), padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: i == current && !finished ? gold : const Color(0xff332e50), borderRadius: BorderRadius.circular(14)),
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
      SizedBox(height: 105, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(hands[current].length, (i) => numberCard(hands[current][i], active: selected == i,
          onTap: () => setState(() => selected = i))))))),
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
