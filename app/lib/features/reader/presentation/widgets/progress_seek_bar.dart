import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_engine/reading_engine.dart';
import 'package:mindflow/features/reader/presentation/providers/rsvp_controller.dart';

class ProgressSeekBar extends ConsumerWidget {
  const ProgressSeekBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RsvpEngineState state = ref.watch(rsvpControllerProvider);
    final controller = ref.read(rsvpControllerProvider.notifier);

    return Column(
      children: [
        Slider(
          value: state.progress.clamp(0.0, 1.0),
          onChanged: state.chunks.isEmpty ? null : (v) => controller.seekToFraction(v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${state.currentIndex + 1} / ${state.chunks.isEmpty ? 0 : state.chunks.length}'),
              Text('${(state.progress * 100).round()}%'),
            ],
          ),
        ),
      ],
    );
  }
}
