import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math';

void main() {
  runApp(Game24App());
}

class Game24App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'เกม 24 (ผู้พิการทางสายตา)',
      home: Game24HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Game24HomePage extends StatefulWidget {
  @override
  _Game24HomePageState createState() => _Game24HomePageState();
}

class _Game24HomePageState extends State<Game24HomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  String spokenText = '';
  List<int> currentNumbers = [];

  @override
  void initState() {
    super.initState();
    initSpeech();
    welcomeMessage(); // เริ่มพูดทันที
  }

  Future<void> initSpeech() async {
    await speech.initialize();
  }

  Future<void> welcomeMessage() async {
    await flutterTts.setLanguage("th-TH");
    await flutterTts.setSpeechRate(0.5);

    await flutterTts.speak("ยินดีต้อนรับสู่เกม 24");
    await flutterTts.awaitSpeakCompletion(true);

    await flutterTts.speak("เกมนี้สำหรับผู้พิการทางสายตา");
    await flutterTts.awaitSpeakCompletion(true);

    await flutterTts.speak("คุณสามารถพูดว่า เริ่มเกม เพื่อเริ่มเล่น");
    await flutterTts.awaitSpeakCompletion(true);

    await flutterTts.speak("หรือพูดว่า ขอเลขซ้ำ เพื่อฟังเลขอีกครั้ง");
    await flutterTts.awaitSpeakCompletion(true);

    listenForCommand(); // เริ่มฟังทันที
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("th-TH");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  void generateNewGame() {
    Random random = Random();
    currentNumbers = List.generate(4, (_) => random.nextInt(9) + 1);
    String numberText = currentNumbers.join(", ");
    speak("ตัวเลขคือ $numberText");
    setState(() {});
  }

  void repeatNumbers() {
    if (currentNumbers.isNotEmpty) {
      String numberText = currentNumbers.join(", ");
      speak("ตัวเลขคือ $numberText");
    } else {
      speak("ยังไม่มีตัวเลข กรุณาเริ่มเกมก่อน");
    }
  }

  void listenForCommand() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(
        localeId: "th_TH",
        onResult: (result) {
          String command = result.recognizedWords;
          setState(() {
            spokenText = command;
          });

          if (command.contains("เริ่มเกม")) {
            speak("เริ่มเกม");
            generateNewGame();
          } else if (command.contains("ขอเลขซ้ำ")) {
            repeatNumbers();
          } else if (command.contains("ได้คำตอบแล้ว")) {
            speak("ฉันกำลังฟัง");
            listenForAnswer();
          } else {
            speak("ไม่เข้าใจคำสั่ง");
          }
        },
      );
    } else {
      speak("ไม่สามารถเปิดไมโครโฟนได้");
    }
  }

  void listenForAnswer() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(
        localeId: "th_TH",
        onResult: (result) {
          String answer = result.recognizedWords;
          setState(() {
            spokenText = answer;
          });
          speak("คุณพูดว่า $answer");
          // ตรวจคำตอบได้ที่นี่
        },
      );
    }
  }

  void exitApp() {
    speak("ขอบคุณที่เล่นเกม 24").then((_) {
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("เกม 24 (ผู้พิการทางสายตา)"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'แตะปุ่มหรือพูดคำสั่งเสียง',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),

            if (currentNumbers.isNotEmpty)
              Text(
                'ตัวเลข: ${currentNumbers.join(', ')}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: generateNewGame,
              child: Text("เริ่มโจทย์ใหม่"),
            ),
            ElevatedButton(
              onPressed: repeatNumbers,
              child: Text("ขอเลขซ้ำ"),
            ),
            ElevatedButton(
              onPressed: () {
                speak("ฉันกำลังฟัง");
                listenForAnswer();
              },
              child: Text("พูดคำตอบ"),
            ),
            ElevatedButton(
              onPressed: () {
                flutterTts.speak("ทดสอบเสียงพูด");
              },
              child: Text("ทดสอบเสียง"),
            ),
            SizedBox(height: 20),
            Text('คุณพูดว่า: $spokenText'),
            Spacer(),
            ElevatedButton(
              onPressed: exitApp,
              child: Text("ออกจากแอป"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
