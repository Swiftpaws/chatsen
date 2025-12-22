import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chatsen_irc/Twitch.dart' as twitch;

/// [HomeTab] is a widget that represents a channel as a simple tab.
class HomeTab extends StatelessWidget {
  final twitch.Client? client;
  final twitch.Channel channel;
  final Function refresh;

  const HomeTab({
    Key? key,
    required this.client,
    required this.channel,
    required this.refresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Tab(
        child: GestureDetector(
          onLongPress: () async {
            channel.messages.clear();
            refresh();
            await channel.loadHistory();
          },
          child: Text('${channel.name!.replaceFirst('#', '')}'),
        ),
      );
}
