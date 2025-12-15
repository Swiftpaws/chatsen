import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImageW extends StatelessWidget {
  final String url;
  final double? scale;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool cache;

  const NetworkImageW(
    this.url, {
    Key? key,
    this.scale,
    this.width,
    this.height,
    this.fit,
    this.cache = true,
  }) : super(key: key);

  bool get _isGif {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url.split(RegExp(r'[?#]')).first).toLowerCase();
    return path.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) => Image(
        // url,
        image: CachedNetworkImageProvider(
          url,
          scale: scale ?? 1.0,
          cacheKey: cache
              ? null
              : '$url:${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
        ),
        filterQuality: _isGif ? FilterQuality.none : FilterQuality.low,
        width: width,
        height: height,
        fit: fit,
        // loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        //   if (loadingProgress == null) {
        //     return child;
        //   }
        //   return Center(
        //     child: CircularProgressIndicator.adaptive(
        //       value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
        //     ),
        //   );
        // },
        // isAntiAlias: true,
      );
}

// placeholderFadeInDuration: Duration(microseconds: 0),
// fadeInDuration: Duration(microseconds: 0),
// fadeOutDuration: Duration(microseconds: 0),
// placeholder: (context, url) => Container(),
