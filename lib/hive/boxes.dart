import 'package:chatbot_with_gemini/constants.dart';
import 'package:chatbot_with_gemini/hive/settings.dart';
import 'package:chatbot_with_gemini/hive/user_model.dart';
import 'package:hive/hive.dart';
import 'chat_history.dart';

class Boxes {
  // get the chat history box
  static Box<ChatHistory> getChatHistory() =>
      Hive.box<ChatHistory>(Constants.chatHistoryBox);

  // get user box
  static Box<UserModel> getUser() =>
      Hive.box<UserModel>(Constants.userBox);

  // get settings box
  static Box<Settings> getSettings() =>
      Hive.box<Settings>(Constants.settingsBox);
}