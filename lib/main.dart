import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juego de la pelota',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _x = 0.0;
  double _y = 0.0;
  double _pelota = 50.0;
  int _puntos = 10;
  late Timer _timer;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  late List<Rect> _obstaculos;
  late List<bool> _obstaculosTocados;
  late List<Rect> _estrella;
  bool _juegoTerminado = false;
  bool _isColliding = false;
  bool _juegoGanado = false;
  late Rect _winButtonRect;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _x = MediaQuery.of(context).size.width / 2 - _pelota / 2;
        _y = MediaQuery.of(context).size.height - _pelota - 20;
        _winButtonRect = Rect.fromLTWH(
          MediaQuery.of(context).size.width - 100,
          20,
          80,
          40,
        );
      });
      _initializeObstacles();
      _initializeStars();
    });

    _timer = Timer.periodic(const Duration(milliseconds: 30), (Timer timer) {
      if (_juegoTerminado || _juegoGanado) return;

      setState(() {
        if (!_isColliding) {
          _y -= 1;
        }

        if (_y > MediaQuery.of(context).size.height - _pelota - 20) {
          setState(() {
            _juegoTerminado = true;
            _y = MediaQuery.of(context).size.height - _pelota - 20;
          });
          _timer.cancel();
          return;
        }

        bool collisionDetected = false;

        for (int i = 0; i < _obstaculos.length; i++) {
          Rect obstacle = _obstaculos[i];
          bool touched = _obstaculosTocados[i];

          if (_ballRect().overlaps(obstacle)) {
            collisionDetected = true;
            if (!touched) {
              _puntos--;
              if (_puntos <= 0) {
                _puntos = 0;
                _juegoTerminado = true;
                _timer.cancel();
              }
              _obstaculosTocados[i] = true;
              _isColliding = true;
              _y = _pelota + obstacle.top;
            }
          } else {
            _obstaculosTocados[i] = false;
          }

          double newTop = obstacle.top + 2;

          if (newTop > MediaQuery.of(context).size.height) {
            newTop = -20;
            double newLeft = Random().nextDouble() *
                (MediaQuery.of(context).size.width - obstacle.width);
            _obstaculos[i] =
                Rect.fromLTWH(newLeft, newTop, obstacle.width, obstacle.height);
            _obstaculosTocados[i] = false;
          } else {
            _obstaculos[i] = Rect.fromLTWH(
                obstacle.left, newTop, obstacle.width, obstacle.height);
          }
        }

        for (int i = 0; i < _estrella.length; i++) {
          Rect star = _estrella[i];
          if (_ballRect().overlaps(star)) {
            _puntos += 2;
            _estrella.removeAt(i);
            break;
          }
        }

        for (int i = 0; i < _estrella.length; i++) {
          Rect star = _estrella[i];
          double newTop = star.top + 2;

          if (newTop > MediaQuery.of(context).size.height) {
            newTop = -30;
            double newLeft = Random().nextDouble() *
                (MediaQuery.of(context).size.width - star.width);
            _estrella[i] =
                Rect.fromLTWH(newLeft, newTop, star.width, star.height);
          } else {
            _estrella[i] =
                Rect.fromLTWH(star.left, newTop, star.width, star.height);
          }
        }

        if (_puntos >= 20) {
          setState(() {
            _juegoGanado = true;
            _timer.cancel();
          });
        }

        if (_ballRect().overlaps(_winButtonRect)) {
          setState(() {
            _juegoGanado = true;
            _timer.cancel();
          });
        }

        if (!collisionDetected) {
          _isColliding = false;
        }
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!_isColliding) {
        setState(() {
          _x += event.y * 15;

          _x = _x.clamp(0, MediaQuery.of(context).size.width - _pelota);
        });
      }
    });
  }

  void _initializeObstacles() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _obstaculos = List.generate(5, (index) {
          double left =
              Random().nextDouble() * (MediaQuery.of(context).size.width - 50);
          double top = Random().nextDouble() * 500;
          return Rect.fromLTWH(left, top, 50, 10);
        });

        _obstaculosTocados =
            List.generate(_obstaculos.length, (index) => false);
      });
    });
  }

  void _initializeStars() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _estrella = List.generate(3, (index) {
          double left =
              Random().nextDouble() * (MediaQuery.of(context).size.width - 30);
          double top = Random().nextDouble() * 500;
          return Rect.fromLTWH(left, top, 30, 30);
        });
      });
    });
  }

  void _resetGame() {
    setState(() {
      _x = MediaQuery.of(context).size.width / 2 - _pelota / 2;
      _y = MediaQuery.of(context).size.height - _pelota - 20;
      _puntos = 10;
      _juegoTerminado = false;
      _juegoGanado = false;
      _isColliding = false;
    });
    _initializeObstacles();
    _initializeStars();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (Timer timer) {
      if (_juegoTerminado || _juegoGanado) return;

      setState(() {
        if (!_isColliding) {
          _y -= 1;
        }

        if (_y > MediaQuery.of(context).size.height - _pelota - 20) {
          setState(() {
            _juegoTerminado = true;
            _y = MediaQuery.of(context).size.height - _pelota - 20;
          });
          _timer.cancel();
          return;
        }

        bool collisionDetected = false;

        for (int i = 0; i < _obstaculos.length; i++) {
          Rect obstacle = _obstaculos[i];
          bool touched = _obstaculosTocados[i];

          if (_ballRect().overlaps(obstacle)) {
            collisionDetected = true;
            if (!touched) {
              _puntos--;
              if (_puntos <= 0) {
                _puntos = 0;
                _juegoTerminado = true;
                _timer.cancel();
              }
              _obstaculosTocados[i] = true;
              _isColliding = true;
              _y = _pelota + obstacle.top;
            }
          } else {
            _obstaculosTocados[i] = false;
          }

          double newTop = obstacle.top + 2;

          if (newTop > MediaQuery.of(context).size.height) {
            newTop = -20;
            double newLeft = Random().nextDouble() *
                (MediaQuery.of(context).size.width - obstacle.width);
            _obstaculos[i] =
                Rect.fromLTWH(newLeft, newTop, obstacle.width, obstacle.height);
            _obstaculosTocados[i] = false;
          } else {
            _obstaculos[i] = Rect.fromLTWH(
                obstacle.left, newTop, obstacle.width, obstacle.height);
          }
        }

        for (int i = 0; i < _estrella.length; i++) {
          Rect star = _estrella[i];
          if (_ballRect().overlaps(star)) {
            _puntos += 2;
            _estrella.removeAt(i);
            break;
          }
        }

        for (int i = 0; i < _estrella.length; i++) {
          Rect star = _estrella[i];
          double newTop = star.top + 2;

          if (newTop > MediaQuery.of(context).size.height) {
            newTop = -30;
            double newLeft = Random().nextDouble() *
                (MediaQuery.of(context).size.width - star.width);
            _estrella[i] =
                Rect.fromLTWH(newLeft, newTop, star.width, star.height);
          } else {
            _estrella[i] =
                Rect.fromLTWH(star.left, newTop, star.width, star.height);
          }
        }

        if (_puntos >= 20) {
          setState(() {
            _juegoGanado = true;
            _timer.cancel();
          });
        }

        if (_ballRect().overlaps(_winButtonRect)) {
          setState(() {
            _juegoGanado = true;
            _timer.cancel();
          });
        }

        if (!collisionDetected) {
          _isColliding = false;
        }
      });
    });
  }

  Rect _ballRect() {
    return Rect.fromLTWH(_x, _y, _pelota, _pelota);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego de la pelota'),
      ),
      body: Stack(
        children: [
          Positioned(
            left: _x,
            top: _y,
            child: Container(
              width: _pelota,
              height: _pelota,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _juegoTerminado
                    ? Colors.red
                    : _juegoGanado
                        ? Colors.green
                        : Colors.blue,
              ),
            ),
          ),
          ..._obstaculos.map((obstacle) {
            return Positioned(
              left: obstacle.left,
              top: obstacle.top,
              child: Container(
                width: obstacle.width,
                height: obstacle.height,
                color: Colors.black,
              ),
            );
          }).toList(),
          ..._estrella.map((star) {
            return Positioned(
              left: star.left,
              top: star.top,
              child: Container(
                width: star.width,
                height: star.height,
                color: Colors.yellow,
              ),
            );
          }).toList(),
          Positioned(
            top: 40,
            left: 20,
            child: Text(
              'Puntos: $_puntos',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Meta',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          if (_juegoTerminado)
            Center(
              child: ElevatedButton(
                onPressed: _resetGame,
                child: const Text('Reiniciar Juego'),
              ),
            ),
          if (_juegoGanado)
            Center(
              child: ElevatedButton(
                onPressed: _resetGame,
                child: const Text('Ganaste! Reiniciar Juego'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gyroscopeSubscription.cancel();
    _timer.cancel();
    super.dispose();
  }
}
