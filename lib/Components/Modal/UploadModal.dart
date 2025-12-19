import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '/Components/UI/BlurModal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_chatsen_irc/Twitch.dart' as twitch;

enum _UploadPickSource {
  camera,
  file,
}

class UploadModal extends StatefulWidget {
  // if (lowName.endsWith('.png') || lowName.endsWith('.jpg') || lowName.endsWith('.jpeg') || lowName.endsWith('.apng') || lowName.endsWith('.gif') || lowName.endsWith('.webp'))

  // Optional: set this to enable Imgur uploads.
  // Imgur requires an application Client ID (Authorization: Client-ID <id>).
  static const String imgurClientId = '';

  static const imgurExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'gif',
    'apng',
    'tiff',
    'mp4',
    'mpeg',
    'avi',
    'webm',
    // quicktime
    'mkv', // x-matroska
    'flv', // x-flv
    // x-msvideo
    // x-ms-wmv
  ];

  static const imageExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'gif',
    'apng',
    'tiff',
  ];

  static const videoExtensions = <String>[
    'mp4',
    'mpeg',
    'avi',
    'webm',
    // quicktime
    'mkv', // x-matroska
    'flv', // x-flv
    // x-msvideo
    // x-ms-wmv
  ];

  final Uint8List bytes;
  final String fileName;
  final twitch.Channel channel;
  final NavigatorState navigator;
  final ScaffoldMessengerState messenger;

  const UploadModal({
    Key? key,
    required this.bytes,
    required this.fileName,
    required this.channel,
    required this.navigator,
    required this.messenger,
  }) : super(key: key);

  @override
  State<UploadModal> createState() => _UploadModalState();

  static Future<void> show(
    BuildContext context, {
    required twitch.Channel channel,
  }) async {
    try {
      final isMobile = Platform.isIOS || Platform.isAndroid;

      _UploadPickSource source = _UploadPickSource.file;
      if (isMobile) {
        if (!context.mounted) return;
        final pickedSource = await showModalBottomSheet<_UploadPickSource>(
          context: context,
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Take photo'),
                    onTap: () => Navigator.of(context).pop(_UploadPickSource.camera),
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Choose file'),
                    onTap: () => Navigator.of(context).pop(_UploadPickSource.file),
                  ),
                ],
              ),
            );
          },
        );

        if (pickedSource == null) return;
        source = pickedSource;
      }

      late Uint8List pickedBytes;
      late String pickedName;

      if (isMobile && source == _UploadPickSource.camera) {
        final picker = ImagePicker();
        final photo = await picker.pickImage(source: ImageSource.camera);
        if (photo == null) return;
        pickedBytes = await photo.readAsBytes();
        final rawName = photo.name.isNotEmpty ? photo.name : photo.path.split('/').last;
        if (rawName.contains('.')) {
          pickedName = rawName;
        } else {
          final mime = photo.mimeType;
          final ext = (mime == 'image/png')
              ? 'png'
              : (mime == 'image/gif')
                  ? 'gif'
                  : (mime == 'image/webp')
                      ? 'webp'
                      : 'jpg';
          pickedName = 'photo.$ext';
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          withData: true,
          type: Platform.isIOS ? FileType.image : FileType.any,
        );

        if (result == null || result.files.isEmpty) return;

        final picked = result.files.single;
        final bytes = picked.bytes ?? (picked.path != null ? await File(picked.path!).readAsBytes() : null);
        if (bytes == null) return;
        pickedBytes = bytes;
        pickedName = picked.name;
      }

      if (!context.mounted) return;

      await BlurModal.show(
        context: context,
        child: UploadModal(
          bytes: pickedBytes,
          fileName: pickedName,
          channel: channel,
          navigator: Navigator.of(context),
          messenger: ScaffoldMessenger.of(context),
        ),
      );
      // ignore: empty_catches
    } catch (e) {
      print(e);
    }
  }
}

class _UploadModalState extends State<UploadModal> {
  bool _isUploading = false;
  String? _uploadingTo;

  void _closeThenSnack(String message) {
    widget.navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.messenger.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _runUpload(String target, Future<void> Function() action) async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _uploadingTo = target;
    });

    try {
      await action();
    } catch (e) {
      _closeThenSnack('Upload failed: $e');
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingTo = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var lowName = widget.fileName.toLowerCase();
    var extension = lowName.contains('.') ? lowName.split('.').last : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // mainAxisSize: MainAxisSize.max,
        // crossAxisAlignment: CrossAxisAlignment.start,
        // shrinkWrap: true,
        children: [
          Text(
            'You are about to upload ${widget.fileName} and share the link in ${widget.channel.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_isUploading) ...[
            SizedBox(height: 12.0),
            LinearProgressIndicator(),
            SizedBox(height: 8.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _uploadingTo != null ? 'Uploading to $_uploadingTo…' : 'Uploading…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          SizedBox(height: 16.0),
          if (UploadModal.imageExtensions.contains(extension)) ...[
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: Image.memory(widget.bytes),
            ),
            SizedBox(height: 16.0),
          ],
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (UploadModal.imgurExtensions.contains(extension)) ...[
                  ElevatedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            if (UploadModal.imgurClientId.isEmpty) {
                              _closeThenSnack('Imgur upload is not configured (missing Client-ID).');
                              return;
                            }

                            await _runUpload('imgur', () async {
                              var request = http.MultipartRequest('POST', Uri.parse('https://api.imgur.com/3/upload'));
                              request.headers['Authorization'] = 'Client-ID ${UploadModal.imgurClientId}';
                              request.files.add(
                                http.MultipartFile.fromBytes(
                                  'image',
                                  widget.bytes,
                                  filename: widget.fileName,
                                ),
                              );
                              var response = await request.send();
                              var responseBody = await response.stream.bytesToString();
                              var responseJson = jsonDecode(responseBody);
                              if (response.statusCode == 200) {
                                widget.channel.send(responseJson['data']['link']);
                                widget.navigator.pop();
                              } else {
                                _closeThenSnack('Imgur upload failed (${response.statusCode}).');
                              }
                              print('Upload: $responseBody');
                            });
                          },
                    label: Text('imgur'),
                    icon: Icon(Icons.upload),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.all(16.0)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0))),
                    ),
                  ),
                  SizedBox(width: 12.0),
                ],
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              await _runUpload('catbox.moe', () async {
                                var request = http.MultipartRequest('POST', Uri.parse('https://catbox.moe/user/api.php'));
                                request.files.add(
                                  http.MultipartFile.fromBytes(
                                    'fileToUpload',
                                    widget.bytes,
                                    filename: widget.fileName,
                                  ),
                                );
                                request.fields['reqtype'] = 'fileupload';
                                var response = await request.send();
                                var responseBody = await response.stream.bytesToString();
                                if (response.statusCode == 200) {
                                  widget.channel.send(responseBody);
                                  widget.navigator.pop();
                                } else {
                                  _closeThenSnack('catbox upload failed (${response.statusCode}).');
                                }
                                print('Upload: $responseBody');
                              });
                            },
                      label: Text('catbox.moe'),
                      icon: Icon(Icons.upload),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.all(16.0)),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0))),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.0),
                IconButton(
                  onPressed: _isUploading ? null : () async => Navigator.of(context).pop(),
                  // label: Text('Cancel'),
                  icon: Icon(Icons.cancel),
                  // style: ButtonStyle(
                  //   padding: MaterialStateProperty.all(EdgeInsets.all(16.0)),
                  //   shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0))),
                  // ),
                ),
                SizedBox(width: 12.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
