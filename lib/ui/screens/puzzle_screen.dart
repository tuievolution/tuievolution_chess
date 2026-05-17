import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../widgets/grow_button.dart';
import '../widgets/grow_card.dart';
import '../widgets/grow_progress_bar.dart';
import '../components/chessboard_fixed.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Puzzle #4,821', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) => const Icon(Icons.star, size: 16, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          Text('ADVANCED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context))),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryDark),
                    ),
                    child: Column(
                      children: [
                        Text('+15', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                        Text('LEAVES', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context))),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              // Chessboard
              // Provide a dummy FEN for the puzzle (this is just an example FEN)
              const ChessboardFixed(startingFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GrowButton(
                      text: 'Hint',
                      icon: Icons.lightbulb_outline,
                      type: GrowButtonType.secondary,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GrowButton(
                      text: 'Next Move',
                      icon: Icons.play_arrow,
                      type: GrowButtonType.primary,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Session History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Session History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                  Text('Today', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 16),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildHistoryPill(true, '#4820'),
                    _buildHistoryPill(true, '#4819'),
                    _buildHistoryPill(false, '#4818'),
                    _buildHistoryPill(true, '#4817'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Daily Growth Target
              GrowCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Daily Growth Target', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                          ],
                        ),
                        Text('75%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const GrowProgressBar(progress: 0.75),
                    const SizedBox(height: 16),
                    Text(
                      '"Nurture your tactical vision. 15 more leaves to sprout a new rank."',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryPill(bool isSuccess, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSuccess ? AppColors.primaryDark : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.primary : Colors.red[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              size: 12,
              color: AppColors.bg(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
