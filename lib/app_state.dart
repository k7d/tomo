import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tomo/platform.dart' as platform;
import 'package:tomo/sound.dart';
import 'package:tomo/theme.dart';

const dismissTimerIn = Duration(seconds: 5);
const int maxTimerTomos = 10;

typedef TimerId = String;

class TimerConfig {
  final TimerId id;
  ColorName color;
  Sound sound;
  String name;
  Duration duration;
  String? startNextId;

  get plusDuration =>
      const Duration(minutes: 5); // TODO make this configurable?

  TimerConfig({
    required this.id,
    required this.color,
    required this.sound,
    required this.name,
    required this.duration,
    this.startNextId,
  });

  Object serialize() {
    return {
      'id': id,
      'color': color.toString().split('.').last,
      'sound': sound.toString().split('.').last,
      'name': name,
      'duration': duration.inSeconds,
      'startNextId': startNextId,
    };
  }

  factory TimerConfig.deserialize(Map config) {
    return TimerConfig(
      id: config['id'],
      color: ColorName.values.firstWhere(
          (e) => e.toString() == 'ColorName.${config['color']}',
          orElse: () => ColorName.color1),
      sound: Sound.values.firstWhere(
          (e) => e.toString() == 'Sound.${config['sound']}',
          orElse: () => Sound.values.first),
      name: config['name'],
      duration: Duration(seconds: config['duration']),
      startNextId: config['startNextId'],
    );
  }
}

extension GetTimerConfig on List<TimerConfig> {
  TimerConfig? getTimerConfig(String id) {
    return firstWhere((config) => config.id == id);
  }
}

sealed class TimerWithConfig {
  TimerConfig get config;
}

class StartableTimer extends TimerWithConfig {
  @override
  final TimerConfig config;

  StartableTimer(this.config);
}

Duration calcRemaining(DateTime start, DateTime now, Duration duration) {
  var remaining = duration - now.difference(start);
  if (remaining.isNegative) {
    return Duration.zero;
  } else {
    return remaining;
  }
}

enum TimerState { done, running, paused }

typedef Date = String;

extension GetIsoDate on DateTime {
  String toSlashDateString() {
    return toIso8601String().split('T').first.replaceAll('-', '/');
  }
}

typedef TimerHistory = Map<Date, Map<TimerId, Map<int, int>>>;

extension TimerHistoryExt on TimerHistory {
  void upsertRun(StartedTimer timer, Duration duration) {
    final date = timer.start.toSlashDateString();
    final currentDuration = DateTime.now().difference(timer.start);
    duration = currentDuration < duration ? currentDuration : duration;
    putIfAbsent(date, () => {});
    update(date, (dateTimers) {
      dateTimers.putIfAbsent(timer.config.id, () => {});
      dateTimers.update(timer.config.id, (timerRuns) {
        timerRuns[timer.start.millisecondsSinceEpoch] = duration.inSeconds;
        return timerRuns;
      }, ifAbsent: () {
        return {timer.start.millisecondsSinceEpoch: duration.inSeconds};
      });
      return dateTimers;
    });
  }

  void mergeHistory(TimerHistory history) {
    for (var entry in history.entries) {
      putIfAbsent(entry.key, () => {});
      update(entry.key, (dateTimers) {
        for (var timerEntry in entry.value.entries) {
          dateTimers.putIfAbsent(timerEntry.key, () => {});
          dateTimers.update(timerEntry.key, (timerRuns) {
            for (var runEntry in timerEntry.value.entries) {
              timerRuns[runEntry.key] = runEntry.value;
            }
            return timerRuns;
          });
        }
        return dateTimers;
      });
    }
  }
}

class StartedTimer extends TimerWithConfig {
  @override
  final TimerConfig config;
  final DateTime start;
  Duration adjustedDuration;
  Duration totalDuration;
  bool isPaused;
  TimerHistory? history;

  StartedTimer({
    required this.config,
    required this.start,
    required this.adjustedDuration,
    required this.totalDuration,
    required this.isPaused,
    this.history,
  });

  Duration get remaining => isPaused
      ? adjustedDuration
      : calcRemaining(start, DateTime.now(), adjustedDuration);

  TimerState get state {
    if (remaining == Duration.zero) {
      return TimerState.done;
    } else if (isPaused) {
      return TimerState.paused;
    } else {
      return TimerState.running;
    }
  }

  double get completed =>
      (totalDuration - remaining).inSeconds / totalDuration.inSeconds;

  DateTime? get finish => start.add(adjustedDuration);

  // SERIALIZATION

