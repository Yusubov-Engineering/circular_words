import 'package:app_localization/app_localization.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:rosco_api/rosco_api.dart';

import '../../shared/cefr_level_l10n.dart';
import '../levels_controller.dart';

/// One selectable level, in that level's colour.
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
    //
    // The scope tints everything inside with this level's hue — the same hue
    // the round is played in, so the choice visibly carries into the game.
    return AppAccentScope(
      accent: entry.level.accent,
      child: Builder(
        builder: (context) {
          final accent = context.accentColors;

          return AppCard(
            onTap: onTap,
            semanticsLabel:
                '${entry.level.label}, ${entry.level.description(context)}, '
                '${_bestLabel(context)}',
            child: Row(
              children: [
                // The CEFR code is the identity of the row, so it leads, on a
                // badge in the level's colour.
                //
                // A *minimum* size rather than a fixed one: a hard size wraps
                // "A1" onto two lines once the user's text scale is above 1.0.
                Container(
                  constraints: BoxConstraints(
                    minWidth: context.sizes.size40 + context.spacing.spacingLg,
                    minHeight: context.sizes.size40 + context.spacing.spacingLg,
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(context.spacing.spacingXs),
                  decoration: BoxDecoration(
                    color: accent.accentSoft,
                    borderRadius: BorderRadius.circular(context.radii.radiusLg),
                    border: Border.all(color: accent.accentSoftBorder),
                  ),
                  child: AppText(
                    title: entry.level.label,
                    maxLines: 1,
                    style: context.typography.textLg.bold.copyWith(
                      color: accent.accentText,
                    ),
                  ),
                ),
                context.spacing.spacingLg.horizontalSpace,
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
                context.spacing.spacingMd.horizontalSpace,
                _Chevron(color: accent.accentText),
              ],
            ),
          );
        },
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

/// A small "go" mark, so the row reads as something that leads somewhere.
class const _Chevron({required final Color color}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: context.sizes.size16,
    child: CustomPaint(painter: _ChevronPainter(color: color)),
  );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.35, size.height * 0.2)
        ..lineTo(size.width * 0.7, size.height * 0.5)
        ..lineTo(size.width * 0.35, size.height * 0.8),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
