import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'main.dart';
import 'shop.dart';
import 'stats.dart';

Future<List<double>> calculateWeeklyProgress(
    double dailyGoal, String mode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  List<double> weeklyProgress = [];
  for (String day in daysOfWeek) {
    String key = 'currentDay' +
        (mode == "productive" ? "ProductiveTime" : "FreeTime") +
        day;
    int totalSeconds = prefs.getInt(key) ?? 0;
    double hoursForDay = totalSeconds / 3600.0; // Convert seconds to hours
    double progress = (hoursForDay / dailyGoal).clamp(0.0, 1.0);

    // Debugging logs
    print(
        "Day: $day, Hours: $hoursForDay, Goal: $dailyGoal, Progress: $progress");

    weeklyProgress.add(progress);
  }
  return weeklyProgress;
}

Future<List<double>> calculateWeeklyProgressKW(
    double dailyGoal, String mode, int kw) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  List<double> weeklyProgress = [];
  for (String day in daysOfWeek) {
    // Adjust the key to include the specified KW
    String key = 'KW$kw' +
        'currentDay' +
        (mode == "productive" ? "ProductiveTime" : "FreeTime") +
        day;
    int totalSeconds = prefs.getInt(key) ?? 0;
    double hoursForDay = totalSeconds / 3600.0; // Convert seconds to hours
    double progress = (hoursForDay / dailyGoal).clamp(0.0, 1.0);

    // Debugging logs
    print(
        "KW: $kw, Day: $day, Hours: $hoursForDay, Goal: $dailyGoal, Progress: $progress");

    weeklyProgress.add(progress);
  }
  return weeklyProgress;
}

Stream<List<double>> calculateWeeklyProgressStream(
    double dailyGoal, String mode) async* {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  while (true) {
    List<double> weeklyProgress = [];

    for (String day in daysOfWeek) {
      String key = 'currentDay' +
          (mode == "productive" ? "ProductiveTime" : "FreeTime") +
          day;
      int totalSeconds = prefs.getInt(key) ?? 0;
      double hoursForDay = totalSeconds / 3600;
      double progress =
          dailyGoal == 0.0 ? 0.0 : (hoursForDay / dailyGoal).clamp(0.0, 1.0);
      weeklyProgress.add(progress);
    }

    yield weeklyProgress;

    await Future.delayed(
        Duration(seconds: 30)); // Adjust the duration as needed
  }
}

Future<double> calculateAverageProductiveHours() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  double totalHours = 0.0;
  int daysWithRecordedTime = 0;
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Process the current week first
  for (String day in daysOfWeek) {
    String currentWeekKey = 'currentDayProductiveTime' + day;
    int totalSeconds = prefs.getInt(currentWeekKey) ?? 0;
    if (totalSeconds > 0) {
      daysWithRecordedTime++;
      totalHours += totalSeconds / 3600; // Convert seconds to hours
    }
  }

  // Process the saved weeks
  List<String> savedWeeks = await getSavedKWWeeks();
  for (String week in savedWeeks) {
    for (String day in daysOfWeek) {
      String key = 'KW$week' + 'currentDayProductiveTime' + day;
      int totalSeconds = prefs.getInt(key) ?? 0;
      if (totalSeconds > 0) {
        daysWithRecordedTime++;
        totalHours += totalSeconds / 3600;
      }
    }
  }

  return daysWithRecordedTime > 0 ? totalHours / daysWithRecordedTime : 0.0;
}

Future<double> calculateAverageFreeTimeHours() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  double totalHours = 0.0;
  int daysWithRecordedTime = 0;
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Process the current week first
  for (String day in daysOfWeek) {
    String currentWeekKey = 'currentDayFreeTime' + day;
    int totalSeconds = prefs.getInt(currentWeekKey) ?? 0;
    if (totalSeconds > 0) {
      daysWithRecordedTime++;
      totalHours += totalSeconds / 3600; // Convert seconds to hours
    }
  }

  // Process the saved weeks
  List<String> savedWeeks = await getSavedKWWeeks();
  for (String week in savedWeeks) {
    for (String day in daysOfWeek) {
      String key = 'KW$week' + 'currentDayFreeTime' + day;
      int totalSeconds = prefs.getInt(key) ?? 0;
      if (totalSeconds > 0) {
        daysWithRecordedTime++;
        totalHours += totalSeconds / 3600;
      }
    }
  }

  return daysWithRecordedTime > 0 ? totalHours / daysWithRecordedTime : 0.0;
}

