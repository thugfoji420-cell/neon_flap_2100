# Neon Flap 2100 Development Instructions

You are working on a production Flutter + Flame game.

Before making ANY change:

- Analyze the existing implementation.
- Never assume functionality.
- Read the affected files completely.
- Understand dependencies.
- Preserve existing functionality.
- Never rewrite unrelated code.

--------------------------------------------------

PROJECT STACK

Flutter
Flame Engine
Firebase Authentication
Cloud Firestore
Google Mobile Ads
Material 3

--------------------------------------------------

PROJECT GOAL

This is a production-quality arcade game.

The priority order is:

1. Stability
2. Gameplay
3. Performance
4. UI Polish
5. Maintainability

--------------------------------------------------

CODING RULES

Never:

- Duplicate code
- Break existing features
- Remove working functionality
- Hardcode values that belong in configuration
- Create unnecessary files

Always:

- Reuse existing services
- Reuse existing widgets
- Follow current architecture
- Keep files clean
- Keep methods small
- Use null-safe code
- Explain major changes

--------------------------------------------------

GAMEPLAY RULES

Gameplay must remain smooth.

Player movement should feel natural.

Pipe generation must:

- Alternate in a proper zig-zag pattern.
- Never generate impossible gaps.
- Always remain fair.

Camera should:

- Show approximately two upcoming pipe gaps.
- Never zoom excessively.
- Never crop gameplay.

Difficulty:

Current difficulty should remain approximately 60% of the original version.

Easy
Medium
Hard

must remain balanced.

--------------------------------------------------

COIN SYSTEM

Every Firebase user owns independent data.

Never share coins between users.

Coins must always sync correctly between:

CoinService
Firestore
HUD
Reward System
Daily Reward
Game Rewards

Rewarded Ads:

Coins earned from rewarded ads must immediately appear in:

- HUD
- Firestore
- CoinService

No duplicate rewards.

No lost rewards.

--------------------------------------------------

DAILY REWARD

Daily reward must:

Never overflow.

Be responsive.

Support all Android screen sizes.

No RenderFlex overflow.

--------------------------------------------------

AUTHENTICATION

Google Sign-In is required.

Requirements:

Continue with Google button

Exit Game button

Logout button

Logout must:

Sign out Firebase

Sign out Google

Return user to login screen

Allow selecting another Google account.

Exit Game button:

Completely close the application.

Use the correct Flutter implementation.

Do NOT use logout for Exit Game.

--------------------------------------------------

BUTTONS

All buttons must:

Fit text correctly.

Have responsive padding.

Professional Material 3 appearance.

No text overflow.

Maintain accessibility.

--------------------------------------------------

UI

Modern.

Clean.

Minimal.

Responsive.

Material 3.

Animations should remain smooth.

--------------------------------------------------

PERFORMANCE

Avoid:

Large widget rebuilds

Memory leaks

Duplicate listeners

Repeated Firestore reads

Unnecessary allocations

Prefer object reuse.

--------------------------------------------------

TESTING

After EVERY task:

Run flutter analyze

Run flutter test

Fix every error introduced.

Never mark a task complete until:

Implementation exists.

Behavior is verified.

No regressions exist.

--------------------------------------------------

WHEN REPORTING

Always include:

Files modified

Reason for each change

Root cause

Verification steps

Possible side effects

--------------------------------------------------

NEVER MARK A TASK COMPLETE

unless the change is visible in the application or verified by tests.

--------------------------------------------------

If unsure,

STOP

Explain the issue

Ask for clarification

Do not guess.
