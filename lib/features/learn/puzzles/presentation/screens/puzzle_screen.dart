// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:client/core/providers/locale_provider.dart';
// import '../cubits/puzzle_cubit.dart';
// import '../widgets/puzzle_board.dart';
// import '../widgets/puzzle_stats.dart';
// import '../widgets/puzzle_theme_selector.dart';
// import '../widgets/puzzle_action_buttons.dart';
//
// class PuzzleScreen extends StatefulWidget {
//   const PuzzleScreen({super.key});
//
//   @override
//   State<PuzzleScreen> createState() => _PuzzleScreenState();
// }
//
// class _PuzzleScreenState extends State<PuzzleScreen> {
//   @override
//   void initState() {
//     super.initState();
//     context.read<PuzzleCubit>().loadRandomPuzzle();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final locale = context.watch<LocaleProvider>();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(locale.get('puzzles_title')),
//         centerTitle: true,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: Row(
//               children: [
//                 const Icon(Icons.extension, size: 20),
//                 const SizedBox(width: 4),
//                 BlocBuilder<PuzzleCubit, PuzzleState>(
//                   builder: (context, state) {
//                     if (state is PuzzleLoaded) {
//                       return Text(
//                         '${state.puzzle.rating}',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       );
//                     }
//                     return Text(locale.get('puzzles_default_rating'));
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: BlocBuilder<PuzzleCubit, PuzzleState>(
//         builder: (context, state) {
//           if (state is PuzzleLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (state is PuzzleError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(state.message),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () => context.read<PuzzleCubit>().loadRandomPuzzle(),
//                     child: Text(locale.get('puzzles_next')),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           return Column(
//             children: [
//               // Statistics
//               BlocBuilder<PuzzleCubit, PuzzleState>(
//                 builder: (context, state) {
//                   if (state is PuzzleThemesLoaded) {
//                     return PuzzleStats(
//                       streak: state.streak,
//                       solvedToday: state.solvedToday,
//                       progress: state.progress,
//                     );
//                   }
//                   return const PuzzleStats();
//                 },
//               ),
//               const SizedBox(height: 16),
//
//               // Theme selector
//               BlocBuilder<PuzzleCubit, PuzzleState>(
//                 builder: (context, state) {
//                   if (state is PuzzleThemesLoaded) {
//                     return PuzzleThemeSelector(
//                       themes: state.themes,
//                       selectedTheme: 'all',
//                       onThemeSelected: (theme) {
//                         context.read<PuzzleCubit>().selectTheme(theme);
//                       },
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 },
//               ),
//               const SizedBox(height: 16),
//
//               // Puzzle board
//               Expanded(
//                 child: state is PuzzleLoaded || state is PuzzleSolved || state is PuzzleFailed
//                   ? PuzzleBoard(
//                       puzzle: state is PuzzleLoaded
//                           ? state.puzzle
//                           : state is PuzzleSolved
//                               ? state.puzzle
//                               : (state as PuzzleFailed).puzzle,
//                       userMoves: state is PuzzleLoaded
//                           ? state.userMoves
//                           : state is PuzzleSolved
//                               ? state.userMoves
//                               : (state as PuzzleFailed).userMoves,
//                       onMoveMade: (move) {
//                         context.read<PuzzleCubit>().makeMove(move);
//                       },
//                     )
//                   : const SizedBox.shrink(),
//             ),
//
//               // Action buttons
//               const PuzzleActionButtons(),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
