class IRCMessage {
  String raw;
  Map<String, dynamic> tags;
  String prefix;
  String command;
  List<String> parameters;

  IRCMessage({
    this.raw = '',
    this.tags = const {},
    this.prefix = '',
    this.command = '',
    this.parameters = const [],
  });

  /// Unescapes IRCv3 tag values.
  ///
  /// Twitch (and IRCv3 in general) escapes some characters in tag values:
  /// - \s => space
  /// - \: => ;
  /// - \r => carriage return
  /// - \n => newline
  /// - \\ => \
  static String unescapeTagValue(String value) {
    if (value.isEmpty) return value;

    final out = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final ch = value[i];
      if (ch != '\\') {
        out.write(ch);
        continue;
      }

      if (i + 1 >= value.length) {
        out.write(r'\\');
        continue;
      }

      final next = value[i + 1];
      switch (next) {
        case ':':
          out.write(';');
          break;
        case 's':
          out.write(' ');
          break;
        case 'r':
          out.write('\r');
          break;
        case 'n':
          out.write('\n');
          break;
        case '\\':
          out.write('\\');
          break;
        default:
          out.write(next);
          break;
      }
      i++; // consumed escape code
    }

    return out.toString();
  }

  static IRCMessage? fromData(message) {
    if (message.length <= 0) return null;

    var ircMessage = IRCMessage(
      raw: message,
    );

    if (message[0] == '@') {
      List<String> messageSplit = message.substring(1).split(' ');
      if (messageSplit.length <= 1) return null;
      messageSplit[1] = messageSplit.sublist(1).join(' ').trim();
      var tags = messageSplit[0].split(';');
      final parsedTags = <String, dynamic>{};
      for (final tag in tags) {
        if (tag.isEmpty) continue;
        final idx = tag.indexOf('=');
        final key = idx == -1 ? tag : tag.substring(0, idx);
        final rawValue = idx == -1 ? '' : tag.substring(idx + 1);
        parsedTags[key] = IRCMessage.unescapeTagValue(rawValue);
      }
      ircMessage.tags = parsedTags;
      message = messageSplit[1];
    }

    if (message[0] == ':') {
      List<String> messageSplit = message.substring(1).split(' ');
      if (messageSplit.length <= 1) return null;
      messageSplit[1] = messageSplit.sublist(1).join(' ').trim();
      ircMessage.prefix = messageSplit[0];
      message = messageSplit[1];
    }

    List<String> messageSplit = message.split(' ');
    if (messageSplit.length > 1)
      messageSplit[1] = messageSplit.sublist(1).join(' ').trim();
    ircMessage.command = messageSplit[0];
    message = (messageSplit.length <= 1) ? null : messageSplit[1];

    if (message == null) return ircMessage;

    List<String> parametersSplit = message.split(':');
    ircMessage.parameters = parametersSplit[0].trim().split(' ');
    if (parametersSplit.length > 1)
      ircMessage.parameters.add(parametersSplit.sublist(1).join(':').trim());

    return ircMessage;
  }
}
