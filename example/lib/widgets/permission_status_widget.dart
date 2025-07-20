import 'package:flutter/material.dart';

class PermissionStatusWidget extends StatelessWidget {
  final bool hasCameraPermission;
  final VoidCallback onRequestPermission;

  const PermissionStatusWidget({
    super.key,
    required this.hasCameraPermission,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: hasCameraPermission ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              hasCameraPermission ? Icons.check_circle : Icons.cancel,
              color: hasCameraPermission ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera Permission',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    hasCameraPermission ? 'Granted' : 'Required for camera features',
                    style: TextStyle(
                      color: hasCameraPermission ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasCameraPermission)
              ElevatedButton(
                onPressed: onRequestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Request'),
              ),
          ],
        ),
      ),
    );
  }
}