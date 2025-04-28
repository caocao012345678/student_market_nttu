import 'package:flutter/material.dart';
import '../screens/chatbot_screen.dart';

class ChatbotButton extends StatelessWidget {
  const ChatbotButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, ChatbotScreen.routeName);
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.chat, color: Colors.white),
      tooltip: 'Trợ lý ảo',
    );
  }
} 