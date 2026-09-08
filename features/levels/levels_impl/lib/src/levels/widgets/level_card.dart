import 'package:app_localization/app_localization.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import '../../shared/cefr_level_l10n.dart';
import '../levels_controller.dart';

/// One selectable level.
class const LevelCard({
  required final LevelEntry entry,
  required final VoidCallback onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final best = entry.best;

    // One announcement for the whole row — the code, the name and the score
    // read as a sentence, rather than as three unrelated fragments a player
    // has to swipe through.
    return Semantics(
      button: true,
      label:
          '${entry.level.label}, ${entry.level.description(context)}, '
          '${_bestLabel(context)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(context.spacing.spacingLg),
          decoration: BoxDecoration(
            color: context.backgroundColors.bgSecondary,
            borderRadius: BorderRadius.circular(context.radii.radiusLg),
            border: Border.all(color: context.borderColors.borderSecondary),
          ),
          child: Row(
            children: [
              // The CEFR code is the identity of the row, so it leads.
              //
              // A *minimum* width rather than a fixed one: every code is two
              // characters, so their natural widths already line up, and a hard
              // width wraps "A1" onto two lines once the user's text scale is
              // above 1.0.
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: context.sizes.size40),
                child: AppText(
                  title: entry.level.label,
                  maxLines: 1,
                  style: context.typography.displaySm.bold.copyWith(
                    color: context.textColors.textBrand,
                  ),
                ),
              ),
              context.spacing.spacingMd.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title: entry.level.description(context),
                      style: context.typography.textLg.medium.copyWith(
                        color: context.textColors.textPrimary,
                      ),
                    ),
                    context.spacing.spacingXxs.verticalSpace,
                    AppText(
                      title: best == null
                          ? context.localization.levelNotPlayed
                          : context.localization.levelBest(
                              best.correct,
                              best.total,
                            ),
                      style: context.typography.textSm.regular.copyWith(
                        color: best == null
                            ? context.textColors.textTertiary
                            : context.textColors.textSecondary,
                      ),
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

  /// The score line, as words rather than a fraction.
  String _bestLabel(BuildContext context) {
    final best = entry.best;
    return best == null
        ? context.localization.levelNotPlayed
        : context.localization.scoreSummary(best.correct, best.total);
  }
}
