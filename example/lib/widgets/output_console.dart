import 'package:flutter/material.dart';

class OutputConsole extends StatelessWidget {
  final String output;

  const OutputConsole({
    super.key,
    required this.output,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Output Console',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              minHeight: 150,
              maxHeight: 250,
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: output.isEmpty
                  ? Text(
                      '⏳ Waiting for output...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    )
                  : SelectableText(
                      output,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