Future<double> calculateProductiveDaysPercentage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  int daysWithProductiveTime = 0;

  for (String day in daysOfWeek) {
    int totalSeconds = prefs.getInt('currentDayProductiveTime' + day) ?? 0;
    if (totalSeconds > 0) {
      daysWithProductiveTime++; // Increment count if the day had productive time
    }
  }

  // Calculate the percentage of days with productive time
  return daysWithProductiveTime.toDouble();
}

Future<double> calculateTodayProductiveHours() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Get the current day of the week
  int currentDayOfWeek = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  String today = daysOfWeek[currentDayOfWeek - 1];

  // Fetch the total seconds recorded for today's productive time
  int totalSecondsToday = prefs.getInt('currentDayProductiveTime' + today) ?? 0;

  // Convert total seconds to hours
  double hoursToday = totalSecondsToday / 3600.0;

  return hoursToday;
}

Future<double> calculateTotalFreeTimeHours() async {
  final prefs = await SharedPreferences.getInstance();
  int totalFreeTimeSeconds = prefs.getInt('totalFreeTimeSeconds') ?? 0;
  return totalFreeTimeSeconds / 3600; // Convert seconds to hours
}

Future<double> calculateTotalProductiveTimeHours() async {
  final prefs = await SharedPreferences.getInstance();
  int totalProductiveTimeSeconds =
      prefs.getInt('totalProductiveTimeSeconds') ?? 0;
  return totalProductiveTimeSeconds / 3600; // Convert seconds to hours
}

Future<double> calculateMaximumProductiveTimeHours() async {
  final prefs = await SharedPreferences.getInstance();
  int maximumProductiveSeconds = prefs.getInt('maximumProductiveSeconds') ?? 0;
  return maximumProductiveSeconds / 3600;
}

String getCurrentCalendarWeek() {
  var now = DateTime.now();
  DateTime firstDayOfYear = DateTime(now.year, 1, 1);
  var weekOfYear =
      ((now.difference(firstDayOfYear).inDays - now.weekday + 10) / 7).floor();
  return '$weekOfYear';
}

String formatHoursToNearestFive(double totalHours) {
  int totalMinutes = (totalHours * 60).round(); // Convert to total minutes
  int roundedMinutes = (totalMinutes / 5).round() * 5; // Round to nearest 5

  int hours = roundedMinutes ~/ 60; // Calculate hours
  int minutes = roundedMinutes % 60; // Calculate remaining minutes

  return "${hours}h ${minutes}m"; // Return formatted string
}

int getIsoWeekNumber(DateTime date) {
  int dayOfYear = int.parse(DateFormat("D").format(date));
  int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
  if (date.weekday == 7 && date.day < 4) {
    woy -= 1;
  }
  return woy;
}

Future<List<String>> getSavedKWWeeks() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> savedWeeks = [];
  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  String mode =
      "ProductiveTime"; // Assume you're checking for "ProductiveTime" or "FreeTime"

  // Check up to 53 weeks as most years have 52 or 53 weeks
  for (int week = 1; week <= 53; week++) {
    bool weekHasData = false;

    // Check each day of the week for the current KW
    for (String day in daysOfWeek) {
      String key = 'KW$week' + 'currentDay' + mode + day;
      if (prefs.getInt(key) != null) {
        weekHasData = true;
        break; // No need to check further if one day has data
      }
    }

    if (weekHasData) {
      savedWeeks.add(week.toString());
    }
  }

  return savedWeeks;
}