  Object serialize() {
    return {
      "id": config.id,
      "start": start.toIso8601String(),
      "adjusted-duration": adjustedDuration.inSeconds,
      "total-duration": totalDuration.inSeconds,
      "paused?": isPaused,
    };
  }

  factory StartedTimer.deserialize(Object object, List<TimerConfig> configs) {
    assert(object is Map);
    Map map = object as Map;
    final config = configs.getTimerConfig(map["id"] as String);
    assert(config != null);
    return StartedTimer(
        config: config!,
        start: DateTime.parse(object["start"] as String),
        adjustedDuration: Duration(seconds: object["adjusted-duration"] as int),
        totalDuration: Duration(seconds: object["total-duration"] as int),
        isPaused: object["paused?"] as bool);
  }
}

class AppState extends ChangeNotifier {
  static bool syncEnabled = false;

  AppState() {
    init();
  }

  User? _user;

  User? get user => _user;

  // TIMER CONFIGS

  List<TimerConfig> timerConfigs = [];

  Future<void> _persistTimerConfigsOnDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final json =
        jsonEncode(timerConfigs.map((config) => config.serialize()).toList());
    await prefs.setString('timerConfigs', json);
  }

  Future<void> _persistTimerConfigs() async {
    await _persistTimerConfigsOnDevice();
    if (_timerConfigsRef != null) {
      await _timerConfigsRef!
          .set(timerConfigs.map((config) => config.serialize()).toList());
    }
  }

  void updateTimerConfig(TimerConfig config) {
    final index = timerConfigs.indexWhere((c) => c.id == config.id);
    timerConfigs[index] = config;
    _persistTimerConfigs();
    notifyListeners();
  }

  // ADD NEW TIMER

  TimerConfig addNewTimer() {
    final id = const Uuid().v4();

    final usedColors = timerConfigs.map((c) => c.color).toSet();
    final availableColors = ColorName.values.toSet().difference(usedColors);
    final color = availableColors.isNotEmpty
        ? availableColors.elementAt(Random().nextInt(availableColors.length))
        : ColorName.values[Random().nextInt(ColorName.values.length)];

    final config = TimerConfig(
      id: id,
      color: color,
      sound: Sound.values.first,
      name: 'Timer ${timerConfigs.length + 1}',
      duration: const Duration(minutes: 10),
    );
    timerConfigs.add(config);
    _persistTimerConfigs();
    notifyListeners();
    return config;
  }

  // DELETE TIMER

  void deleteTimer(TimerConfig config) {
    timerConfigs.removeWhere((c) => c.id == config.id);
    _persistTimerConfigs();
    notifyListeners();
  }

  // STARTABLE TIMERS

  List<StartableTimer> get timers =>
      [for (var config in timerConfigs) StartableTimer(config)];

  // LAST ACTION

  StartedTimer? _lastAction;

  Future<void> _persistLastActionOnDevice() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastAction == null) {
      await prefs.remove('lastAction');
    } else {
      final json = jsonEncode(_lastAction!.serialize());
      await prefs.setString('lastAction', json);
    }
  }

  Future<void> _setLastAction(StartedTimer? timer) async {
    _lastAction = timer;
    // Persist locally
    await _persistLastActionOnDevice();
    if (_lastActionRef != null) {
      // Persist to Firebase
      if (timer == null) {
        await _lastActionRef!.remove();
      } else {
        await _lastActionRef!.set(timer.serialize());
      }
    }
  }

  // CURRENT / ACTIVE TIMER

  (StartedTimer?, bool) _getCurrentTimer() {
    // TODO - history
    var timer = _lastAction;
    if (timer == null) {
      return (null, false);
    }
    var history = TimerHistory();
    for (var i = 0; i < maxTimerTomos; i++) {
      var config = timer!.config,
          duration = i == 0 ? timer.adjustedDuration : config.duration,
          nextStart = timer.start.add(duration).add(dismissTimerIn);
      history.upsertRun(timer, duration);
      timer.history = history;
      if (DateTime.now().isBefore(nextStart)) {
        return (timer, true);
      } else {
        if (config.startNextId != null) {
          var nextConfig = timerConfigs.getTimerConfig(config.startNextId!);
          if (nextConfig == null) {
            return (timer, false);
          }
          timer = StartedTimer(
              config: nextConfig,
              start: nextStart,
              adjustedDuration: nextConfig.duration,
              totalDuration: nextConfig.duration,
              isPaused: false);
        } else {
          return (timer, false);
        }
      }
    }
    return (timer, false);
  }

  StartedTimer? getActiveTimer() {
    final (timer, active) = _getCurrentTimer();
    if (!active) {
      return null;
    }
    return timer;
  }

  // NEXT TIMER

  StartableTimer? getNextTimer(StartedTimer timer) {
    if (timer.config.startNextId == null) {
      return null;
    }
    final nextConfig = timerConfigs.getTimerConfig(timer.config.startNextId!);
    if (nextConfig == null) {
      return null;
    }
    return StartableTimer(nextConfig);
  }

  // START TIMER

  void startTimer(TimerWithConfig timer) {
    var (current, _) = _getCurrentTimer();
    commitToHistory(current);
    var now = DateTime.now(),
        isPaused = current?.isPaused ?? false,
        duration = isPaused ? current!.adjustedDuration : timer.config.duration;
    _setLastAction(StartedTimer(
        config: timer.config,
        start: now,
        adjustedDuration: duration,
        totalDuration: isPaused ? current!.totalDuration : duration,
        isPaused: false));
    _restartTicker();
    _ensureTodayHistorySub();
    platform.closeWindow();
    notifyListeners();
  }

  // STOP TIMER

  void stopTimer() {
    var timer = getActiveTimer();
    if (timer == null) {
      return;
    }
    commitToHistory(timer);
    _setLastAction(null);
    notifyListeners();
  }

  // PAUSE TIMER

  void pauseTimer() {
    var timer = getActiveTimer();
    if (timer == null) {
      return;
    }
    commitToHistory(timer);
    var now = DateTime.now();
    var duration = calcRemaining(timer.start, now, timer.adjustedDuration);
    _setLastAction(StartedTimer(
        config: timer.config,
        start: now,
        adjustedDuration: duration,
        totalDuration: timer.totalDuration,
        isPaused: true));
    notifyListeners();
  }

  // RESUME TIMER

  void resumeTimer() {
    var timer = getActiveTimer();
    if (timer == null) {
      return;
    }
    startTimer(timer);
  }

  // PLUS TIMER

  void plusTimer() {
    var timer = getActiveTimer();
    if (timer == null) {
      return;
    }
    commitToHistory(timer);
    final adjustedDuration = timer.remaining + timer.config.plusDuration;
    final totalDuration = timer.totalDuration + timer.config.plusDuration;
    _setLastAction(StartedTimer(
      config: timer.config,
      start: DateTime.now(),
      adjustedDuration: adjustedDuration,
      totalDuration: totalDuration,
      isPaused: false,
    ));
    _restartTicker();
    _ensureTodayHistorySub();
    platform.closeWindow();
    notifyListeners();
  }

  // RESTART TIMER

  void restartTimer() {
    var timer = getActiveTimer();
    if (timer == null) {
      return;
    }
    stopTimer();
    startTimer(timer);
  }

  // HISTORY

  final TimerHistory _committedHistory = {};

  void commitToHistory(StartedTimer? timer) {
    if (timer?.history == null) {
      return;
    }
    _committedHistory.mergeHistory(timer!.history!);
    _pushHistory(timer.history!);
  }

  Future<void> _pushHistory(TimerHistory history) async {
    if (_user == null) {
      return;
    }
    for (var entry in history.entries) {
      final date = entry.key;
      final basePath = 'users/${_user!.uid}/timers/history/$date';
      for (var timerEntry in entry.value.entries) {
        final timerId = timerEntry.key;
        for (var runEntry in timerEntry.value.entries) {
          final start = runEntry.key;
          final duration = runEntry.value;
          final ref =
              FirebaseDatabase.instance.ref('$basePath/$timerId/$start');
          await ref.set(duration);
        }
      }
    }
  }

  TimerHistory get _history {
    final (timer, _) = _getCurrentTimer();
    if (timer?.history == null) {
      return _committedHistory;
    }
    var history = TimerHistory();
    history.mergeHistory(_committedHistory);
    history.mergeHistory(timer!.history!);
    return history;
  }

  Duration getCurrentDayDuration(TimerId id) {
    final today = _history[DateTime.now().toSlashDateString()];
    if (today == null) {
      return Duration.zero;
    }
    final timerRuns = today[id];
    if (timerRuns == null) {
      return Duration.zero;
    }
    return Duration(
        seconds: timerRuns.values.fold(0, (sum, duration) {
      return sum + duration;
    }));
  }

  // TICK

  Timer? _tick;

  void _restartTicker() {
    if (_tick != null) {
      _tick!.cancel();
    }

    String? idBefore;
    DateTime? startBefore;
    Duration? remainingBefore;
    TimerState? stateBefore;

    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final timer = getActiveTimer();
      if (timer?.config.id != idBefore ||
          timer?.start != startBefore ||
          timer?.remaining != remainingBefore ||
          timer?.state != stateBefore) {
        notifyListeners();
        if (timer?.state == TimerState.done && stateBefore != TimerState.done) {
          platform.openWindow();
          playSound(timer!.config.sound);
        }
        idBefore = timer?.config.id;
        startBefore = timer?.start;
        remainingBefore = timer?.remaining;
        stateBefore = timer?.state;
      }
    });
  }

  // FIREBASE SYNC

  DatabaseReference? _lastActionRef;
  StreamSubscription<DatabaseEvent>? _lastActionSub;

  DatabaseReference? _timerConfigsRef;
  StreamSubscription<DatabaseEvent>? _timerConfigsSub;

  StreamSubscription<DatabaseEvent>? _todayHistorySub;
  String? _todayHistorySubDate;

  void _ensureTodayHistorySub() {
    if (_user == null) {
      return;
    }
    final date = DateTime.now().toSlashDateString();
    if (_todayHistorySubDate == date) {
      return;
    }
    _todayHistorySub?.cancel();
    final ref = FirebaseDatabase.instance
        .ref('users/${_user!.uid}/timers/history/$date');
    _todayHistorySub = ref.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value == null) {
        return;
      }
      Map<TimerId, Map<int, int>> history =
          (event.snapshot.value as Map<dynamic, dynamic>).map(
        (key, value) => MapEntry(
          key as String,
          (value as Map<dynamic, dynamic>).map(
            (k, v) => MapEntry(int.parse(k as String), v as int),
          ),
        ),
      );
      _committedHistory.mergeHistory({date: history});
      notifyListeners();
    });
  }

  void _startFirebaseSync(User user) {
    _user = user;

    final db = FirebaseDatabase.instance;
    db.setPersistenceEnabled(true);

    _timerConfigsRef = db.ref('users/${_user!.uid}/timers/configs');
    _timerConfigsSub = _timerConfigsRef!.onValue.listen(
      (DatabaseEvent event) {
        final value = event.snapshot.value;
        if (value == null) {
          return;
        }
        final configsList = value as List<dynamic>;
        timerConfigs = configsList
            .map((config) => TimerConfig.deserialize(config))
            .toList();
        _persistTimerConfigsOnDevice();
        notifyListeners();
      },
      onError: (Object o) {
        final error = o as FirebaseException;
        debugPrint("Firebase error $error");
      },
    );

    _lastActionRef = db.ref('users/${_user!.uid}/timers/last-action');
    _lastActionSub = _lastActionRef!.onValue.listen(
      (DatabaseEvent event) {
        final value = event.snapshot.value;
        if (value == null) {
          return;
        }
        _lastAction = StartedTimer.deserialize(value, timerConfigs);
        _persistLastActionOnDevice();
        notifyListeners();
      },
      onError: (Object o) {
        final error = o as FirebaseException;
        debugPrint("Firebase error $error");
      },
    );

    _ensureTodayHistorySub();
  }

  void _stopFirebaseSync() {
    _user = null;
    _timerConfigsRef = null;
    _timerConfigsSub?.cancel();
    _timerConfigsSub = null;
    _lastActionRef = null;
    _lastActionSub?.cancel();
    _lastActionSub = null;
    _todayHistorySub?.cancel();
    _todayHistorySub = null;
    _todayHistorySubDate = null;
  }

  // INIT / DISPOSE

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final timerConfigsJson = prefs.getString('timerConfigs');
    if (timerConfigsJson != null) {
      final List<dynamic> configsList = jsonDecode(timerConfigsJson);
      timerConfigs =
          configsList.map((config) => TimerConfig.deserialize(config)).toList();
    } else {
      // Default configs if none are saved
      timerConfigs = [
        TimerConfig(
          id: "focus",
          color: ColorName.color1,
          sound: Sound.bowl,
          name: 'Focus',
          duration: const Duration(minutes: 25),
          startNextId: "break",
        ),
        TimerConfig(
          id: "break",
          color: ColorName.color3,
          sound: Sound.bird,
          name: 'Break',
          duration: const Duration(minutes: 5),
        )
      ];
    }

    final lastActionJson = prefs.getString('lastAction');
    if (lastActionJson != null) {
      _lastAction =
          StartedTimer.deserialize(jsonDecode(lastActionJson), timerConfigs);
    }

    _restartTicker();

    // since init is async, notify listeners to ensure UI is updated
    notifyListeners();

    if (AppState.syncEnabled) {
      FirebaseAuth.instance.userChanges().listen((user) {
        if (user != null) {
          _startFirebaseSync(user);
        } else {
          _stopFirebaseSync();
        }
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _stopFirebaseSync();
  }
}
