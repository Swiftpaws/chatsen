import '/Components/UI/BlurModal.dart';
import 'package:flutter/material.dart';

class ChannelCloseModal extends StatefulWidget {
  final String name;
  final Function onLeave;

  const ChannelCloseModal({
    Key? key,
    required this.name,
    required this.onLeave,
  }) : super(key: key);

  @override
  State<ChannelCloseModal> createState() => _ChannelCloseModalState();

  static Future<void> show(
    BuildContext context, {
    required String name,
    required Function onLeave,
  }) async {
    await BlurModal.show(
      context: context,
      child: ChannelCloseModal(
        name: name,
        onLeave: onLeave,
      ),
    );
  }
}

class _ChannelCloseModalState extends State<ChannelCloseModal> {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Are you sure that you want to close channel ${widget.name}?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8.0),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onLeave();
                },
                icon: Icon(Icons.close),
                label: Text('Leave channel'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.redAccent),
                  padding: MaterialStateProperty.all(EdgeInsets.all(16.0)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0))),
                ),
              ),
              SizedBox(height: 8.0),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                // // icon: Icon(Icons.close),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(EdgeInsets.all(16.0)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0))),
                ),
                child: Text('Abort'),
              ),
            ],
          ),
        ),
      );
}