void initializeShopItemsFirst() async {
  final prefs = await SharedPreferences.getInstance();

  shopItems = [
    ShopItemData(
      id: 'item1',
      title: "How to make a big Fire",
      description: "Gives 1.5x more flame genration",
      price: 100,
      imagePath: "assets/icons/item1.png",
      isBought: await prefs.getBool('item1') ?? false,
      isEquiped: await prefs.getBool('item1Equiped') ?? false,
      flameMultiplier: 1.5,
      levelNeeded: 2,
    ),
    ShopItemData(
      id: 'item2',
      title: "Art of Hellfire",
      description: "Gives 15x more flame generation but exp is locked",
      price: 100,
      imagePath: "assets/icons/item2.png",
      isBought: await prefs.getBool('item2') ?? false,
      isEquiped: await prefs.getBool('item2Equiped') ?? false,
      flameMultiplier: 15.0,
      levelNeeded: 2,
    ),
    ShopItemData(
      id: 'item3',
      title: "Starting Powder",
      description: "The flame starts significally faster",
      price: 100,
      imagePath: "assets/icons/item3.png",
      isBought: await prefs.getBool('item3') ?? false,
      isEquiped: await prefs.getBool('item3Equiped') ?? false,
      levelNeeded: 4,
    ),
    ShopItemData(
      id: 'item4',
      title: "Ring of fire",
      description: "Slows down decaying rate when not productive",
      price: 100,
      imagePath: "assets/icons/item4.png",
      isBought: await prefs.getBool('item4') ?? false,
      isEquiped: await prefs.getBool('item4Equiped') ?? false,
      levelNeeded: 5,
    ),
    ShopItemData(
      id: 'item5',
      title: "Cursed Charm",
      description:
          "Slows flame generation by 0.2x but increases coin generation by 4x",
      price: 100,
      imagePath: "assets/icons/item5.png",
      isBought: await prefs.getBool('item5') ?? false,
      isEquiped: await prefs.getBool('item5Equiped') ?? false,
      flameMultiplier: 0.8,
      coinMultiplier: 4.0,
      levelNeeded: 7,
    ),
    ShopItemData(
      id: 'item6',
      title: "Lucky Charm",
      description: "Randomly gives bigger chunks of money",
      price: 100,
      imagePath: "assets/icons/item6.png",
      isBought: await prefs.getBool('item6') ?? false,
      isEquiped: await prefs.getBool('item6Equiped') ?? false,
      coinMultiplier: 1.0 + Random().nextDouble() * 5.0,
      levelNeeded: 7,
    ),
    ShopItemData(
      id: 'item7',
      title: "Broken Artifact",
      description:
          "Literally broken increases flame and coin generation by 10x",
      price: 150000,
      imagePath: "assets/icons/item7.png",
      isBought: prefs.getBool('item7') ?? false,
      isEquiped: await prefs.getBool('item7Equiped') ?? false,
      flameMultiplier: 10.0,
      coinMultiplier: 10.0,
      levelNeeded: 7,
    ),
    ShopItemData(
      id: 'item8',
      title: "Grinding Needles",
      description: "5x Exp gain",
      price: 10000,
      imagePath: "assets/icons/item8.png",
      isBought: prefs.getBool('item8') ?? false,
      isEquiped: await prefs.getBool('item8Equiped') ?? false,
      expMultiplier: 5.0,
      levelNeeded: 7,
    ),
    ShopItemData(
      id: 'item9',
      title: "Preparing the Powder",
      description: "4x Exp gain",
      price: 20000,
      imagePath: "assets/icons/item9.png",
      isBought: prefs.getBool('item9') ?? false,
      isEquiped: await prefs.getBool('item9Equiped') ?? false,
      expMultiplier: 4.0,
      levelNeeded: 8,
    ),
    ShopItemData(
      id: 'item10',
      title: "Ash selling Permit",
      description: "2.5x Coin gain",
      price: 120000,
      imagePath: "assets/icons/item10.png",
      isBought: prefs.getBool('item10') ?? false,
      isEquiped: await prefs.getBool('item10Equiped') ?? false,
      coinMultiplier: 2.5,
      levelNeeded: 9,
    ),
    ShopItemData(
      id: 'item11',
      title: "Eternal Flame",
      description: "6x flame gain",
      price: 10,
      imagePath: "assets/icons/item11.png",
      isBought: prefs.getBool('item11') ?? false,
      isEquiped: await prefs.getBool('item11Equiped') ?? false,
      flameMultiplier: 6.0,
      levelNeeded: 10,
    ),
    ShopItemData(
      id: 'item12',
      title: "Premium Wood",
      description: "2.5x flame gain",
      price: 50000,
      imagePath: "assets/icons/item12.png",
      isBought: prefs.getBool('item12') ?? false,
      isEquiped: await prefs.getBool('item12Equiped') ?? false,
      flameMultiplier: 2.5,
      levelNeeded: 12,
    ),
    ShopItemData(
      id: 'item13',
      title: "Taxes",
      description: "Make them pay 3.0x Coin gain",
      price: 80000,
      imagePath: "assets/icons/item13.png",
      isBought: prefs.getBool('item13') ?? false,
      isEquiped: await prefs.getBool('item13Equiped') ?? false,
      coinMultiplier: 3.0,
      levelNeeded: 14,
    ),
    ShopItemData(
      id: 'item14',
      title: "Moon of the Dark",
      description: "10x Exp and 10x Coin gain at night",
      price: 80000,
      imagePath: "assets/icons/item14.png",
      isBought: prefs.getBool('item14') ?? false,
      isEquiped: await prefs.getBool('item14Equiped') ?? false,
      coinMultiplier: 10.0,
      flameMultiplier: 10.0,
      levelNeeded: 14,
    ),
    ShopItemData(
      id: 'item15',
      title: "Latom",
      description: "2x Exp, 2x Coin, 2x Flame gain",
      price: 80000,
      imagePath: "assets/icons/item15.png",
      isBought: prefs.getBool('item15') ?? false,
      isEquiped: await prefs.getBool('item15Equiped') ?? false,
      coinMultiplier: 10.0,
      flameMultiplier: 10.0,
      expMultiplier: 10.0,
      levelNeeded: 14,
    ),
  ];
}

