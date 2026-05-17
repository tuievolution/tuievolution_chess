import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../widgets/grow_card.dart';
import '../widgets/grow_badge.dart';
import '../widgets/grow_progress_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar & Info
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha:0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surface(context),
                    child: Icon(Icons.person, size: 60, color: AppColors.textSecondary(context)),
                  ),
                ),
                GrowBadge(text: 'PRO', backgroundColor: AppColors.primary, textColor: AppColors.bg(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Magnus Forest',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'MASTER CULTIVATOR',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
            
            const SizedBox(height: 32),
            
            // Stats Grid
            GrowCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PUZZLES SOLVED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context))),
                      const SizedBox(height: 8),
                      Text('1,428', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: AppColors.primary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grass, color: AppColors.primary, size: 32),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GrowCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book, color: AppColors.textSecondary(context), size: 16),
                            const SizedBox(width: 8),
                            Text('OPENINGS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('42', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
                        const SizedBox(height: 12),
                        const GrowProgressBar(progress: 0.6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GrowCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: AppColors.textSecondary(context), size: 16),
                            const SizedBox(width: 8),
                            Text('RATING', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('2480', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
                        const SizedBox(height: 12),
                        Text('↑ +12 this week', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Recent Growth
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Growth', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () {},
                  child: Text('View All', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTimelineItem(
              context: context,
              badge: 'MASTERED',
              time: '2h ago',
              title: 'Sicilian Defense',
              desc: 'Completed all 12 theory branches with 98% recall accuracy.',
              rewardText: '+500 Growth XP',
              rewardIcon: Icons.eco,
              isFirst: true,
            ),
            _buildTimelineItem(
              context: context,
              badge: 'MILESTONE',
              time: 'Yesterday',
              title: '1,000 Puzzles Streak',
              desc: 'Maintained a puzzle daily streak for 30 consecutive days.',
              rewardText: 'Persistence Badge',
              rewardIcon: Icons.shield,
              badgeColor: AppColors.border(context),
            ),
            _buildTimelineItem(
              context: context,
              badge: '',
              time: '',
              title: 'Italian Game Seeds',
              desc: 'Planted new study nodes for Giuoco Piano variations.',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required String badge,
    required String time,
    required String title,
    required String desc,
    String? rewardText,
    IconData? rewardIcon,
    Color badgeColor = AppColors.primaryDark,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line & dot
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : (isFirst ? AppColors.primary : AppColors.primaryDark),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isFirst ? AppColors.primary : AppColors.textSecondary(context), width: 2),
                    color: AppColors.bg(context),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : (isFirst ? AppColors.primary : AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GrowCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GrowBadge(text: badge, backgroundColor: badgeColor, textColor: badgeColor == AppColors.primaryDark ? AppColors.primary : AppColors.textSecondary(context)),
                          Text(time, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(desc, style: Theme.of(context).textTheme.bodyMedium),
                    if (rewardText != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(rewardIcon, size: 16, color: badgeColor == AppColors.primaryDark ? AppColors.primary : AppColors.textSecondary(context)),
                          const SizedBox(width: 8),
                          Text(
                            rewardText,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: badgeColor == AppColors.primaryDark ? AppColors.primary : AppColors.textPrimary(context),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
