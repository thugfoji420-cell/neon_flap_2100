import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/game/pipe_gap_planner.dart';
import 'package:neon_flap1_game/models/difficulty_config.dart';

void main() {
  group('PipeGapPlanner', () {
    const minCenter = 190.0;
    const maxCenter = 470.0;
    const midpoint = (minCenter + maxCenter) / 2;

    for (final mode in DifficultyMode.values) {
      test('${mode.name} generates 50 bounded randomized fair gaps', () {
        final config = DifficultyConfig.preset(mode);
        final planner = PipeGapPlanner(random: Random(42));
        double? previous;
        final bands = <int>{};
        var sameSideTransitions = 0;

        for (var index = 0; index < 50; index++) {
          final center = planner.nextCenter(
            minCenter: minCenter,
            maxCenter: maxCenter,
            score: index * 5,
            config: config,
          );

          expect(center, inInclusiveRange(minCenter, maxCenter));
          if (index == 0) {
            expect(center, midpoint);
          } else {
            final last = previous ?? midpoint;
            expect(
              center - last,
              inInclusiveRange(
                -config.maxVerticalGapChange,
                config.maxVerticalGapChange,
              ),
            );
            bands.add(
                ((center - minCenter) / (maxCenter - minCenter) * 7).floor());
            if ((center - midpoint) * (last - midpoint) > 0) {
              sameSideTransitions++;
            }
          }
          previous = center;
        }

        expect(bands.length, greaterThan(3));
        // Random generation is explicitly allowed to keep the same side;
        // this assertion protects against accidentally reintroducing zig-zag.
        expect(sameSideTransitions, greaterThan(0));
      });

      test('${mode.name} reset restores its friendly first opening', () {
        final planner = PipeGapPlanner(random: Random(7));
        final config = DifficultyConfig.preset(mode);
        planner.nextCenter(
          minCenter: minCenter,
          maxCenter: maxCenter,
          score: 20,
          config: config,
        );
        planner.nextCenter(
          minCenter: minCenter,
          maxCenter: maxCenter,
          score: 25,
          config: config,
        );
        planner.reset();

        expect(
          planner.nextCenter(
            minCenter: minCenter,
            maxCenter: maxCenter,
            score: 0,
            config: config,
          ),
          midpoint,
        );
      });
    }

    test('Easy is tuned down while Normal and Hard remain established', () {
      final easy = DifficultyConfig.preset(DifficultyMode.easy);
      final normal = DifficultyConfig.preset(DifficultyMode.normal);
      final hard = DifficultyConfig.preset(DifficultyMode.hard);

      expect(easy.baseSpeed, 97);
      expect(easy.maxSpeed, 198);
      expect(easy.speedStep, 4.5);
      expect(easy.baseGap, 296);
      expect(easy.minGap, 226);
      expect(easy.gapStep, 1.8);
      expect(easy.maxVerticalGapChange, 105);
      expect(easy.pipeMotion.enabled, isTrue);
      expect(easy.pipeMotion.amplitude, 28);
      expect(easy.pipeMotion.speed, 0.72);

      expect(normal.baseSpeed, 115);
      expect(normal.maxSpeed, 221);
      expect(normal.baseGap, 296);
      expect(normal.minGap, 197);
      expect(normal.pipeMotion.amplitude, 63);
      expect(normal.obstacleBaseSpeed, 34);
      expect(normal.maxVerticalGapChange, 136);

      expect(hard.baseSpeed, 159);
      expect(hard.maxSpeed, 301);
      expect(hard.baseGap, 252);
      expect(hard.minGap, 163);
      expect(hard.pipeMotion.amplitude, 92);
      expect(hard.obstacleBaseSpeed, 77);
      expect(hard.maxVerticalGapChange, 167);
    });

    test('coin opportunity is centralized and ordered by difficulty', () {
      final easy = DifficultyConfig.preset(DifficultyMode.easy).coinSpawn;
      final normal = DifficultyConfig.preset(DifficultyMode.normal).coinSpawn;
      final hard = DifficultyConfig.preset(DifficultyMode.hard).coinSpawn;

      expect(easy.opportunityRate, lessThan(normal.opportunityRate));
      expect(normal.opportunityRate, lessThan(hard.opportunityRate));
      expect(hard.spawnChance, 1.0);
      expect(hard.minCoins, 1);
      expect(hard.maxCoins, 3);
      expect(easy.opportunityRate / hard.opportunityRate,
          inInclusiveRange(0.20, 0.40));
      expect(normal.opportunityRate / hard.opportunityRate,
          inInclusiveRange(0.55, 0.75));
    });

    test('Easy pipes move gently while Normal and Hard retain stronger motion',
        () {
      final easy = DifficultyConfig.preset(DifficultyMode.easy).pipeMotion;
      final normal = DifficultyConfig.preset(DifficultyMode.normal).pipeMotion;
      final hard = DifficultyConfig.preset(DifficultyMode.hard).pipeMotion;

      expect(easy.enabled, isTrue);
      expect(normal.enabled, true);
      expect(hard.enabled, true);
      expect(easy.amplitude, lessThan(normal.amplitude));
      expect(easy.speed, lessThan(normal.speed));
      expect(hard.amplitude, greaterThan(normal.amplitude));
      expect(hard.speed, greaterThan(normal.speed));
    });

    test('difficulty keeps fair randomized transition limits ordered', () {
      final easy = DifficultyConfig.preset(DifficultyMode.easy);
      final hard = DifficultyConfig.preset(DifficultyMode.hard);

      expect(hard.maxVerticalGapChange, greaterThan(easy.maxVerticalGapChange));
    });
  });
}
