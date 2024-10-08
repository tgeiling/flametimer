import 'dart:async';
import 'dart:convert';
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

Future<double> calculateTodayFreetimeHours() async {
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
  int totalSecondsToday = prefs.getInt('currentDayFreeTime' + today) ?? 0;

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
      price: 250,
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
      price: 10000,
      imagePath: "assets/icons/item2.png",
      isBought: await prefs.getBool('item2') ?? false,
      isEquiped: await prefs.getBool('item2Equiped') ?? false,
      flameMultiplier: 15.0,
      expMultiplier: 0.0,
      levelNeeded: 3,
    ),
    ShopItemData(
      id: 'item3',
      title: "Working Powder",
      description: "Gives 2x Exp gain",
      price: 4000,
      imagePath: "assets/icons/item3.png",
      isBought: await prefs.getBool('item3') ?? false,
      isEquiped: await prefs.getBool('item3Equiped') ?? false,
      expMultiplier: 2.0,
      levelNeeded: 4,
    ),
    ShopItemData(
      id: 'item4',
      title: "Ring of fire",
      description: "Gives 2x Flame gain and 2x Coin gain",
      price: 6000,
      imagePath: "assets/icons/item4.png",
      isBought: await prefs.getBool('item4') ?? false,
      isEquiped: await prefs.getBool('item4Equiped') ?? false,
      flameMultiplier: 2.0,
      coinMultiplier: 2.0,
      levelNeeded: 5,
    ),
    ShopItemData(
      id: 'item5',
      title: "Cursed Charm",
      description:
          "Slows flame generation by 0.2x but increases coin generation by 4x",
      price: 20000,
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
      price: 100000,
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
      levelNeeded: 8,
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
      levelNeeded: 9,
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
      levelNeeded: 10,
    ),
    ShopItemData(
      id: 'item11',
      title: "Eternal Flame",
      description: "6x flame gain",
      price: 200000,
      imagePath: "assets/icons/item11.png",
      isBought: prefs.getBool('item11') ?? false,
      isEquiped: await prefs.getBool('item11Equiped') ?? false,
      flameMultiplier: 6.0,
      levelNeeded: 11,
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
      price: 800000,
      imagePath: "assets/icons/item13.png",
      isBought: prefs.getBool('item13') ?? false,
      isEquiped: await prefs.getBool('item13Equiped') ?? false,
      coinMultiplier: 3.0,
      levelNeeded: 14,
    ),
    ShopItemData(
      id: 'item14',
      title: "Moon of the Dark",
      description: "10x Exp and 10x Coin gain",
      price: 800000,
      imagePath: "assets/icons/item14.png",
      isBought: prefs.getBool('item14') ?? false,
      isEquiped: await prefs.getBool('item14Equiped') ?? false,
      coinMultiplier: 10.0,
      flameMultiplier: 10.0,
      levelNeeded: 16,
    ),
    ShopItemData(
      id: 'item15',
      title: "Latom",
      description: "2x Exp, 2x Coin, 2x Flame gain",
      price: 2000000,
      imagePath: "assets/icons/item15.png",
      isBought: prefs.getBool('item15') ?? false,
      isEquiped: await prefs.getBool('item15Equiped') ?? false,
      coinMultiplier: 10.0,
      flameMultiplier: 10.0,
      expMultiplier: 10.0,
      levelNeeded: 18,
    ),
    ShopItemData(
      id: 'item16',
      title: "Blazing Cauldron",
      description: "Gives 5x Flame gain and 2.5x Coin gain",
      price: 1000000,
      imagePath: "assets/icons/item16.png", // Image of the cauldron
      isBought: await prefs.getBool('item16') ?? false,
      isEquiped: await prefs.getBool('item16Equiped') ?? false,
      flameMultiplier: 5.0,
      coinMultiplier: 2.5,
      levelNeeded: 20,
    ),
    ShopItemData(
      id: 'item17',
      title: "Sun's Fury",
      description: "Flame generation increases by 5x",
      price: 500000,
      imagePath: "assets/icons/item17.png", // Image of the sun icon
      isBought: await prefs.getBool('item17') ?? false,
      isEquiped: await prefs.getBool('item17Equiped') ?? false,
      flameMultiplier: 5.0,
      levelNeeded: 21,
    ),
    ShopItemData(
      id: 'item18',
      title: "Fiery Pepper",
      description: "Increases flame and exp by 3x",
      price: 250000,
      imagePath: "assets/icons/item18.png", // Image of the pepper
      isBought: await prefs.getBool('item18') ?? false,
      isEquiped: await prefs.getBool('item18Equiped') ?? false,
      flameMultiplier: 3.0,
      expMultiplier: 3.0,
      levelNeeded: 22,
    ),
    ShopItemData(
      id: 'item19',
      title: "Heart of the Flame",
      description: "Grants 10x Flame generation",
      price: 2000000,
      imagePath: "assets/icons/item19.png", // Image of the heart
      isBought: await prefs.getBool('item19') ?? false,
      isEquiped: await prefs.getBool('item19Equiped') ?? false,
      flameMultiplier: 10.0,
      levelNeeded: 23,
    ),
    ShopItemData(
      id: 'item20',
      title: "Molten Core",
      description: "Increases Flame gain by 80x",
      price: 750000,
      imagePath: "assets/icons/item20.png", // Image of molten core
      isBought: await prefs.getBool('item20') ?? false,
      isEquiped: await prefs.getBool('item20Equiped') ?? false,
      flameMultiplier: 80.0,
      levelNeeded: 24,
    ),
    ShopItemData(
      id: 'item21',
      title: "Flame Lantern",
      description: "Gives 200x EXP gain",
      price: 1200000,
      imagePath: "assets/icons/item21.png", // Image of the lantern
      isBought: await prefs.getBool('item21') ?? false,
      isEquiped: await prefs.getBool('item21Equiped') ?? false,
      expMultiplier: 200.0,
      levelNeeded: 25,
    ),
    ShopItemData(
      id: 'item22',
      title: "Toxic Blaze",
      description: "Gives 200x Coin gain",
      price: 1500000,
      imagePath: "assets/icons/item22.png", // Image of toxic green flame
      isBought: await prefs.getBool('item22') ?? false,
      isEquiped: await prefs.getBool('item22Equiped') ?? false,
      coinMultiplier: 200.0,
      levelNeeded: 26,
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
        price: 1000,
      ),
      FireResearchItem(
        type: 'FLAME',
        multiplier: 0.1,
        progress: await prefs.getInt('progressT2_2') ?? 0,
        prefKey: 'progressT2_2',
        imageAsset: 'assets/icons/r6.png',
        description: 'Gains 0.1x Flame boost',
        price: 1000,
      ),
      FireResearchItem(
        type: 'COINS',
        multiplier: 0.1,
        progress: await prefs.getInt('progressT2_3') ?? 0,
        prefKey: 'progressT2_3',
        imageAsset: 'assets/icons/r2.png',
        description: 'Gains 0.1x Coin boost',
        price: 1000,
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
        price: 5000,
      ),
      FireResearchItem(
        type: 'FLAME',
        multiplier: 1.0,
        progress: await prefs.getInt('progressT3_2') ?? 0,
        prefKey: 'progressT3_2',
        imageAsset: 'assets/icons/r7.png',
        description: 'Gains 1.0x Flame boost',
        price: 5000,
      ),
      FireResearchItem(
        type: 'COINS',
        multiplier: 1.0,
        progress: await prefs.getInt('progressT3_3') ?? 0,
        prefKey: 'progressT3_3',
        imageAsset: 'assets/icons/r3.png',
        description: 'Gains 1x Coin boost',
        price: 5000,
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
        price: 10000,
      ),
      FireResearchItem(
        type: 'FLAME',
        multiplier: 10.0,
        progress: await prefs.getInt('progressT4_2') ?? 0,
        prefKey: 'progressT4_2',
        imageAsset: 'assets/icons/r8.png',
        description: 'Gains 10x Flame boost',
        price: 10000,
      ),
      FireResearchItem(
        type: 'COINS',
        multiplier: 10.0,
        progress: await prefs.getInt('progressT4_3') ?? 0,
        prefKey: 'progressT4_3',
        imageAsset: 'assets/icons/r4.png',
        description: 'Gains 10 Coin boost',
        price: 10000,
      ),
    ]),
  ];
}