void initializeResearchItemsFirst() async {
  final prefs = await SharedPreferences.getInstance();

  tiers = [
    FireResearchTierData(tier: 1, levelToUnlock: 5, researchItems: [
      FireResearchItem(
        type: 'EXP',
        multiplier: 0.01,
        progress: await prefs.getInt('progressT1_1') ?? 0,
        prefKey: 'progressT1_1',
        imageAsset: 'assets/icons/r9.png',
        description: 'Gains 0.01x Exp boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'FLAME',
        multiplier: 0.01,
        progress: await prefs.getInt('progressT1_2') ?? 0,
        prefKey: 'progressT1_2',
        imageAsset: 'assets/icons/r5.png',
        description: 'Gains 0.01x Flame boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'COINS',
        multiplier: 0.01,
        progress: await prefs.getInt('progressT1_3') ?? 0,
        prefKey: 'progressT1_3',
        imageAsset: 'assets/icons/r1.png',
        description: 'Gains 0.01x Coin boost',
        price: 100,
      ),
    ]),
    FireResearchTierData(tier: 2, levelToUnlock: 6, researchItems: [
      FireResearchItem(
        type: 'EXP',
        multiplier: 0.1,
        progress: await prefs.getInt('progressT2_1') ?? 0,
        prefKey: 'progressT2_1',
        imageAsset: 'assets/icons/r10.png',
        description: 'Gains 0.1x Exp boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'FLAME',
        multiplier: 0.1,
        progress: await prefs.getInt('progressT2_2') ?? 0,
        prefKey: 'progressT2_2',
        imageAsset: 'assets/icons/r6.png',
        description: 'Gains 0.1x Flame boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'COINS',
        multiplier: 0.1,
        progress: await prefs.getInt('progressT2_3') ?? 0,
        prefKey: 'progressT2_3',
        imageAsset: 'assets/icons/r2.png',
        description: 'Gains 0.1x Coin boost',
        price: 100,
      ),
    ]),
    FireResearchTierData(tier: 3, levelToUnlock: 15, researchItems: [
      FireResearchItem(
        type: 'EXP',
        multiplier: 1.0,
        progress: await prefs.getInt('progressT3_1') ?? 0,
        prefKey: 'progressT3_1',
        imageAsset: 'assets/icons/r11.png',
        description: 'Gains 1.0x Exp boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'FLAME',
        multiplier: 1.0,
        progress: await prefs.getInt('progressT3_2') ?? 0,
        prefKey: 'progressT3_2',
        imageAsset: 'assets/icons/r7.png',
        description: 'Gains 1.0x Flame boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'COINS',
        multiplier: 1.0,
        progress: await prefs.getInt('progressT3_3') ?? 0,
        prefKey: 'progressT3_3',
        imageAsset: 'assets/icons/r3.png',
        description: 'Gains 1x Coin boost',
        price: 100,
      )
    ]),
    FireResearchTierData(tier: 4, levelToUnlock: 20, researchItems: [
      FireResearchItem(
        type: 'EXP',
        multiplier: 10.0,
        progress: await prefs.getInt('progressT4_1') ?? 0,
        prefKey: 'progressT4_1',
        imageAsset: 'assets/icons/r12.png',
        description: 'Gains 10x Exp boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'FLAME',
        multiplier: 10.0,
        progress: await prefs.getInt('progressT4_2') ?? 0,
        prefKey: 'progressT4_2',
        imageAsset: 'assets/icons/r8.png',
        description: 'Gains 10x Flame boost',
        price: 100,
      ),
      FireResearchItem(
        type: 'COINS',
        multiplier: 10.0,
        progress: await prefs.getInt('progressT4_3') ?? 0,
        prefKey: 'progressT4_3',
        imageAsset: 'assets/icons/r4.png',
        description: 'Gains 10 Coin boost',
        price: 100,
      ),
    ]),
  ];
}

