import 'package:chatbot_with_gemini/providers/chat_provider.dart';
import 'package:chatbot_with_gemini/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await ChatProvider.initHive();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// void main() => runApp(const MyApp());
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Gemini Chat',
//       home: GeminiChatScreen(),
//     );
//   }
// }
//
// class GeminiChatScreen extends StatefulWidget {
//   @override
//   _GeminiChatScreenState createState() => _GeminiChatScreenState();
// }
//
// class _GeminiChatScreenState extends State<GeminiChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final List<Map<String, String>> _messages = [];
//
//   final String _apiKey = "AIzaSyBVf0enlZjUVbPOn2iLvhiJvmFQlLQMCo4"; // Replace with your Gemini API key
//   final String _apiUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash-002:generateContent";
//
//   Future<void> _sendMessage(String message) async {
//     setState(() {
//       _messages.add({"role": "user", "text": message});
//     });
//
//     final response = await http.post(
//       Uri.parse("$_apiUrl?key=$_apiKey"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "contents": [
//           {
//             "parts": [
//               {"text": message}
//             ]
//           }
//         ]
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       final json = jsonDecode(response.body);
//       final reply = json['candidates'][0]['content']['parts'][0]['text'];
//       setState(() {
//         _messages.add({"role": "gemini", "text": reply});
//       });
//     } else {
//       setState(() {
//         _messages.add({
//           "role": "gemini",
//           "text": "Error: ${response.statusCode}\n${response.body}"
//         });
//       });
//     }
//
//     _controller.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Gemini Chat')),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(8),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final msg = _messages[index];
//                 final isUser = msg['role'] == 'user';
//                 return Align(
//                   alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     margin: const EdgeInsets.symmetric(vertical: 4),
//                     decoration: BoxDecoration(
//                       color: isUser ? Colors.blue[100] : Colors.grey[300],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(msg['text'] ?? ''),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     onSubmitted: _sendMessage,
//                     decoration: const InputDecoration(
//                       hintText: "Type your message...",
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: () => _sendMessage(_controller.text),
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