// Define the QuestType enum
enum QuestType {
  CollectCoins,
  EarnExperience,
  GenerateFlame,
  CollectProductiveTime,
  CollectFreeTimeTime,
  MeetDailyProductiveGoal,
  MeetFreeTimeProductiveGoal,
}

// Define the QuestItem class
class QuestItem {
  final String id;
  String title;
  String description;
  int level;
  bool isDone;
  bool isRewardTaken;
  int progress;
  int maxValue;
  bool isGoldReward;
  String rewardValue;
  int? goldValue;
  String? itemImagePath;
  String? rewardDescription;
  QuestType questType;
  ShopItemData? rewardItem;

  QuestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.isDone,
    required this.isRewardTaken,
    required this.progress,
    required this.maxValue,
    required this.isGoldReward,
    required this.rewardValue,
    this.goldValue,
    this.itemImagePath,
    this.rewardDescription,
    required this.questType,
    this.rewardItem,
  });

  // Convert QuestItem to a Map for JSON encoding
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level': level,
      'isDone': isDone,
      'isRewardTaken': isRewardTaken,
      'progress': progress,
      'maxValue': maxValue,
      'isGoldReward': isGoldReward,
      'rewardValue': rewardValue,
      'goldValue': goldValue,
      'itemImagePath': itemImagePath,
      'rewardDescription': rewardDescription,
      'questType': questType.toString(),
      'rewardItem': rewardItem?.toMap(),
    };
  }

  // Create a QuestItem from a Map (after JSON decoding)
  factory QuestItem.fromMap(Map<String, dynamic> map) {
    return QuestItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      level: map['level'],
      isDone: map['isDone'],
      isRewardTaken: map['isRewardTaken'],
      progress: map['progress'],
      maxValue: map['maxValue'],
      isGoldReward: map['isGoldReward'],
      rewardValue: map['rewardValue'],
      goldValue: map['goldValue'],
      itemImagePath: map['itemImagePath'],
      rewardDescription: map['rewardDescription'],
      questType: QuestType.values.firstWhere(
          (e) => e.toString() == map['questType'],
          orElse: () => QuestType.CollectCoins),
      rewardItem: map['rewardItem'] != null
          ? ShopItemData.fromMap(map['rewardItem'])
          : null,
    );
  }
}

