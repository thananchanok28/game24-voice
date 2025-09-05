import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const Game24App());
}

class Game24App extends StatelessWidget {
  const Game24App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'เกม 24 ผู้พิการทางสายตา',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Game24Page(),
    );
  }
}

class Game24Page extends StatefulWidget {
  const Game24Page({super.key});

  @override
  State<Game24Page> createState() => _Game24PageState();
}

class _Game24PageState extends State<Game24Page> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final Random _random = Random();

  List<int> numbers = [];
  String recognizedText = "";
  bool isListening = false;
  final TextEditingController _textController = TextEditingController();

  final Map<String, String> numberThai = {
    "1": "หนึ่ง",
    "2": "สอง",
    "3": "สาม",
    "4": "สี่",
    "5": "ห้า",
    "6": "หก",
    "7": "เจ็ด",
    "8": "แปด",
    "9": "เก้า",
  };

  final Map<String, String> opThai = {
    "+": "บวก",
    "-": "ลบ",
    "*": "คูณ",
    "/": "หาร",
  };

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage("th-TH");
    _speakIntro();
    _generateNumbers();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _speakIntro() async {
    await _speak(
        "ยินดีต้อนรับสู่เกม 24 สำหรับผู้พิการทางสายตา คุณจะได้ยินตัวเลข 4 ตัว "
        "จงใช้บวก ลบ คูณ หาร เพื่อให้ได้ 24 "
        "คุณสามารถพูดว่า สุ่มเลข เพื่อเริ่มใหม่ พูดว่า ฟัง เพื่อให้ระบบฟังคำตอบ หรือพูดว่า เลิกเล่น เพื่อออกจากเกม");
  }

  void _generateNumbers() {
    setState(() {
      numbers = List.generate(4, (_) => _random.nextInt(9) + 1);
    });
    _speak("เลขของคุณคือ ${numbers.join(", ")}");
  }

  Future<void> _listen() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          recognizedText = result.recognizedWords;
        });
        if (result.finalResult) {
          setState(() => isListening = false);
          _checkAnswer(recognizedText);
        }
      });
    } else {
      await _speak("ไม่สามารถเปิดไมโครโฟนได้");
    }
  }

  void _checkAnswer(String answer) {
    Map<String, String> thaiToSymbol = {
      "บวก": "+",
      "ลบ": "-",
      "คูณ": "*",
      "หาร": "/",
      "หนึ่ง": "1",
      "สอง": "2",
      "สาม": "3",
      "สี่": "4",
      "ห้า": "5",
      "หก": "6",
      "เจ็ด": "7",
      "แปด": "8",
      "เก้า": "9"
    };

    String expr = answer;
    thaiToSymbol.forEach((k, v) {
      expr = expr.replaceAll(k, v);
    });

    bool correct = false;
    try {
      double result = _evaluateExpression(expr);
      if ((result - 24).abs() < 0.001) {
        correct = true;
      }
    } catch (_) {}

    if (correct) {
      _speak("ถูกต้อง!");
    } else {
      String? solution = _find24Solution(numbers);
      if (solution != null) {
        String thaiSolution = _convertToThaiExpression(solution);
        _speak("ผิด! วิธีทำที่ถูกต้องคือ $thaiSolution เท่ากับยี่สิบสี่");
      } else {
        _speak("ผิด! ไม่มีวิธีทำให้ได้ 24 กับเลขนี้");
      }
    }

    Future.delayed(const Duration(seconds: 4), () {
      _generateNumbers();
      _listen();
    });
  }

  double _evaluateExpression(String expr) {
    List<String> tokens = [];
    String current = "";
    for (int i = 0; i < expr.length; i++) {
      String c = expr[i];
      if ("+-*/".contains(c)) {
        if (current.isNotEmpty) {
          tokens.add(current);
          current = "";
        }
        tokens.add(c);
      } else {
        current += c;
      }
    }
    if (current.isNotEmpty) tokens.add(current);

    double result = double.parse(tokens[0]);
    for (int i = 1; i < tokens.length; i += 2) {
      String op = tokens[i];
      double num = double.parse(tokens[i + 1]);
      if (op == "+") result += num;
      if (op == "-") result -= num;
      if (op == "*") result *= num;
      if (op == "/") result /= num;
    }
    return result;
  }

  String _convertToThaiExpression(String expr) {
    String thai = expr;
    numberThai.forEach((k, v) {
      thai = thai.replaceAll(k, v);
    });
    opThai.forEach((k, v) {
      thai = thai.replaceAll(k, v);
    });
    return thai;
  }

  String? _find24Solution(List<int> nums) {
    List<String> ops = ["+", "-", "*", "/"];
    List<List<int>> permutations = _permute(nums);
    for (var p in permutations) {
      for (var o1 in ops) {
        for (var o2 in ops) {
          for (var o3 in ops) {
            List<String> patterns = [
              "(${p[0]}$o1${p[1]})$o2(${p[2]}$o3${p[3]})",
              "(${p[0]}$o1(${p[1]}$o2${p[2]}))$o3${p[3]}",
              "${p[0]}$o1(${p[1]}$o2(${p[2]}$o3${p[3]}))",
              "(${p[0]}$o1${p[1]})$o2${p[2]}$o3${p[3]}",
              "${p[0]}$o1${p[1]}$o2${p[2]}$o3${p[3]}"
            ];
            for (var pattern in patterns) {
              try {
                if ((_evaluateExpression(pattern) - 24).abs() < 0.001) {
                  return pattern;
                }
              } catch (_) {}
            }
          }
        }
      }
    }
    return null;
  }

  List<List<int>> _permute(List<int> nums) {
    if (nums.length == 1) return [nums];
    List<List<int>> result = [];
    for (int i = 0; i < nums.length; i++) {
      int n = nums[i];
      List<int> rest = List.from(nums)..removeAt(i);
      for (var p in _permute(rest)) {
        result.add([n, ...p]);
      }
    }
    return result;
  }

  void _submitTextAnswer() {
    _checkAnswer(_textController.text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เกม 24 ผู้พิการทางสายตา")),
      body: Container(
        color: Colors.blue[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("เลขสุ่ม: ${numbers.join(", ")}",
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateNumbers,
                child: const Text("สุ่มเลขใหม่"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _listen,
                child: Text(isListening ? "กำลังฟัง..." : "พูดคำตอบ"),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: "พิมพ์คำตอบ",
                  ),
                  onSubmitted: (_) => _submitTextAnswer(),
                ),
              ),
              const SizedBox(height: 20),
              Text("สิ่งที่ได้ยิน: $recognizedText",
                  style: const TextStyle(fontSize: 18)),
              const Spacer(),
              const Text(
                "พัฒนาระบบล่าสุดเมื่อวันที่ 3 ก.ย. 68",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
