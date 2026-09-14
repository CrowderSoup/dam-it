# Repeatable playtest method

## Purpose

Use short, first-time-player sessions to find comprehension and interaction
problems that automated tests cannot reveal. The process is designed for a
solo developer: a tester can play and respond asynchronously, without a
scheduled or moderated call.

This method measures the build under test. It does not ask testers to evaluate
the whole design roadmap or imagine unfinished features.

## Before sharing a build

Record the following in the test notes:

- commit or release identifier;
- test date;
- build URL;
- browser and operating system;
- keyboard or gamepad;
- whether the tester has played an earlier build;
- which save slot was used and whether it began empty.

Verify the public build in a private browser window. Use an empty save slot.
Never ask a tester to reset a slot containing progress they want to keep.

For tests involving a child, obtain permission from their parent or guardian.
Do not collect names, email addresses, recordings, or other identifying
information in the standard feedback form. A recording is optional and
requires the informed permission of everyone whose voice or image it captures.

## Instructions sent to the tester

Send only the build link and this text:

> This is an unfinished desktop browser game. Please start a new save and play
> as you naturally would. Stop when you think you have finished the demo, no
> longer want to continue, or reach 45 minutes. Movement uses WASD, arrow keys,
> or the left stick/D-pad. Interact uses E, Space, or gamepad A. Afterward,
> please complete the short feedback form. There are no wrong answers.

Do not explain the intended goal, construction order, resource economy, or
meaning of the HUD before play. Discovering those things is part of the test.

## Session record

The tester records their start and stop time. If screen recording is
comfortable and practical, it may replace manual notes; it is never required.

Record times for these checkpoints when they occur:

1. save slot selected and play begins;
2. first successful gather;
3. first dam piece built;
4. dam and pond completed;
5. Lodge completed;
6. both garden spots completed;
7. player chooses to stop.

Pouch upgrades, leaks, and recurring raccoon visits are post-loop activities,
not requirements for completing the current demo baseline. Note whether the
player discovers or uses them, but do not direct the player toward them.

When observing live, do not intervene unless the player asks for help or has
made no meaningful progress for two minutes. Record the question and the exact
hint given. For an asynchronous test, the tester records any point where they
would have asked for help.

## Classifying friction

Keep observations separate from interpretations. “Pressed Space beside three
objects without a visible result” is an observation; “did not understand the
resource cap” is an interpretation to confirm with the tester's response.

- **Blocker:** the player cannot continue without outside help, a restart, or
  a workaround.
- **Major:** the player eventually continues, but loses at least two minutes,
  repeatedly attempts the wrong action, or misses a required goal.
- **Moderate:** the player hesitates, backtracks, or misunderstands feedback,
  but corrects the problem without substantial delay.
- **Minor:** a brief annoyance, presentation issue, or isolated mistake that
  does not affect progress.

Prioritize repeated observations across builds or testers. A single report is
still actionable when it exposes a blocker, accessibility problem, lost
progress, or browser incompatibility.

## After each round

1. Attach or transcribe the completed feedback form without personal data.
2. Add checkpoint times and friction to the build's baseline notes.
3. Link confirmed problems to an existing issue or create one with reproduction
   evidence.
4. Change one cluster of related problems before the next round when possible;
   this keeps comparisons understandable.
5. Preserve the original notes. Do not rewrite an earlier result to match a
   later interpretation.

Three perspectives are preferred for a milestone exit check: a target-age
reader, an adult cozy-game player, and a gamepad user. This is a sampling goal,
not a gate on development. When people are unavailable, record a clearly
labeled internal cognitive walkthrough and leave external validation pending.