// Global list to store quests
List<QuestItem> questItems = [];

// Function to initialize quests
Future<void> initializeQuestItemsFirst() async {
  final prefs = await SharedPreferences.getInstance();

  // Always load quests from SharedPreferences
  await loadQuestsFromPreferences();

  // Get the current date and compare with the last quest generation date
  DateTime currentDate = DateTime.now();
  int lastQuestGenerationTimestamp =
      prefs.getInt("lastQuestGenerationDate") ?? 0;
  DateTime lastQuestGenerationDate =
      DateTime.fromMillisecondsSinceEpoch(lastQuestGenerationTimestamp);

  // If the quests haven't been generated today, generate new random quests
  if (lastQuestGenerationDate.day != currentDate.day ||
      lastQuestGenerationDate.month != currentDate.month ||
      lastQuestGenerationDate.year != currentDate.year) {
    await generateRandomQuests();
    // After generating new quests, load them again
    await loadQuestsFromPreferences();
  }
}

// Function to generate random quests
Future<void> generateRandomQuests() async {
  final prefs = await SharedPreferences.getInstance();
  Random random = Random();

  // List of all available quest types
  List<QuestType> allQuestTypes = [
    QuestType.CollectCoins,
    QuestType.EarnExperience,
    QuestType.GenerateFlame,
    QuestType.CollectProductiveTime,
    QuestType.CollectFreeTimeTime,
    QuestType.MeetDailyProductiveGoal,
    QuestType.MeetFreeTimeProductiveGoal,
  ];

  // Generate one quest for each quest type
  List<QuestItem> generatedQuests = [];
  int questIdCounter = 1;
  for (QuestType questType in allQuestTypes) {
    QuestItem quest = await generateQuestForType(questType, questIdCounter++);
    generatedQuests.add(quest);
  }

  // Now generate additional quests, ensuring not to duplicate quest types excessively
  while (generatedQuests.length < 7) {
    // Limit the number of duplicates to at most 2 per quest type
    // Count how many times each quest type has been used
    Map<QuestType, int> questTypeCounts = {};
    for (QuestItem quest in generatedQuests) {
      questTypeCounts[quest.questType] =
          (questTypeCounts[quest.questType] ?? 0) + 1;
    }

    // Filter quest types that have been used less than 2 times
    List<QuestType> availableQuestTypes = allQuestTypes.where((questType) {
      return (questTypeCounts[questType] ?? 0) < 2;
    }).toList();

    if (availableQuestTypes.isEmpty) {
      // All quest types have been used the maximum allowed times
      break;
    }

    // Select a random quest type from the available ones
    QuestType questType =
        availableQuestTypes[random.nextInt(availableQuestTypes.length)];

    QuestItem quest = await generateQuestForType(questType, questIdCounter++);
    generatedQuests.add(quest);
  }

  // Assign the generated quests to questItems
  questItems = generatedQuests;

  // Save the generated quests in SharedPreferences
  await saveQuestsToPreferences();

  // Save the current date as the last quest generation date
  DateTime currentDate = DateTime.now();
  await prefs.setInt(
      'lastQuestGenerationDate', currentDate.millisecondsSinceEpoch);
}

