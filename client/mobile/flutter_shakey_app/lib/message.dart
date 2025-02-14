import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';

class Message {
  final bool isUser;
  final String message;
  final DateTime date;
  final bool showGif;

  Message({
    required this.isUser,
    required this.message,
    required this.date,
    this.showGif = false,
  });
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;
  final bool showGif;
  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
    this.showGif = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 15)
          .copyWith(left: isUser ? 100 : 10, right: isUser ? 10 : 100),
      decoration: BoxDecoration(
        color: showGif
            ? Colors.transparent
            : (isUser ? Colors.blueAccent : Colors.grey.shade400),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: isUser ? Radius.circular(10) : Radius.zero,
            topRight: Radius.circular(10),
            bottomRight: isUser ? Radius.zero : Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          showGif
              ? GifView.asset(
                  'assets/images/botGif.gif',
                  fit: BoxFit.fill,
                )
              : Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
          Text(
            date,
            style: TextStyle(color: Colors.white, fontSize: 16),
          )
        ],
      ),
    );
  }
}
