import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_engine/reading_engine.dart';
import 'package:mindflow/features/reader/presentation/providers/rsvp_controller.dart';

class ReaderControls extends ConsumerWidget {
  const ReaderControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RsvpEngineState state = ref.watch(rsvpControllerProvider);
    final controller = ref.read(rsvpControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10),
          onPressed: state.chunks.isEmpty ? null : () => controller.rewind(steps: 5),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          iconSize: 40,
          icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: state.chunks.isEmpty ? null : controller.togglePlayPause,
        ),
        const SizedBox(width: 12),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.forward_10),
          onPressed: state.chunks.isEmpty ? null : () => controller.forward(steps: 5),
        ),
      ],
    );
  }
}