// Helper function to generate a quest for a given quest type
Future<QuestItem> generateQuestForType(QuestType questType, int questId) async {
  Random random = Random();
  String title;
  String description;
  int maxValue;

  switch (questType) {
    case QuestType.CollectCoins:
      maxValue =
          (random.nextInt(100) + 1) * 1000; // Between 1000 and 100,000 coins
      title = 'Collect $maxValue Coins';
      description = 'Collect a total of $maxValue coins.';
      break;
    case QuestType.EarnExperience:
      maxValue = (random.nextInt(200) + 1) *
          1000; // Between 1000 and 200,000 experience
      title = 'Earn $maxValue Experience';
      description = 'Earn a total of $maxValue experience points.';
      break;
    case QuestType.GenerateFlame:
      maxValue =
          (random.nextInt(2000) + 1) * 1000; // Between 1000 and 2,000,000 flame
      title = 'Generate $maxValue Flame';
      description = 'Generate a total of $maxValue flame.';
      break;
    case QuestType.CollectProductiveTime:
      maxValue = random.nextInt(10) + 1; // Between 1 and 10 hours
      title = 'Track $maxValue Hours of Productive Time';
      description = 'Accumulate $maxValue hours of productive work.';
      break;
    case QuestType.CollectFreeTimeTime:
      maxValue = random.nextInt(5) + 1; // Between 1 and 5 hours
      title = 'Track $maxValue Hours of Free Time';
      description = 'Be productive for $maxValue hours during free time.';
      break;
    case QuestType.MeetDailyProductiveGoal:
      maxValue = 1; // Goal met or not
      title = 'Meet Today\'s Productive Goal';
      description = 'Achieve your productive goal for today.';
      break;
    case QuestType.MeetFreeTimeProductiveGoal:
      maxValue = 1; // Goal met or not
      title = 'Meet Today\'s Free Time Goal';
      description = 'Achieve your productive goal during free time today.';
      break;
  }

  bool isGoldReward = true;
  int? randomGoldValue;
  String? rewardValue;
  ShopItemData? rewardItem;
  String? itemImagePath;
  String? rewardDescription;

  // Determine if the quest reward should be a shop item (2% chance)
  if (random.nextInt(100) < 2) {
    // 2% chance
    // Ensure shopItems is initialized and accessible
    if (shopItems.isEmpty) {
      initializeShopItemsFirst(); // Initialize shop items if not already done
    }

    // Select a random shop item that is not yet bought
    ShopItemData randomItem = getRandomShopItem();
    isGoldReward = false;
    rewardValue = randomItem.title;
    rewardItem = randomItem;
    itemImagePath = randomItem.imagePath;
    rewardDescription = randomItem.description;
  } else {
    isGoldReward = true;
    randomGoldValue =
        (random.nextInt(1000) + 1) * 50; // Between 1000 and 50.000 gold
    rewardValue = '$randomGoldValue Gold';
  }

  return QuestItem(
    id: questId.toString(),
    title: title,
    description: description,
    level: 1, // All quests available from level 1 for now
    isDone: false,
    isRewardTaken: false,
    progress: 0,
    maxValue: maxValue,
    isGoldReward: isGoldReward,
    rewardValue: rewardValue,
    goldValue: randomGoldValue,
    itemImagePath: itemImagePath,
    rewardDescription: rewardDescription,
    questType: questType,
    rewardItem: rewardItem,
  );
}

