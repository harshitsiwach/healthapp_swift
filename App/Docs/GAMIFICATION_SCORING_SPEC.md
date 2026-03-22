# Gamification Scoring Spec

## Overview
The Wellness Score is a weighted 0-100 value computed from:
- **Nutrition (30%)**: Quality, frequency, and balance of logged meals.
- **Activity (25%)**: Steps, workout completion (requires HealthKit).
- **Recovery (20%)**: Sleep consistency (requires HealthKit).
- **Habit (15%)**: Consistency in minor routines like hydration.
- **Consistency (10%)**: Long-term streak multipliers.

## XP & Levels
- **Seed**: Levels 1-3
- **Active**: Levels 4-6
- **Balanced**: Levels 7-9
- **Strong**: Levels 10-12
- **Elite**: Levels 13-14
- **Legendary**: Level 15+

XP is awarded for daily actions (e.g., logging a meal = 10 XP, balanced meal = +20 XP).

## Streaks
A streak increments when any core activity occurs (logging a meal, completing a workout).
Missing a day resets the streak to 0, though "Skip Tokens" or Grace Periods can be implemented.

**Milestone Bonuses:**
- 3 days: 25 XP
- 7 days: 50 XP
- 14 days: 100 XP
- 30 days: 300 XP
