// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:client/core/providers/locale_provider.dart';
// import '../cubits/puzzle_cubit.dart';
//
// class PuzzleActionButtons extends StatelessWidget {
//   const PuzzleActionButtons({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final locale = context.watch<LocaleProvider>();
//
//     return BlocBuilder<PuzzleCubit, PuzzleState>(
//       builder: (context, state) {
//         return Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               if (state is PuzzleFailed)
//                 ElevatedButton.icon(
//                   onPressed: () => context.read<PuzzleCubit>().resetPuzzle(),
//                   icon: const Icon(Icons.refresh),
//                   label: Text(locale.get('puzzles_try_again')),
//                 ),
//               if (state is PuzzleSolved)
//                 ElevatedButton.icon(
//                   onPressed: () => context.read<PuzzleCubit>().loadRandomPuzzle(),
//                   icon: const Icon(Icons.skip_next),
//                   label: Text(locale.get('puzzles_next')),
//                 ),
//               OutlinedButton.icon(
//                 onPressed: () => context.read<PuzzleCubit>().skipPuzzle(),
//                 icon: const Icon(Icons.skip_next),
//                 label: Text(locale.get('puzzles_next')),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
