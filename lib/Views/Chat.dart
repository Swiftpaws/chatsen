import 'dart:io';
import 'dart:async';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '/BlockedUsers/BlockedUsersCubit.dart';
import '/Settings/Settings.dart';
import '/Settings/SettingsState.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/Components/ChatInputBox.dart';
import '/Components/ChatMessage.dart';
import 'package:flutter_chatsen_irc/Twitch.dart' as twitch;
import '/Components/UI/WidgetBlur.dart';
import '/StreamOverlay/StreamOverlayBloc.dart';
import '/StreamOverlay/StreamOverlayState.dart';

/// The [ChatView] widget is a view that renders the messages associated to a channel with regards to the given client.
class ChatView extends StatefulWidget {
  final twitch.Client? client;
  final twitch.Channel? channel;
  final bool shadow;
  // final Function(String)? addText;

  const ChatView({
    Key? key,
    required this.client,
    required this.channel,
    this.shadow = false,
    // this.addText,
  }) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> implements twitch.Listener {
  var gkey = GlobalKey<ChatInputBoxState>();
  bool shouldScroll = true;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  void scrollToEnd() {
    if (itemScrollController.isAttached) {
      itemScrollController.jumpTo(index: 0);
    }
  }

  @override
  void initState() {
    widget.client?.listeners.add(this);
    itemPositionsListener.itemPositions.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    itemPositionsListener.itemPositions.removeListener(_scrollListener);
    widget.client?.listeners.remove(this);
    super.dispose();
  }

  void _scrollListener() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final isAtBottom = positions.any((element) => element.index == 0);

      if (isAtBottom != shouldScroll) {
        setState(() {
          shouldScroll = isAtBottom;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: BlocBuilder<Settings, SettingsState>(
            builder: (context, state) {
              var blockedUsers = List<String>.from(
                      BlocProvider.of<BlockedUsersCubit>(context).state)
                  .map((element) => element.toLowerCase())
                  .toList();
              var messages = widget.channel!.messages
                  .where((element) => !blockedUsers
                      .contains(element.user?.login?.toLowerCase()))
                  .toList()
                  .reversed
                  .toList();

              return ScrollablePositionedList.builder(
                reverse: true,
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                padding: MediaQuery.of(context).padding +
                    (Platform.isMacOS
                        ? EdgeInsets.only(top: 26.0)
                        : EdgeInsets.zero) +
                    EdgeInsets.only(
                        bottom: (kDebugMode ||
                                    widget.channel?.transmitter?.credentials
                                            ?.token !=
                                        null
                                ? (36.0 + 4.0)
                                : 0.0) +
                            8.0,
                        top: 8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state is SettingsLoaded && state.messageLines)
                        Container(
                          color: Theme.of(context).dividerColor,
                          height: 1.0,
                        ),
                      ChatMessage(
                        key: ObjectKey(message),
                        backgroundColor: state is SettingsLoaded &&
                                state.messageAlternateBackground &&
                                ((messages.length - 1 - index) % 2 == 0)
                            ? Theme.of(context).dividerColor
                            : null,
                        message: message,
                        shadow: widget.shadow,
                        gkey: gkey,
                        highlight: message.id == _highlightedMessageId,
                        onReplyClick: (replyId) {
                          final targetIndex =
                              messages.indexWhere((m) => m.id == replyId);
                          if (targetIndex != -1) {
                            itemScrollController.scrollTo(
                              index: targetIndex,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: 0.5,
                            );
                            setState(() {
                              _highlightedMessageId = replyId;
                            });
                            _highlightTimer?.cancel();
                            _highlightTimer =
                                Timer(Duration(milliseconds: 1000), () {
                              if (mounted) {
                                setState(() {
                                  _highlightedMessageId = null;
                                });
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Original message not found in loaded history.')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        if ((Platform.isMacOS ? 0.0 : MediaQuery.of(context).padding.top) > 0.0 && (MediaQuery.of(context).size.aspectRatio > 1.0 ? true : BlocProvider.of<StreamOverlayBloc>(context).state is StreamOverlayClosed))
          WidgetBlur(
            child: Material(
              color: Theme.of(context).canvasColor.withAlpha(196),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    // height: Platform.isMacOS ? 26.0 : MediaQuery.of(context).padding.top,
                    height: MediaQuery.of(context).padding.top,
                  ),
                  Container(
                    color: Theme.of(context).dividerColor,
                    height: 1.0,
                  ),
                ],
              ),
            ),
          ),
        if (widget.channel?.historyLoading ?? false)
          Center(child: CircularProgressIndicator()),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!shouldScroll)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: WidgetBlur(
                    borderRadius: BorderRadius.circular(32.0),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface.withAlpha(196),
                      child: Container(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor.withAlpha(16),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: InkWell(
                          onTap: () async => scrollToEnd(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.primary),
                                SizedBox(width: 8.0),
                                Text(
                                  'Resume scrolling',
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // icon:
                      // onPressed: () async => scrollToEnd(), child: null,
                    ),
                  ),
                ),
              WidgetBlur(
                child: Material(
                  color: Theme.of(context).colorScheme.surface.withAlpha(196),
                  child: ChatInputBox(
                    key: gkey,
                    client: widget.client,
                    channel: widget.channel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void onChannelStateChange(twitch.Channel channel, twitch.ChannelState state) {
    if (channel != widget.channel) return;
    setState(() {});
  }

  @override
  void onConnectionStateChange(twitch.Connection connection, twitch.ConnectionState state) {}

  @override
  void onMessage(twitch.Channel? channel, twitch.Message message) {
    if (channel != widget.channel || !shouldScroll) return;
    setState(() {});
  }

  @override
  void onHistoryLoading(twitch.Channel channel) {
    if (channel != widget.channel) return;
    setState(() {});
  }

  @override
  void onHistoryLoaded(twitch.Channel channel) {
    if (channel != widget.channel || !shouldScroll) return;
    setState(() {});
  }

  @override
  void onWhisper(twitch.Channel channel, twitch.Message message) {
    if (channel != widget.channel || !shouldScroll) return;
    setState(() {});
  }
}




            // if (scrollNotification is ScrollStartNotification) {
            //   scrollPosition = scrollController.position.pixels;
            // } else if (scrollNotification is ScrollUpdateNotification) {
            //   if (scrollController.position.pixels < scrollPosition && shouldScroll != false) {
            //     shouldScroll = false;
            //     setState(() {});
            //   }
            //   scrollPosition = scrollController.position.pixels;
            // } else if (scrollNotification is ScrollEndNotification) {
            //   if (scrollController.position.pixels >= scrollController.position.maxScrollExtent && shouldScroll != true) {
            //     shouldScroll = true;
            //     setState(() {});
            //   }
            //   scrollPosition = null;
            // }

            /*
if (shouldScroll) {
      // SchedulerBinding.instance.addPostFrameCallback((_) {
      //   if (scrollController.position != null && shouldScroll) {
      //     scrollController.jumpTo(
      //       scrollController.position.maxScrollExtent,
      //       // curve: Curves.linear,
      //       // duration: const Duration(milliseconds: 250),
      //     );
      //   }
      // });
      // scrollController.jumpTo(
      // -10, //scrollController.position.minScrollExtent,
      // curve: Curves.linear,
      // duration: const Duration(milliseconds: 250),
      // );
    }
            */