void initializeQuestItemsFirst() async {
  final prefs = await SharedPreferences.getInstance();

  questItems = [
    QuestItem(
      id: "1",
      title: 'A Start',
      description: 'Reach 5 Hours Productive Total',
      level: 1,
      isDone: prefs.getBool("1_isDone") ?? false,
      isRewardTaken:
          prefs.getBool("1_isRewardTaken") ?? false, // Added parameter
      progress: prefs.getInt("1_progress") ?? 0,
      maxValue: 5,
      isGoldReward: true,
      rewardValue: '100 Gold',
      goldValue: 100,
    ),
    QuestItem(
      id: "2",
      title: 'Restore Balance',
      description: 'Reach 3 Avg Hours',
      level: 2,
      isDone: prefs.getBool("2_isDone") ?? false,
      isRewardTaken:
          prefs.getBool("2_isRewardTaken") ?? false, // Added parameter
      progress: prefs.getInt("2_progress") ?? 0,
      maxValue: 3,
      isGoldReward: false,
      rewardValue: 'Magic Sword',
      itemImagePath:
          'assets/icons/item1.png', // Assuming an image asset path for the item
      rewardDescription: 'A legendary sword imbued with magical powers.',
    ),
    QuestItem(
      id: "3",
      title: 'Gain Traktion',
      description: 'Reach 1 Hours Productive Total',
      level: 25,
      isDone: prefs.getBool("3_isDone") ?? false,
      isRewardTaken:
          prefs.getBool("3_isRewardTaken") ?? false, // Added parameter
      progress: prefs.getInt("3_progress") ?? 0,
      maxValue: 1,
      isGoldReward: true,
      rewardValue: '150000 Gold',
      goldValue: 150000,
    ),
    QuestItem(
      id: "4",
      title: 'Goal Hitter',
      description: 'Reach your goal just once',
      level: 27,
      isDone: prefs.getBool("4_isDone") ?? false,
      isRewardTaken:
          prefs.getBool("4_isRewardTaken") ?? false, // Added parameter
      progress: prefs.getInt("4_progress") ?? 0,
      maxValue: 1,
      isGoldReward: true,
      rewardValue: '150000 Gold',
      goldValue: 150000,
    ),
    QuestItem(
      id: "5",
      title: 'Goal Hitter 2',
      description: 'Reach your goal just once',
      level: 29,
      isDone: prefs.getBool("5_isDone") ?? false,
      isRewardTaken:
          prefs.getBool("5_isRewardTaken") ?? false, // Added parameter
      progress: prefs.getInt("5_progress") ?? 0,
      maxValue: 1,
      isGoldReward: true,
      rewardValue: '150000 Gold',
      goldValue: 150000,
    ),
  ];
}

Future<void> updateQuestProgress() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  double productiveDailyGoal =
      await prefs.getDouble('productiveDailyGoal') ?? 0.0;

  double averageProductiveHours = await calculateAverageProductiveHours();
  double todayProductiveHours = await calculateTodayProductiveHours();
  double todayProductiveProgress = productiveDailyGoal > 0
      ? (todayProductiveHours / productiveDailyGoal).clamp(0.0, 1.0)
      : 0.0;

  DateTime currentDate = DateTime.now();
  int lastGoalHitTimestamp = prefs.getInt("lastGoalHitDate") ?? 0;
  DateTime lastGoalHitDate =
      DateTime.fromMillisecondsSinceEpoch(lastGoalHitTimestamp);

  bool todayGoalMet = await prefs.getBool("isTodayGoalMet") ?? false;

  // Reset isTodayGoalMet if it's a new day
  if (lastGoalHitDate.day != currentDate.day ||
      lastGoalHitDate.month != currentDate.month ||
      lastGoalHitDate.year != currentDate.year) {
    await prefs.setBool("isTodayGoalMet", false);
  }

  for (QuestItem quest in questItems) {
    // Update each quest's progress based on its title
    switch (quest.id) {
      case '1':
        if (quest.level >= level) {
          quest.progress = totalProductiveHours.floor();
        }
        break;
      case '2':
        if (quest.level >= level) {
          quest.progress =
              (averageProductiveHours).clamp(0, quest.maxValue).toInt();
        }
        break;
      case '3':
        if (quest.level >= level) {
          quest.progress = totalProductiveHours.floor();
        }
        break;
      case '4':
        if (quest.level >= level) {
          quest.progress = todayGoalMet ? 1 : 0;
        }
        break;
      case '5':
        if (quest.level >= level) {
          quest.progress = todayGoalMet ? 1 : 0;
        }
        break;
      // Add more cases for other quests as needed
    }

    if (todayProductiveProgress >= 1 && !todayGoalMet) {
      await prefs.setBool("isTodayGoalMet", true); // Set today's goal as met
      await prefs.setInt("lastGoalHitDate",
          currentDate.millisecondsSinceEpoch); // Update the last goal hit date
    }

    // Save updated progress in SharedPreferences
    await prefs.setInt('${quest.id}_progress', quest.progress);
    if (quest.progress >= quest.maxValue) {
      await prefs.setBool('${quest.id}_isDone', true);
    }

    // Check if the quest is completed and perform necessary actions
    if (quest.progress >= quest.maxValue) {
      // Quest completed actions here
    }
  }
}