// Helper function to select a random shop item
ShopItemData getRandomShopItem() {
  Random random = Random();
  // Get only items that are not yet bought
  List<ShopItemData> availableItems =
      shopItems.where((item) => !item.isBought).toList();

  if (availableItems.isNotEmpty) {
    int index = random.nextInt(availableItems.length);
    return availableItems[index];
  } else {
    // All items are bought; return a default or handle accordingly
    // For this example, we'll return a random item from the full list
    int index = random.nextInt(shopItems.length);
    return shopItems[index];
  }
}

// Function to save quests to SharedPreferences
Future<void> saveQuestsToPreferences() async {
  final prefs = await SharedPreferences.getInstance();

  // Convert the questItems list to a JSON string
  List<String> questJsonList =
      questItems.map((quest) => jsonEncode(quest.toMap())).toList();

  // Save the list to SharedPreferences
  await prefs.setStringList('questItems', questJsonList);
}

// Function to load quests from SharedPreferences
Future<void> loadQuestsFromPreferences() async {
  final prefs = await SharedPreferences.getInstance();

  // Load the list from SharedPreferences
  List<String>? questJsonList = prefs.getStringList('questItems');

  if (questJsonList != null) {
    questItems = questJsonList.map((questJson) {
      Map<String, dynamic> questMap = jsonDecode(questJson);
      return QuestItem.fromMap(questMap);
    }).toList();
  } else {
    questItems = []; // Initialize as empty list if nothing is saved
  }
}

