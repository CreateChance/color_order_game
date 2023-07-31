import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColorOrder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Color Order Game'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MaterialColor _color = Colors.blue;
  List<Color> _colors = [];

  int _slot = 0;
  double _offset = 0;
  final GlobalKey _globalKey = GlobalKey();

  _shuffle() {
    setState(() {
      _color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
      _colors = List.generate(8, (index) => _color[(index + 1) * 100]!);
      _colors.shuffle();
    });
  }

  bool _checkWin() {
    List<double> lum =
        _colors.map((c) => c.computeLuminance()).toList(growable: false);
    bool win = true;
    for (int i = 0; i < lum.length - 1; i++) {
      if (lum[i] < lum[i + 1]) {
        win = false;
        break;
      }
    }
    return win;
  }

  _notifyWinByDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("You Win"),
                  TextButton(
                      onPressed: () {
                        _shuffle();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Start a new game!"))
                ],
              ),
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Arrange colors from light to deep",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Listener(
              onPointerMove: (event) {
                double y = event.position.dy - _offset;
                if (y > (_slot + 1) * Box.height) {
                  if (_slot == _colors.length - 1) return;
                  setState(() {
                    final c = _colors[_slot];
                    _colors[_slot] = _colors[_slot + 1];
                    _colors[_slot + 1] = c;
                    _slot++;
                  });
                } else if (y < _slot * Box.height) {
                  if (_slot == 0) return;
                  setState(() {
                    final c = _colors[_slot - 1];
                    _colors[_slot - 1] = _colors[_slot];
                    _colors[_slot] = c;
                    _slot--;
                  });
                }
              },
              child: SizedBox(
                width: Box.width,
                height: _colors.length * Box.height,
                child: Stack(
                  key: _globalKey,
                  children: List.generate(_colors.length, (index) {
                    return Box(
                      _colors[index],
                      0,
                      index * Box.height,
                      (color) {
                        _slot = _colors.indexOf(color);
                        // 这个时候需要计算一下 app bar 高度，在拖动的时候需要减去这个
                        _offset = (_globalKey.currentContext!.findRenderObject()
                                as RenderBox)
                            .localToGlobal(Offset.zero)
                            .dy;
                      },
                      () {
                        if (_checkWin()) {
                          _notifyWinByDialog();
                        }
                      },
                      key: ValueKey(_colors[index]),
                    );
                  }),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Be careful!"),
                  content: const Text(
                      "You haven't finished the game yet, sure to restart?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancel")),
                    TextButton(
                        onPressed: () {
                          _shuffle();
                          Navigator.of(context).pop();
                        },
                        child: const Text("Restart")),
                  ],
                );
              });
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class Box extends StatelessWidget {
  static const width = 150.0;
  static const height = 50.0;

  final Color color;
  final double x;
  final double y;
  final Function(Color color) onDrag;
  final Function() onDragEnd;

  const Box(this.color, this.x, this.y, this.onDrag, this.onDragEnd,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: x,
      top: y,
      duration: const Duration(milliseconds: 100),
      child: Draggable(
        onDragStarted: () {
          onDrag(color);
        },
        onDragEnd: (_) {
          onDragEnd();
        },
        feedback: Container(
          width: width,
          height: height,
          color: color,
        ),
        childWhenDragging: const SizedBox(
          width: width,
          height: height,
        ),
        child: Container(
          width: width,
          height: height,
          color: color,
        ),
      ),
    );
  }
}