Future<void> loadSharedPreferencesFirstTime() async {
  //total hours
  double loadedTotalProductiveHours = await calculateTotalProductiveTimeHours();
  double loadedTotalFreeTimeHours = await calculateTotalFreeTimeHours();

  //total hours
  double loadedMaximumProductiveHours =
      await calculateMaximumProductiveTimeHours();

  totalProductiveHours = loadedTotalProductiveHours;
  totalFreeTimeHours = loadedTotalFreeTimeHours;
  maximumProductiveHours = loadedMaximumProductiveHours;
}

double calculateTotalFlameMultiplier(
    List<ShopItemData> shopItems, List<FireResearchTierData> researchTiers) {
  double totalFlameMultiplier = 1.0; // Starting with a default multiplier of 1

  for (var item in shopItems) {
    if (item.isEquiped &&
        item.flameMultiplier != null &&
        item.flameMultiplier != 0.0) {
      totalFlameMultiplier *= item.flameMultiplier!;
    }
  }

  for (var tier in researchTiers) {
    for (var researchItem in tier.researchItems) {
      if (researchItem.type == 'FLAME') {
        totalFlameMultiplier +=
            (researchItem.multiplier * researchItem.progress);
      }
    }
  }

  return totalFlameMultiplier;
}

double calculateTotalCoinMultiplier(
    List<ShopItemData> shopItems, List<FireResearchTierData> researchTiers) {
  double totalCoinMultiplier = 1.0; // Starting with a default multiplier of 1

  for (var item in shopItems) {
    if (item.isEquiped &&
        item.coinMultiplier != null &&
        item.coinMultiplier != 0.0) {
      totalCoinMultiplier *= item.coinMultiplier!;
    }
  }

  for (var tier in researchTiers) {
    for (var researchItem in tier.researchItems) {
      if (researchItem.type == 'COINS') {
        totalCoinMultiplier +=
            (researchItem.multiplier * researchItem.progress);
      }
    }
  }

  return totalCoinMultiplier;
}

double calculateTotalExpMultiplier(
    List<ShopItemData> shopItems, List<FireResearchTierData> researchTiers) {
  double totalExpMultiplier = 1.0; // Starting with a default multiplier of 1

  for (var item in shopItems) {
    if (item.isEquiped &&
        item.expMultiplier != null &&
        item.expMultiplier != 0.0) {
      totalExpMultiplier *= item.expMultiplier!;
    }
  }

  for (var tier in researchTiers) {
    for (var researchItem in tier.researchItems) {
      if (researchItem.type == 'EXP') {
        totalExpMultiplier += (researchItem.multiplier * researchItem.progress);
      }
    }
  }

  return totalExpMultiplier;
}

int calculateLevel(int expCount, List<int> expGoals) {
  for (int i = 0; i < expGoals.length; i++) {
    if (expCount < expGoals[i]) {
      // Since levels are typically 1-indexed, return i + 1
      return i + 1;
    }
  }
  // If expCount exceeds all goals, return the length of the list + 1
  // which represents the maximum level
  return expGoals.length + 1;
}

Color getFlameColor(int flameLevel) {
  if (flameLevel <= 10) {
    return Colors.orange.shade900;
  } else if (flameLevel >= 11 && flameLevel <= 20) {
    return Colors.red.shade800;
  } else if (flameLevel >= 21 && flameLevel <= 30) {
    return Colors.green;
  } else if (flameLevel >= 31 && flameLevel <= 40) {
    return Colors.purple;
  } else {
    return Colors.black; // Default color for out of range levels
  }
}