// Function to update quest progress
Future<void> updateQuestProgress(int totalFlameGenerated) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  double productiveDailyGoal = prefs.getDouble('productiveDailyGoal') ?? 0.0;
  double freeTimeProductiveGoal = prefs.getDouble('freetimeDailyGoal') ?? 0.0;

  double totalProductiveHours = await calculateTotalProductiveTimeHours();
  double todayProductiveHours = await calculateTodayProductiveHours();
  double todayProductiveProgress = productiveDailyGoal > 0
      ? (todayProductiveHours / productiveDailyGoal).clamp(0.0, 1.0)
      : 0.0;

  double totalFreeTimeHours = await calculateTotalFreeTimeHours();
  double todayFreeTimeHours = await calculateTodayFreetimeHours();
  ;
  double todayFreeTimeProgress = freeTimeProductiveGoal > 0
      ? (todayFreeTimeHours / freeTimeProductiveGoal).clamp(0.0, 1.0)
      : 0.0;

  DateTime currentDate = DateTime.now();
  int lastGoalHitTimestamp = prefs.getInt("lastGoalHitDate") ?? 0;
  DateTime lastGoalHitDate =
      DateTime.fromMillisecondsSinceEpoch(lastGoalHitTimestamp);

  bool todayGoalMet = prefs.getBool("isTodayGoalMet") ?? false;
  bool todayFreeTimeGoalMet = prefs.getBool("isTodayFreeTimeGoalMet") ?? false;

  // Reset isTodayGoalMet if it's a new day
  if (lastGoalHitDate.day != currentDate.day ||
      lastGoalHitDate.month != currentDate.month ||
      lastGoalHitDate.year != currentDate.year) {
    await prefs.setBool("isTodayGoalMet", false);
    await prefs.setBool("isTodayFreeTimeGoalMet", false);
    todayGoalMet = false;
    todayFreeTimeGoalMet = false;
  }

  int level = prefs.getInt('playerLevel') ?? 1;
  int totalCoinsCollected = prefs.getInt('coinCount') ?? 0;
  int totalExperienceEarned = prefs.getInt('expCount') ?? 0;

  for (QuestItem quest in questItems) {
    if (!quest.isDone && quest.level <= level) {
      switch (quest.questType) {
        case QuestType.CollectProductiveTime:
          quest.progress = totalProductiveHours.floor();
          break;
        case QuestType.CollectFreeTimeTime:
          quest.progress = totalFreeTimeHours.floor();
          break;
        case QuestType.MeetDailyProductiveGoal:
          quest.progress = todayGoalMet ? 1 : 0;
          break;
        case QuestType.MeetFreeTimeProductiveGoal:
          quest.progress = todayFreeTimeGoalMet ? 1 : 0;
          break;
        case QuestType.CollectCoins:
          quest.progress = totalCoinsCollected;
          break;
        case QuestType.EarnExperience:
          quest.progress = totalExperienceEarned;
          break;
        case QuestType.GenerateFlame:
          quest.progress = totalFlameGenerated;
          break;
      }

      quest.progress = quest.progress.clamp(0, quest.maxValue);

      if (quest.progress >= quest.maxValue) {
        quest.progress = quest.maxValue;
        quest.isDone = true;
      }
    }
  }

  // Save updated quests to SharedPreferences
  await saveQuestsToPreferences();

  if (todayProductiveProgress >= 1 && !todayGoalMet) {
    await prefs.setBool("isTodayGoalMet", true); // Set today's goal as met
    await prefs.setInt("lastGoalHitDate",
        currentDate.millisecondsSinceEpoch); // Update the last goal hit date
  }

  if (todayFreeTimeProgress >= 1 && !todayFreeTimeGoalMet) {
    await prefs.setBool(
        "isTodayFreeTimeGoalMet", true); // Set today's free time goal as met
    await prefs.setInt("lastFreeTimeGoalHitDate",
        currentDate.millisecondsSinceEpoch); // Update the last goal hit date
  }
}

Future<void> saveShopItemsToPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> shopItemsJsonList =
      shopItems.map((item) => jsonEncode(item.toMap())).toList();
  await prefs.setStringList('shopItems', shopItemsJsonList);
}

Future<void> loadShopItemsFromPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? shopItemsJsonList = prefs.getStringList('shopItems');
  if (shopItemsJsonList != null) {
    shopItems = shopItemsJsonList.map((itemJson) {
      Map<String, dynamic> itemMap = jsonDecode(itemJson);
      return ShopItemData.fromMap(itemMap);
    }).toList();
  } else {
    // If not found in SharedPreferences, initialize as before
    initializeShopItemsFirst();
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
