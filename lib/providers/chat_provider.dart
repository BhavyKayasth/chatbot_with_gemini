import 'dart:developer';
import 'dart:typed_data';
import 'package:chatbot_with_gemini/api/api_service.dart';
import 'package:chatbot_with_gemini/constants.dart';
import 'package:chatbot_with_gemini/hive/chat_history.dart';
import 'package:chatbot_with_gemini/hive/settings.dart';
import 'package:chatbot_with_gemini/hive/user_model.dart';
import 'package:chatbot_with_gemini/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  // list of messages
  final List<Message> _inChatMessages = [];

  // page controller
  final PageController _pageController = PageController();

  // image file list
  List<XFile>? _imagesFileList = [];

  // index of current screen
  int _currentIndex = 0;

  // current chatId
  String _currentChatId = '';

  // initialize generative model
  GenerativeModel? _model;

  // initialize text model
  GenerativeModel? _textModel;

  // initialize vision model
  GenerativeModel? _visionModel;

  // current model
  String _modelType = 'gemini-pro';

  // loading bool
  bool _isLoading = false;

  // getters
  List<Message> get inChatMessages => _inChatMessages;

  PageController get pageController => _pageController;

  List<XFile>? get imagesFileList => _imagesFileList;

  int get currentIndex => _currentIndex;

  String get currentChatId => _currentChatId;

  GenerativeModel? get model => _model;

  GenerativeModel? get textModel => _textModel;

  GenerativeModel? get visionModel => _visionModel;

  String get modelType => _modelType;

  bool get isLoading => _isLoading;

  // setters

  //set in chatMessages
  Future<void> setInChatMessages({required String chatId}) async {
    // get messages from hive db
    final messagesFromDB = await loadMessagesFromDB(chatId: chatId);

    for (var message in messagesFromDB) {
      if (!_inChatMessages.contains(message)) {
        _inChatMessages.add(message);
        log('message already exists');
        continue;
      }
    }
  }

  // load the message from db
  Future<List<Message>> loadMessagesFromDB({required String chatId}) async {
    // open the box of this chatId
    await Hive.openBox('${Constants.chatMessagesBox}$chatId');

    final messageBox = Hive.box('${Constants.chatMessagesBox}$chatId');

    final newData =
        messageBox.keys.map((e) {
          final message = messageBox.get(e);
          final messageData = Message.fromMap(
            Map<String, dynamic>.from(message),
          );

          return messageData;
        }).toList();
    notifyListeners();
    return newData;
  }

  // set file list
  void setImageFileList({required List<XFile> listValue}) {
    _imagesFileList = listValue;
    notifyListeners();
  }

  // set the current model
  String setCurrentModel({required String newModel}) {
    _modelType = newModel;
    notifyListeners();
    return _modelType;
  }

  // function to set the model based on bool - isTextOnly
  // Future<void> setModel({required bool isTextOnly}) async {
  //   if (isTextOnly) {
  //     _model = _textModel ??
  //         GenerativeModel(
  //           model: setCurrentModel(newModel: 'gemini-1.5-flash'),
  //           apiKey: ApiService.apiKey,
  //         );
  //   } else {
  //     try {
  //       _model = _visionModel ??
  //           GenerativeModel(
  //             model: setCurrentModel(newModel: 'gemini-1.5-pro'),
  //             apiKey: ApiService.apiKey,
  //           );
  //     } catch (e) {
  //       log('Model fallback error: $e');
  //       _model = GenerativeModel(
  //         model: setCurrentModel(newModel: 'gemini-1.5-flash'),
  //         apiKey: ApiService.apiKey,
  //       );
  //     }
  //   }
  // }


  Future<void> setModel({required bool isTextOnly}) async {
    if (isTextOnly) {
      _model =
          _textModel ??
          GenerativeModel(
            model: setCurrentModel(newModel: 'gemini-1.5-flash'),
            apiKey: ApiService.apiKey,
          );
    } else {
      _model =
          _visionModel ??
          GenerativeModel(
            model: setCurrentModel(newModel: 'gemini-1.5-flash'),
            apiKey: ApiService.apiKey,
          );
    }
  }

  // set current page index
  void setCurrentIndex({required int newIndex}) {
    _currentIndex = newIndex;
    notifyListeners();
  }

  // set current chat id
  void setCurrentChatId({required String newChatId}) {
    _currentChatId = newChatId;
    notifyListeners();
  }

  // set loading
  void setLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  // send message to gemini and get the streamed response
  Future<void> sentMessage({
    required String message,
    required bool isTextOnly,
  }) async {
    // set the model
    await setModel(isTextOnly: isTextOnly);

    // set loading
    setLoading(value: true);

    // get the chatId
    String chatId = getChatId();

    // list of history messages
    List<Content> history = [];

    // get chat history
    history = await getHistory(chatId: chatId);

    // get the imagesUrls
    List<String> imagesUrls = getImagesUrls(isTextOnly: isTextOnly);

    // user message id
    final userMessageId = const Uuid().v4();

    // user message
    final userMessage = Message(
      messageId: userMessageId,
      chatId: chatId,
      role: Role.user,
      message: StringBuffer(message),
      imagesUrls: imagesUrls,
      timeSent: DateTime.now(),
    );

    // add this message to the list on inChatMessages
    _inChatMessages.add(userMessage);
    notifyListeners();

    if (currentChatId.isEmpty) {
      setCurrentChatId(newChatId: chatId);
    }

    // send the message to the model and wait for the response
    await sendMessageAndWaitForResponse(
      message: message,
      chatId: chatId,
      isTextOnly: isTextOnly,
      history: history,
      userMessage: userMessage,
    );
  }

  // send the message to the model and wait for the response
  Future<void> sendMessageAndWaitForResponse({
    required String message,
    required String chatId,
    required bool isTextOnly,
    required List<Content> history,
    required Message userMessage,
  }) async {
    // start the chat session - only send history in it's text-only
    final chatSession = _model!.startChat(
      history: history.isEmpty || !isTextOnly ? null : history,
    );

    // get content
    final content = await getContent(
      message: message,
      isTextOnly: isTextOnly,
    );

    // assistant messageId
    final modelMessageId = const Uuid().v4();

    // assistant message
    final assistantMessage = userMessage.copyWith(
      messageId: modelMessageId,
      role: Role.assistant,
      message: StringBuffer(),
      timeSent: DateTime.now(),
    );

    // add this messages to the list on in ChatMessages
    _inChatMessages.add(assistantMessage);
    notifyListeners();

    // wait for stream response
    chatSession
        .sendMessageStream(content)
        .asyncMap((event) {
          return event;
        })
        .listen(
          (event) {
            _inChatMessages
                .firstWhere(
                  (element) =>
                      element.messageId == assistantMessage.messageId &&
                      element.role.name == Role.assistant.name,
                )
                .message
                .write(event.text);
            notifyListeners();
          },
          onDone: () {
            // save message to hive db

            // set loading to false
            setLoading(value: false);
          },
        )
        .onError((error, stackTrace) {
          // set loading
          log('Gemini Stream Error: $error');
          log('StackTrace: $stackTrace');
          setLoading(value: false);
        });
  }

  //
  Future<Content> getContent({
    required String message,
    required bool isTextOnly,
  }) async {
    if (isTextOnly) {
      // generate text from text-only input
      return Content.text(message);
    } else {
      // generate image from text and image input
      final imageFutures = _imagesFileList
          ?.map((imageFile) => imageFile.readAsBytes())
          .toList(growable: false);

      final imageBytes = await Future.wait(imageFutures!);

      final prompt = TextPart(message);
      // final imageParts =
      //     imageBytes
      //         .map((bytes) => DataPart('image/jpeg', Uint8List.fromList(bytes)))
      //         .toList();

      final imageParts = <DataPart>[];
      for (int i = 0; i < imageBytes.length; i++) {
        final mimeType = getMimeType(_imagesFileList![i]);
        imageParts.add(DataPart(mimeType, Uint8List.fromList(imageBytes[i])));
      }

      return Content.multi([prompt, ...imageParts]);
    }
  }

  String getMimeType(XFile file) {
    final ext = file.path.split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    return 'application/octet-stream'; // default fallback
  }


  // get the imagesUrls
  List<String> getImagesUrls({required bool isTextOnly}) {
    List<String> imagesUrls = [];
    if (!isTextOnly && imagesFileList != null) {
      for (var image in imagesFileList!) {
        imagesUrls.add(image.path);
      }
    }
    return imagesUrls;
  }

  // get chat history
  Future<List<Content>> getHistory({required String chatId}) async {
    List<Content> history = [];
    if (currentChatId.isNotEmpty) {
      await setInChatMessages(chatId: chatId);

      for (var message in inChatMessages) {
        if (message.imagesUrls.isNotEmpty) continue; //////----
        if (message.role == Role.user) {
          history.add(Content.text(message.message.toString()));
        } else {
          history.add(Content.model([TextPart(message.message.toString())]));
        }
      }
    }
    return history;
  }

  String getChatId() {
    if (currentChatId.isEmpty) {
      return const Uuid().v4();
    } else {
      return currentChatId;
    }
  }

  // init hive box
  static initHive() async {
    final dir = await path.getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    await Hive.initFlutter(Constants.geminiDB);

    // register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatHistoryAdapter());

      // open the chat history box
      await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
      await Hive.openBox<UserModel>(Constants.userBox);
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsAdapter());
      await Hive.openBox<Settings>(Constants.settingsBox);
    }
  }
}
