import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '/Components/UI/WidgetBlur.dart';

class LoadingOverlay extends StatelessWidget {
  final String status;

  const LoadingOverlay({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: SizedBox(
          width: 150,
          height: 150,
          child: WidgetBlur(
            blur: 20.0,
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(radius: 16.0),
                  const SizedBox(height: 16.0),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
