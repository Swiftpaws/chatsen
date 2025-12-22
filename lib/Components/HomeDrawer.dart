import 'dart:io';

import '/BackgroundAudio/BackgroundAudioWrapper.dart';
import '/BackgroundDaemon/BackgroundDaemonCubit.dart';
import '/Pages/Settings.dart';
import '/Theme/ThemeManager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Consts.dart';
import '/Components/UI/WidgetBlur.dart';
import '/Pages/Account.dart';
import '/Pages/Search.dart';
import '/Pages/Whispers.dart';
import '/StreamOverlay/StreamOverlayBloc.dart';
import '/StreamOverlay/StreamOverlayEvent.dart';
import '/StreamOverlay/StreamOverlayState.dart';
import '/Views/Userlist.dart';
import 'package:flutter_chatsen_irc/Twitch.dart' as twitch;
import 'package:hive/hive.dart';

/// The [HomeDrawer] widget represents the drawer available on the home page. It features our [UserlistView] which displays all the users currently in a channel as well as giving us the way to access multiple options, accounts and features.
class HomeDrawer extends StatelessWidget {
  final twitch.Client? client;
  final twitch.Channel? channel;
  final VoidCallback? onChannelClose;

  const HomeDrawer({
    Key? key,
    required this.client,
    required this.channel,
    this.onChannelClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => WidgetBlur(
        child: Material(
          color: Theme.of(context).canvasColor.withAlpha(196),
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: channel != null
                          ? UserlistView(
                              channel: channel,
                            )
                          : ListView(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 8.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (channel != null)
                              IconButton(
                                icon: Icon((Platform.isMacOS || Platform.isIOS) ? CupertinoIcons.play_fill : Icons.play_arrow),
                                onPressed: () async {
                                  if (!kPlayStoreRelease) {
                                    var bgDaemon = BlocProvider.of<BackgroundDaemonCubit>(context);
                                    var toggle = BlocProvider.of<StreamOverlayBloc>(context).state is StreamOverlayClosed;
                                    (BlocProvider.of<StreamOverlayBloc>(context).state is StreamOverlayClosed) ? BlocProvider.of<StreamOverlayBloc>(context).add(StreamOverlayOpen(channelName: channel!.name!.substring(1))) : BlocProvider.of<StreamOverlayBloc>(context).add(StreamOVerlayClose());
                                    await Future.delayed(Duration(seconds: 2));
                                    if (toggle) {
                                      await bgDaemon.pause();
                                    } else {
                                      await bgDaemon.play();
                                    }
                                  } else {
                                    (BlocProvider.of<StreamOverlayBloc>(context).state is StreamOverlayClosed) ? BlocProvider.of<StreamOverlayBloc>(context).add(StreamOverlayOpen(channelName: channel!.name!.substring(1))) : BlocProvider.of<StreamOverlayBloc>(context).add(StreamOVerlayClose());
                                  }
                                }, //launch('https://twitch.tv/${channel.name.substring(1)}'),
                                tooltip: 'Open current channel\'s stream',
                              ),
                            if (channel != null)
                              IconButton(
                                icon: Icon((Platform.isMacOS || Platform.isIOS) ? CupertinoIcons.search : Icons.search),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (BuildContext context) => SearchPage(
                                      channel: channel,
                                    ),
                                  ),
                                ),
                                tooltip: 'Search in the current channel',
                              ),
                            if (channel != null)
                              IconButton(
                                icon: Icon((Platform.isMacOS || Platform.isIOS) ? CupertinoIcons.xmark : Icons.close),
                                onPressed: () async {
                                  var confirm = await (Platform.isIOS || Platform.isMacOS
                                      ? showCupertinoDialog<bool>(
                                          context: context,
                                          builder: (context) => CupertinoAlertDialog(
                                            title: Text('Close channel?'),
                                            content: Text('Are you sure you want to close ${channel!.name}?'),
                                            actions: [
                                              CupertinoDialogAction(
                                                child: Text('Cancel'),
                                                onPressed: () => Navigator.of(context).pop(false),
                                              ),
                                              CupertinoDialogAction(
                                                isDestructiveAction: true,
                                                child: Text('Close'),
                                                onPressed: () => Navigator.of(context).pop(true),
                                              ),
                                            ],
                                          ),
                                        )
                                      : showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Close channel?'),
                                            content: Text('Are you sure you want to close ${channel!.name}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: Text('Close'),
                                              ),
                                            ],
                                          ),
                                        ));

                                  if (confirm == true) {
                                    client!.partChannels([channel!]);
                                    var channelsBox = await Hive.openBox('Channels');
                                    await channelsBox.clear();
                                    await channelsBox.addAll(client!.channels.map((channel) => channel.name));
                                    if (onChannelClose != null) onChannelClose!();
                                  }
                                },
                                tooltip: 'Close current channel',
                              ),
                            if (channel != null)
                              Container(
                                width: 1.0,
                                height: 24.0,
                                color: Theme.of(context).dividerColor,
                              ),
                            IconButton(
                              icon: Icon((Platform.isMacOS || Platform.isIOS) ? CupertinoIcons.envelope_fill : Icons.inbox),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) => WhispersPage(
                                    client: client,
                                  ),
                                ),
                              ),
                              tooltip: 'Open whispers',
                            ),
                            IconButton(
                              icon: Icon((Platform.isMacOS || Platform.isIOS) ? CupertinoIcons.person_crop_circle_fill_badge_plus : Icons.switch_account),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) => AccountPage(
                                    client: client!,
                                  ),
                                ),
                              ),
                              tooltip: 'Add or switch between your accounts',
                            ),
                            // IconButton(
                            //   icon: Icon(Icons.account_circle),
                            //   onPressed: () => Navigator.of(context).push(
                            //     MaterialPageRoute(
                            //       builder: (BuildContext context) => ProfilePage(),
                            //     ),
                            //   ),
                            //   tooltip: 'Get your profile information',
                            // ),
                            IconButton(
                              icon: Icon((Platform.isMacOS || Platform.isIOS) ? CupertinoIcons.gear_alt_fill : Icons.settings),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) => ThemeManager.routeWrapper(
                                    context: context,
                                    child: SettingsPage(
                                      client: client!,
                                    ),
                                  ),
                                ),
                              ),
                              tooltip: 'Opens the settings page',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 4.0,
                      height: 64.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(128),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  Container(
                    width: 1.0,
                    color: Theme.of(context).dividerColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
