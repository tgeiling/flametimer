import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumorphic_ui/neumorphic_ui.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'stats.dart';
import 'achivements.dart';
import 'shop.dart';

import 'sharedFunctions.dart';

void main() {
  runApp(
    MyApp(),
  );
}

ThemeData themeData = ThemeData(
  textTheme: TextTheme(
    bodyLarge: GoogleFonts.roboto(),
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeData,
      home: MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScaffold extends StatefulWidget {
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

var _currentIndex = 0;
List<double> weekValues = [];
double freetimeDailyGoal = 0;
double productiveDailyGoal = 0;
int flameCounter = 0;
int coinCount = 0;
bool brake = false;
int difference = 0;
int level = 1;
int expCount = 0;
double flameCounterMultiplier = 1.0;
int flameLevel = 1;

final List<int> expGoals = [
  500,
  1000,
  2000,
  3000,
  7000,
  12000,
  20000,
  30000,
  45000,
  65000,
  90000,
  130000,
  180000,
  250000,
  340000,
  450000,
  600000,
  800000,
  1050000,
  1350000,
  1700000,
  2100000,
  2550000,
  3050000,
  3600000,
  4200000,
  4850000,
  5550000,
  6300000,
  7100000,
  7960000,
  8880000,
  9860000,
  10900000,
  12050000,
  13250000,
  14500000,
  15800000,
  17150000,
  18550000,
  20000000,
];

class _MainScaffoldState extends State<MainScaffold> {
  PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            MainFrame(),
            ShopWidget(),
            Stats(
              weekValues: weekValues,
              freetimeDailyGoal: freetimeDailyGoal,
              productiveDailyGoal: productiveDailyGoal,
            ),
            AchievementsPage(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/frame2.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: SalomonBottomBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              _pageController.jumpToPage(i);
            },
            items: [
              SalomonBottomBarItem(
                icon: Image.asset(
                  'assets/icons/home.png',
                  height: 40,
                  width: 40, // Adjust the size as needed
                ),
                title: Text("Timer"),
                selectedColor: Colors.grey[600],
              ),
              SalomonBottomBarItem(
                icon: Image.asset(
                  'assets/icons/gear.png',
                  height: 40,
                  width: 40, // Adjust the size as needed
                ),
                title: Text("Profile"),
                selectedColor: Colors.grey[600],
              ),
              SalomonBottomBarItem(
                icon: Image.asset(
                  'assets/icons/disk.png',
                  height: 40,
                  width: 40, // Adjust the size as needed
                ),
                title: Text("Stats"),
                selectedColor: Colors.grey[600],
              ),
              SalomonBottomBarItem(
                icon: Image.asset(
                  'assets/icons/star.png',
                  height: 40,
                  width: 40, // Adjust the size as needed
                ),
                title: Text("Ach."),
                selectedColor: Colors.grey[600],
              ),
            ],
          ),
        ));
  }
}

class MainFrame extends StatefulWidget {
  @override
  _MainFrameState createState() => _MainFrameState();
}

class _MainFrameState extends State<MainFrame>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late Timer _freeTimeInterval;
  late Timer _productiveInterval;
  late Timer _pauseInterval = Timer(Duration.zero, () {});

  String _activeMode = "freeTime";
  late int _freeTimeTotalSeconds;
  late int _productiveTimeTotalSeconds;
  late int _pauseTimeTotalSeconds;

  @override
  void initState() {
    super.initState();
    _loadSavedValues();
    loadSharedPreferencesFirstTime();
    initializeShopItemsFirst();
    initializeResearchItemsFirst();
    initializeQuestItemsFirst();
    _resetTimers();
    WidgetsBinding.instance.addObserver(this);
  }

  void _updateTime(int hours, int minutes, int seconds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_currentIndex == 0) {
      setState(() {
        if (_activeMode == "freeTime" ||
            (hours == 0 && minutes == 0 && seconds == 0)) {
          freeTimeHours = hours.toString().padLeft(2, "0");
          freeTimeMinutes = minutes.toString().padLeft(2, "0");
          freeTimeSeconds = seconds.toString().padLeft(2, "0");

          // Save the values to SharedPreferences
          prefs.setString('freeTimeHours', freeTimeHours);
          prefs.setString('freeTimeMinutes', freeTimeMinutes);
          prefs.setString('freeTimeSeconds', freeTimeSeconds);

          _freeTimeTotalSeconds = getTotalSecondsFromTime(
            hours: freeTimeHours,
            minutes: freeTimeMinutes,
            seconds: freeTimeSeconds,
          );

          prefs.setInt('freeTimeTotalSeconds', _freeTimeTotalSeconds);
        }

        if (_activeMode == "productive" ||
            (hours == 0 && minutes == 0 && seconds == 0)) {
          productiveHours = hours.toString().padLeft(2, "0");
          productiveMinutes = minutes.toString().padLeft(2, "0");
          productiveSeconds = seconds.toString().padLeft(2, "0");

          // Save the values to SharedPreferences
          prefs.setString('productiveHours', productiveHours);
          prefs.setString('productiveMinutes', productiveMinutes);
          prefs.setString('productiveSeconds', productiveSeconds);

          _productiveTimeTotalSeconds = getTotalSecondsFromTime(
            hours: productiveHours,
            minutes: productiveMinutes,
            seconds: productiveSeconds,
          );

          prefs.setInt(
              'productiveTimeTotalSeconds', _productiveTimeTotalSeconds);
        }
      });
    } else {
      if (_activeMode == "freeTime" ||
          (hours == 0 && minutes == 0 && seconds == 0)) {
        freeTimeHours = hours.toString().padLeft(2, "0");
        freeTimeMinutes = minutes.toString().padLeft(2, "0");
        freeTimeSeconds = seconds.toString().padLeft(2, "0");

        // Save the values to SharedPreferences
        prefs.setString('freeTimeHours', freeTimeHours);
        prefs.setString('freeTimeMinutes', freeTimeMinutes);
        prefs.setString('freeTimeSeconds', freeTimeSeconds);

        _freeTimeTotalSeconds = getTotalSecondsFromTime(
          hours: freeTimeHours,
          minutes: freeTimeMinutes,
          seconds: freeTimeSeconds,
        );

        prefs.setInt('freeTimeTotalSeconds', _freeTimeTotalSeconds);
      }

      if (_activeMode == "productive" ||
          (hours == 0 && minutes == 0 && seconds == 0)) {
        productiveHours = hours.toString().padLeft(2, "0");
        productiveMinutes = minutes.toString().padLeft(2, "0");
        productiveSeconds = seconds.toString().padLeft(2, "0");

        // Save the values to SharedPreferences
        prefs.setString('productiveHours', productiveHours);
        prefs.setString('productiveMinutes', productiveMinutes);
        prefs.setString('productiveSeconds', productiveSeconds);

        _productiveTimeTotalSeconds = getTotalSecondsFromTime(
          hours: productiveHours,
          minutes: productiveMinutes,
          seconds: productiveSeconds,
        );

        prefs.setInt('productiveTimeTotalSeconds', _productiveTimeTotalSeconds);
      }
    }

    _saveCurrentDayData(1);
  }

  void _loadSavedValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      freeTimeHours = prefs.getString('freeTimeHours') ?? '00';
      freeTimeMinutes = prefs.getString('freeTimeMinutes') ?? '00';
      freeTimeSeconds = prefs.getString('freeTimeSeconds') ?? '00';

      productiveHours = prefs.getString('productiveHours') ?? '00';
      productiveMinutes = prefs.getString('productiveMinutes') ?? '00';
      productiveSeconds = prefs.getString('productiveSeconds') ?? '00';

      _freeTimeTotalSeconds = prefs.getInt('freeTimeTotalSeconds') ?? 0;
      _productiveTimeTotalSeconds =
          prefs.getInt('productiveTimeTotalSeconds') ?? 0;
      freetimeDailyGoal = prefs.getDouble('freetimeDailyGoal') ?? 0;
      productiveDailyGoal = prefs.getDouble('productiveDailyGoal') ?? 0;

      weekValues = weekValues;
    });
    freetimeDailyGoal = await prefs.getDouble('freetimeDailyGoal') ?? 0;
    productiveDailyGoal = await prefs.getDouble('productiveDailyGoal') ?? 0;
    coinCount = await prefs.getInt("coinCount") ?? 0;
    level = await prefs.getInt("level") ?? 1;
    flameLevel = await prefs.getInt("flameLevel") ?? 0;
    expCount = await prefs.getInt("expCount") ?? 0;
    weekValues =
        await calculateWeeklyProgress(productiveDailyGoal, "productive");
    setState(() {});
  }

  void _saveCurrentDayData(int increment) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    double flameMultiplier = calculateTotalFlameMultiplier(shopItems, tiers);
    if (_activeMode != "freeTime") {
      flameCounter = (flameCounter + increment * flameMultiplier).ceil();
    } else {
      int decrement = (flameCounter / 1800).ceil();
      flameCounter = flameCounter - decrement;
      if (flameCounter < 0) {
        flameCounter = 0;
      }
    }

    int originalCoinCount = coinCount;
    double coinMultiplier = calculateTotalCoinMultiplier(shopItems, tiers);
    coinCount =
        (coinCount + increment * coinMultiplier * flameCounterMultiplier)
            .ceil();
    difference = coinCount - originalCoinCount;

    double expMultiplier = calculateTotalExpMultiplier(shopItems, tiers);
    expCount =
        (expCount + increment * expMultiplier * flameCounterMultiplier).ceil();

    int expToLevel = calculateLevel(expCount, expGoals);

    if (expToLevel > level) {
      level = expToLevel;
      showLevelUpDialog(context, level);
    }

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

    String freeTimeKey =
        'currentDayFreeTime' + daysOfWeek[currentDayOfWeek - 1];
    String productiveTimeKey =
        'currentDayProductiveTime' + daysOfWeek[currentDayOfWeek - 1];

    // Fetch the current total seconds and increment by 1 for each type
    int currentFreeTimeSeconds = (prefs.getInt(freeTimeKey) ?? 0) + increment;
    int currentProductiveTimeSeconds =
        (prefs.getInt(productiveTimeKey) ?? 0) + increment;
    int totalFreeTimeSeconds =
        (prefs.getInt("totalFreeTimeSeconds") ?? 0) + increment;
    int totalProductiveTimeSeconds =
        (prefs.getInt("totalProductiveTimeSeconds") ?? 0) + increment;

    int maximumProductiveSeconds =
        prefs.getInt("maximumProductiveSeconds") ?? 0;

    DateTime now = DateTime.now();
    String lastResetDateKey = "lastResetDate";
    String? lastResetDateString = await prefs.getString(lastResetDateKey);
    DateTime lastResetDate = lastResetDateString != null
        ? DateTime.parse(lastResetDateString)
        : DateTime.now().subtract(Duration(days: 1)); // Default to yesterday

    DateTime midnightYesterday = DateTime(now.year, now.month, now.day);
    int secondsSinceMidnight = now.difference(midnightYesterday).inSeconds;

    int secondsForToday = secondsSinceMidnight;
    int secondsForYesterday = increment - secondsSinceMidnight;
    String yesterdayKey = daysOfWeek[(currentDayOfWeek + 5) % 7];

    if (currentProductiveTimeSeconds > maximumProductiveSeconds) {
      await prefs.setInt(
          "maximumProductiveSeconds", currentProductiveTimeSeconds);
    }

    // Compare the last reset date to the current date
    if (now.year > lastResetDate.year ||
        now.month > lastResetDate.month ||
        now.day > lastResetDate.day) {
      if (increment > 1) {
        if (_activeMode == "freeTime") {
          await prefs.setInt(yesterdayKey, secondsForYesterday);
          await prefs.setInt(freeTimeKey, secondsForToday);
          await prefs.setInt("totalFreeTimeSeconds", totalFreeTimeSeconds);
        } else {
          await prefs.setInt(productiveTimeKey, currentProductiveTimeSeconds);
          await prefs.setInt(
              "totalProductiveTimeSeconds", totalProductiveTimeSeconds);
        }
      } else {
        await prefs.setInt(freeTimeKey, 0);
        await prefs.setInt(productiveTimeKey, 0);
      }
      // Update the last reset date to today
      await prefs.setString(lastResetDateKey, now.toIso8601String());
    } else {
      // Save the updated seconds back to SharedPreferences
      if (_activeMode == "freeTime") {
        await prefs.setInt(freeTimeKey, currentFreeTimeSeconds);
        await prefs.setInt("totalFreeTimeSeconds", totalFreeTimeSeconds);
      } else {
        await prefs.setInt(productiveTimeKey, currentProductiveTimeSeconds);
        await prefs.setInt(
            "totalProductiveTimeSeconds", totalProductiveTimeSeconds);
      }
    }

    int currentKW = getIsoWeekNumber(DateTime.now());
    int lastSavedKW = prefs.getInt("lastSavedKW") ?? 0;

    if (currentKW != lastSavedKW) {
      for (String day in daysOfWeek) {
        String freeTimeKey = 'currentDayFreeTime' + day;
        String productiveTimeKey = 'currentDayProductiveTime' + day;

        int freeTimeSeconds = prefs.getInt(freeTimeKey) ?? 0;
        int productiveTimeSeconds = prefs.getInt(productiveTimeKey) ?? 0;

        print('KW$lastSavedKW$freeTimeKey');
        print(freeTimeSeconds);
        print('KW$lastSavedKW$productiveTimeKey');
        print(productiveTimeSeconds);

        // Save last week's data with a KW mark
        await prefs.setInt('KW$lastSavedKW$freeTimeKey', freeTimeSeconds);
        await prefs.setInt(
            'KW$lastSavedKW$productiveTimeKey', productiveTimeSeconds);
      }

      // Save the new KW mark
      await prefs.setInt("lastSavedKW", currentKW);
    }

    await prefs.setInt("coinCount", coinCount);
    await prefs.setInt("expCount", expCount);
    await prefs.setInt("level", level);

    // Temporary print for debugging - shows the seconds value for every weekday
    print("########## Total Seconds for Each Day ##########");
    print("Total Seconds productive: $totalProductiveTimeSeconds");
    print("Total Seconds productive: $totalFreeTimeSeconds");
    for (String day in daysOfWeek) {
      String tempFreeKey = 'currentDayFreeTime' + day;
      String tempProdKey = 'currentDayProductiveTime' + day;
      int freeSeconds = prefs.getInt(tempFreeKey) ?? 0;
      int prodSeconds = prefs.getInt(tempProdKey) ?? 0;
      print(
          "$day - Free Time: $freeSeconds seconds, Productive Time: $prodSeconds seconds");
    }
  }

  String _getImagePath() {
    print("The Flame is at: $flameCounter");

    final conditions = [
      {
        'limit': 30000,
        'levelReq': 30,
        'multiplier': 3.1,
        'flameLevel': 30,
        'path': 'assets/campfires/campfire30.gif'
      },
      {
        'limit': 29000,
        'levelReq': 29,
        'multiplier': 3.0,
        'flameLevel': 29,
        'path': 'assets/campfires/campfire29.gif'
      },
      {
        'limit': 28000,
        'levelReq': 28,
        'multiplier': 2.9,
        'flameLevel': 28,
        'path': 'assets/campfires/campfire28.gif'
      },
      {
        'limit': 27000,
        'levelReq': 27,
        'multiplier': 2.8,
        'flameLevel': 27,
        'path': 'assets/campfires/campfire27.gif'
      },
      {
        'limit': 26000,
        'levelReq': 26,
        'multiplier': 2.7,
        'flameLevel': 26,
        'path': 'assets/campfires/campfire26.gif'
      },
      {
        'limit': 25000,
        'levelReq': 25,
        'multiplier': 2.6,
        'flameLevel': 25,
        'path': 'assets/campfires/campfire25.gif'
      },
      {
        'limit': 24000,
        'levelReq': 24,
        'multiplier': 2.5,
        'flameLevel': 24,
        'path': 'assets/campfires/campfire24.gif'
      },
      {
        'limit': 23000,
        'levelReq': 23,
        'multiplier': 2.4,
        'flameLevel': 23,
        'path': 'assets/campfires/campfire23.gif'
      },
      {
        'limit': 22000,
        'levelReq': 22,
        'multiplier': 2.3,
        'flameLevel': 22,
        'path': 'assets/campfires/campfire22.gif'
      },
      {
        'limit': 21000,
        'levelReq': 21,
        'multiplier': 2.2,
        'flameLevel': 21,
        'path': 'assets/campfires/campfire21.gif'
      },
      {
        'limit': 20000,
        'levelReq': 20,
        'multiplier': 3.0,
        'flameLevel': 20,
        'path': 'assets/campfires/campfire20.gif'
      },
      {
        'limit': 19000,
        'levelReq': 19,
        'multiplier': 2.9,
        'flameLevel': 19,
        'path': 'assets/campfires/campfire19.gif'
      },
      {
        'limit': 18000,
        'levelReq': 18,
        'multiplier': 2.8,
        'flameLevel': 18,
        'path': 'assets/campfires/campfire18.gif'
      },
      {
        'limit': 17000,
        'levelReq': 17,
        'multiplier': 2.7,
        'flameLevel': 17,
        'path': 'assets/campfires/campfire17.gif'
      },
      {
        'limit': 16000,
        'levelReq': 16,
        'multiplier': 2.6,
        'flameLevel': 16,
        'path': 'assets/campfires/campfire16.gif'
      },
      {
        'limit': 15000,
        'levelReq': 15,
        'multiplier': 2.5,
        'flameLevel': 15,
        'path': 'assets/campfires/campfire15.gif'
      },
      {
        'limit': 14000,
        'levelReq': 14,
        'multiplier': 2.4,
        'flameLevel': 14,
        'path': 'assets/campfires/campfire14.gif'
      },
      {
        'limit': 13000,
        'levelReq': 13,
        'multiplier': 2.3,
        'flameLevel': 13,
        'path': 'assets/campfires/campfire13.gif'
      },
      {
        'limit': 12000,
        'levelReq': 12,
        'multiplier': 2.2,
        'flameLevel': 12,
        'path': 'assets/campfires/campfire12.gif'
      },
      {
        'limit': 11000,
        'levelReq': 11,
        'multiplier': 2.1,
        'flameLevel': 11,
        'path': 'assets/campfires/campfire11.gif'
      },
      {
        'limit': 10000,
        'levelReq': 10,
        'multiplier': 2.0,
        'flameLevel': 10,
        'path': 'assets/campfires/campfire10.gif'
      },
      {
        'limit': 9000,
        'levelReq': 9,
        'multiplier': 1.9,
        'flameLevel': 9,
        'path': 'assets/campfires/campfire9.gif'
      },
      {
        'limit': 8000,
        'levelReq': 8,
        'multiplier': 1.8,
        'flameLevel': 8,
        'path': 'assets/campfires/campfire8.gif'
      },
      {
        'limit': 7000,
        'levelReq': 7,
        'multiplier': 1.7,
        'flameLevel': 7,
        'path': 'assets/campfires/campfire7.gif'
      },
      {
        'limit': 6000,
        'levelReq': 6,
        'multiplier': 1.6,
        'flameLevel': 6,
        'path': 'assets/campfires/campfire6.gif'
      },
      {
        'limit': 5000,
        'levelReq': 5,
        'multiplier': 1.5,
        'flameLevel': 5,
        'path': 'assets/campfires/campfire5.gif'
      },
      {
        'limit': 4000,
        'levelReq': 4,
        'multiplier': 1.4,
        'flameLevel': 4,
        'path': 'assets/campfires/campfire4.gif'
      },
      {
        'limit': 3000,
        'levelReq': 3,
        'multiplier': 1.3,
        'flameLevel': 3,
        'path': 'assets/campfires/campfire3.gif'
      },
      {
        'limit': 2000,
        'levelReq': 2,
        'multiplier': 1.2,
        'flameLevel': 2,
        'path': 'assets/campfires/campfire2.gif'
      },
      {
        'limit': 500,
        'levelReq': 1,
        'multiplier': 1.1,
        'flameLevel': 1,
        'path': 'assets/campfires/campfire1.gif'
      },
    ];

    if (_activeMode == "freeTime" && flameCounter >= 0) {
      return 'assets/campfires/smokeFire.gif';
    }

    if (_activeMode == "pause" && flameCounter >= 0) {
      return 'assets/campfires/smokeFire.gif';
    }

    for (var condition in conditions) {
      // Extracting and checking types from the map
      final limit = condition['limit'];
      final levelReq = condition['levelReq'];
      final multiplier = condition['multiplier'];
      final flameLevelValue = condition['flameLevel'];
      final path = condition['path'];

      if (limit is int &&
          levelReq is int &&
          multiplier is double &&
          flameLevelValue is int &&
          path is String) {
        if (flameCounter >= limit && level >= levelReq) {
          flameCounterMultiplier = multiplier;
          flameLevel = flameLevelValue;
          return path;
        }
      } else {
        // Handle the error or log a warning if the types are not as expected
        print('Invalid data types in conditions map');
      }
    }
    return 'assets/campfires/campfire0.gif';
  }

  Widget campfireImageSwitcher() {
    // Static list with individually set padding values for each level
    const List<double> paddingValues = [
      90.0, //0
      90.0, //1
      90.0, //2
      90.0, //3
      100.0, //4
      60.0, //5
      63.0, //6
      63.0, //7
      60.0, //8
      90.0, //9
      90.0, //10
      120.0, //11
      120.0, //12
      90.0, //13
      90.0, //14
      90.0, //15
      90.0, //16
      90.0, //17
      90.0, //18
      90.0, //19
      90.0, //20
      70.0, //21
      70.0, //22
      90.0, //23
      90.0, //24
      90.0, //25
      90.0, //26
      90.0, //27
      90.0, //28
      90.0, //29
      140.0, //30
    ];

    const List<double> heightValues = [
      1, //0
      180, //1
      230, //2
      230, //3
      230, //4
      260, //5
      230, //6
      230, //7
      230, //8
      230, //9
      230, //10
      230, //11
      160, //12
      210, //13
      210, //14
      180, //15
      230, //16
      230, //17
      230, //18
      230, //19
      230, //20
      220, //21
      220, //22
      260, //23
      260, //24
      260, //25
      260, //26
      260, //27
      260, //28
      260, //29
      200, //30
    ];

    double getPaddingForLevel() {
      return paddingValues[flameLevel];
    }

    double getHeightForLevel() {
      return heightValues[flameLevel];
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double maxHeight = MediaQuery.of(context).size.height;
        double height = maxHeight * 0.48;

        return Container(
          height: height,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/campfires/campfireBG.png'),
              fit: BoxFit.fitHeight,
            ),
          ),
          child: Container(
            padding: EdgeInsets.only(
                bottom: getPaddingForLevel()), // Adjust padding as needed
            alignment: Alignment.bottomCenter,
            child: FittedBox(
              fit: BoxFit
                  .scaleDown, // Adjust this to control how the image should fit within the box
              child: SizedBox(
                height:
                    getHeightForLevel(), // Set the desired height for the image
                width: constraints
                    .maxWidth, // You might want to adjust this according to your layout needs
                child: Image.asset(
                  _getImagePath(), // Replace with your method to get the image path
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int getTotalSecondsFromTime(
      {required String hours,
      required String minutes,
      required String seconds}) {
    int hoursInSeconds = int.parse(hours) * 3600; // 3600 seconds in an hour
    int minutesInSeconds = int.parse(minutes) * 60; // 60 seconds in a minute
    int secondsAsInt =
        int.parse(seconds); // seconds are already in the correct unit

    return hoursInSeconds + minutesInSeconds + secondsAsInt;
  }

  void _printLabel(String mode) {
    setState(() {
      label = mode;
    });
  }

  AssetImage labelSwitcher() {
    if (_activeMode == 'freeTime') {
      return AssetImage('assets/steelpixel1.png');
    } else {
      return AssetImage('assets/steelpixel2.png');
    }
  }

  void _start() {
    if (_activeMode == "freeTime") {
      if (_freeTimeInterval != null && _freeTimeInterval.isActive) {
        return;
      }
      _freeTimeInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    } else if (_activeMode == "productive") {
      if (_productiveInterval != null && _productiveInterval.isActive) {
        return;
      }
      _productiveInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    } else if (_activeMode == "pause") {
      _activeMode = "productive";
      _printLabel(_activeMode);
      _productiveInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    }

    if (_pauseInterval.isActive) {
      _pauseInterval.cancel();
    }
    _pauseTimeTotalSeconds = 0;
    brake = false;
  }

  void _startAfterPause() {
    if (_activeMode == "freeTime") {
      if (_freeTimeInterval != null && _freeTimeInterval.isActive) {
        return;
      }
      _freeTimeInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    } else if (_activeMode == "productive") {
      if (_productiveInterval != null && _productiveInterval.isActive) {
        return;
      }
      _productiveInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    }

    if (_activeMode == "pause") {
      if (_pauseInterval != null && _pauseInterval.isActive) {
        return;
      }
      _pauseInterval = Timer.periodic(Duration(seconds: 1), (timer) {
        _pauseTimeTotalSeconds++;
        print("Pause Counter is at  $_pauseTimeTotalSeconds");
      });
    }
    brake = false;
  }

  void _stop([bool pause = true]) {
    if (_activeMode == "freeTime") {
      _freeTimeInterval.cancel();
    } else if (_activeMode == "productive") {
      _productiveInterval.cancel();
    }
    if (pause) {
      _startPauseTracking(_pauseInterval);
    }
  }

  void _brakeStop() {
    if (_activeMode == "freeTime") {
      _freeTimeInterval.cancel();
    } else if (_activeMode == "productive") {
      _productiveInterval.cancel();
    }
    if (_activeMode == "pause") {
      _pauseInterval.cancel();
    }
    brake = true;
  }

  void _reset() {
    _freeTimeInterval.cancel();
    _productiveInterval.cancel();
    _pauseInterval.cancel();
    _freeTimeTotalSeconds = 0;
    _productiveTimeTotalSeconds = 0;
    _pauseTimeTotalSeconds = 0;
    _updateTime(0, 0, 0);
  }

  void _resetTimers() {
    _freeTimeInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    _productiveInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    _pauseInterval = Timer.periodic(Duration(seconds: 1), _stopWatch);
    _freeTimeInterval.cancel();
    _productiveInterval.cancel();
    _pauseInterval.cancel();
  }

  void _switchTime() {
    _stop(false);

    if (_activeMode == "freeTime") {
      setState(() {
        _activeMode = "productive";
      });
    } else if (_activeMode == "productive") {
      setState(() {
        _activeMode = "freeTime";
      });
    } else if (_activeMode == "pause") {
      setState(() {
        _activeMode = "productive";
      });
    }

    _printLabel(_activeMode);
    _start();
  }

  void _stopWatch(Timer timer) {
    late int counter; // Provide an initial value
    if (_activeMode == "freeTime") {
      print(_freeTimeTotalSeconds);
      counter = ++_freeTimeTotalSeconds;
    } else if (_activeMode == "productive") {
      print(_productiveTimeTotalSeconds);
      counter = ++_productiveTimeTotalSeconds;
    }

    int hours = counter ~/ 3600;
    int minutes = (counter ~/ 60) % 60;
    int seconds = counter % 60;

    _updateTime(hours, minutes, seconds);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if ((_productiveInterval.isActive ||
            _freeTimeInterval.isActive ||
            _pauseInterval.isActive) &&
        state == AppLifecycleState.paused) {
      _saveCurrentTime();
      _brakeStop();
    } else if (brake == true && state == AppLifecycleState.resumed) {
      // start gets triggerd before updateTimerOnResume so instead of pause continued productive time gets continued
      // just add active mode pause

      _updateTimerOnResume();
      _startAfterPause();
    }
  }

  void _startPauseTracking(Timer timer) {
    if (!_pauseInterval.isActive) {
      setState(() {
        _activeMode = "pause";
        _printLabel(_activeMode);
      });
      _pauseInterval = Timer.periodic(Duration(seconds: 1), (timer) {
        _pauseTimeTotalSeconds++;

        int decrement = (flameCounter / 1800).ceil();
        flameCounter = flameCounter - decrement;
        if (flameCounter < 0) {
          flameCounter = 0;
        }

        print("The Flame is at: $flameCounter");
        print("Pause Counter is at  $_pauseTimeTotalSeconds");
      });
    }
  }

  void _saveCurrentTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastPauseTime', DateTime.now().millisecondsSinceEpoch);
  }

  void _updateTimerOnResume() async {
    final prefs = await SharedPreferences.getInstance();
    int lastPauseTime =
        prefs.getInt('lastPauseTime') ?? DateTime.now().millisecondsSinceEpoch;
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int elapsedTimeInSeconds = (currentTime - lastPauseTime) ~/ 1000;

    if (_activeMode == "pause") {
      _pauseTimeTotalSeconds += elapsedTimeInSeconds;
    } else if (_activeMode == "freeTime" &&
        _freeTimeInterval != null &&
        _freeTimeInterval!.isActive) {
      _freeTimeTotalSeconds += elapsedTimeInSeconds;
    } else if (_activeMode == "productive" &&
        _productiveInterval != null &&
        _productiveInterval!.isActive) {
      _productiveTimeTotalSeconds += elapsedTimeInSeconds;
      flameCounter += elapsedTimeInSeconds;
    }

    _saveCurrentDayData(elapsedTimeInSeconds);
  }

  String label = "freeTime";
  String freeTimeHours = "00";
  String freeTimeMinutes = "00";
  String freeTimeSeconds = "00";
  String productiveHours = "00";
  String productiveMinutes = "00";
  String productiveSeconds = "00";

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 231, 231, 231),
          border: Border.all(
            color: Color.fromARGB(255, 187, 187, 187),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Text(
                label,
                style: TextStyle(
                    fontSize: 52,
                    fontFamily: 'digi',
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 46, 46, 46)),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          campfireImageSwitcher(),
                          Positioned(
                            top: 10,
                            right: 25,
                            child: CoinCountDisplay(),
                          ),
                          Positioned(
                              top: 50,
                              right: 27,
                              child: CuteLittleWidget(
                                flameCounterValue:
                                    calculateTotalFlameMultiplier(
                                        shopItems, tiers),
                                coinCounterValue: calculateTotalCoinMultiplier(
                                    shopItems, tiers),
                                expCounterValue: calculateTotalExpMultiplier(
                                    shopItems, tiers),
                                levelMultiplierValue: flameCounterMultiplier,
                                flameIconPath: 'assets/icons/item4.png',
                                coinIconPath: 'assets/icons/coin.png',
                                expIconPath: 'assets/icons/item6.png',
                                levelIconPath: 'assets/icons/item1.png',
                              )),
                          Positioned(
                            top: 0,
                            right: 35,
                            child:
                                FlameCounterWidget(flameCounter: flameCounter),
                          ),
                          Positioned(
                              bottom: 30,
                              left: 120,
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: 8, right: 8, top: 4, bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "Lv: " + flameLevel.toString(),
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'digi',
                                      fontWeight: FontWeight.bold,
                                      color: getFlameColor(flameLevel)),
                                ),
                              )),
                          Positioned(
                              top: 150,
                              right: 20,
                              child: Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                        'assets/frame4.png'), // Replace with your image path
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Wrap(
                                  direction: Axis.vertical,
                                  spacing: 5,
                                  runSpacing: 2,
                                  children: shopItems
                                      .where((item) => item.isEquiped)
                                      .map((item) => SizedBox(
                                            width: 34,
                                            height: 34,
                                            child: Image.asset(
                                              item.imagePath,
                                              fit: BoxFit.cover,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              )),
                        ],
                      ),
                      timerWrapper(context),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildImageButton(
                              'assets/icons/switch.png', _switchTime),
                          _buildImageButton('assets/icons/play.png', _start),
                          _buildImageButton('assets/icons/pause.png', _stop),
                          _buildImageButton('assets/icons/trash.png', _reset),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget CoinCountDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade800, // Dark gray background
        border: Border.all(color: Colors.grey.shade300), // Light gray border
        borderRadius: BorderRadius.circular(5), // Rounded corners
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Ensures the Row takes only required space
        children: <Widget>[
          Image.asset(
            'assets/icons/coinStack.png',
            width: 20, // Adjust the size to fit your needs
            height: 20, // Adjust the size to fit your needs
          ),
          SizedBox(width: 4), // Optional spacing between image and text
          Center(
            child: Text(
              coinCount.toString().padLeft(6, '0'),
              style: TextStyle(
                fontFamily: 'digi',
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget timerWrapper(BuildContext context) {
    // Check the screen height
    //bool isTallScreen = MediaQuery.of(context).size.height < 730;

    if (_activeMode == "freeTime") {
      // Use Column for taller screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimer(
            "Free Time",
            freeTimeHours,
            freeTimeMinutes,
            freeTimeSeconds,
            const Color.fromARGB(255, 35, 115, 235),
          ),
        ],
      );
    } else {
      // Use Row for shorter screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimer(
            "Productive Time",
            productiveHours,
            productiveMinutes,
            productiveSeconds,
            const Color.fromARGB(255, 202, 51, 51),
          ),
        ],
      );
    }
  }

  Widget _buildTimer(
    String label,
    String hours,
    String minutes,
    String seconds,
    Color color,
  ) {
    return Column(
      children: [
        SizedBox(height: 10),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeSpan(hours, color, context),
              Text(
                ":",
                style: TextStyle(
                    color: color, fontSize: 30, fontWeight: FontWeight.normal),
              ),
              _buildTimeSpan(minutes, color, context),
              Text(":",
                  style: TextStyle(
                      color: color,
                      fontSize: 30,
                      fontWeight: FontWeight.normal)),
              _buildTimeSpan(seconds, color, context),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimeSpan(String value, Color color, BuildContext context) {
    // Get the TextScaler from the MediaQuery
    TextScaler textScaler = MediaQuery.of(context).textScaler;

    // Use TextScaler to scale the font size
    double scaledFontSize = textScaler.scale(40);

    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage('assets/frame1.png'), // Replace with your image path
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
            width: 66,
            height: 65,
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                    color: color,
                    fontSize: scaledFontSize,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'digi'),
              ),
            )));
  }

  Widget _buildSmallTimer(
    String label,
    String hours,
    String minutes,
    String seconds,
  ) {
    return Column(
      children: [
        SizedBox(height: 10),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallTimeSpan(hours),
              Text(
                ":",
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.normal),
              ),
              _buildSmallTimeSpan(minutes),
              Text(":", style: TextStyle(fontSize: 20)),
              _buildSmallTimeSpan(seconds),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSmallTimeSpan(String value) {
    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage('assets/frame1.png'), // Replace with your image path
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
            width: 46,
            height: 46,
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                    color: Color.fromARGB(255, 35, 115, 235),
                    fontSize: 26,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'digi'),
              ),
            )));
  }

  Widget _buildImageButton(String assetPath, Function() onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Image.asset(
        assetPath,
        width: 60,
        height: 60,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class FlameCounterWidget extends StatefulWidget {
  final int flameCounter;

  FlameCounterWidget({Key? key, required this.flameCounter}) : super(key: key);

  @override
  _FlameCounterWidgetState createState() => _FlameCounterWidgetState();
}

class _FlameCounterWidgetState extends State<FlameCounterWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..stop();

    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
    _positionAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(0, -1))
        .animate(_animationController);
  }

  @override
  void didUpdateWidget(FlameCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (difference > 0) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return difference > 0
        ? FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _positionAnimation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('assets/icons/coin.png'),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '+' + difference.toString(),
                    style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'digi',
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        : SizedBox(); // Return an empty widget if the difference is 0 or less
  }

  @override
  bool get wantKeepAlive => true;
}

final Map<int, String> levelDescriptions = {
  1: "Ember",
  2: "Flamelet",
  3: "Kindler",
  4: "Igniter",
  5: "Inferno",
  6: "Pyromancer",
  7: "Blazebringer",
  8: "Flarecaster",
  9: "Scorcher",
  10: "Firestarter",
  11: "Incendian",
  12: "Combustor",
  13: "Cinder",
  14: "Pyroclast",
  15: "Burning Heart",
  16: "Infernal Champion",
  17: "Volcano Lord",
  18: "Molten Magus",
  19: "Flame Overlord",
  20: "Fire Phoenix",
  21: "Eternal Flame",
  22: "Blazing Specter",
  23: "Pyro Titan",
  24: "Magma Serpent",
  25: "Fire Elemental",
  26: "Flame Demigod",
  27: "Inferno Monarch",
  28: "Scorching Deity",
  29: "Blazing God",
  30: "Eternal Inferno",
  31: "Pyro Divinity",
  32: "Flame Sovereign",
  33: "Volcano Emperor",
  34: "Molten Deity",
  35: "Flame Tyrant",
  36: "Fire Ascendant",
  37: "Infernal Divinity",
  38: "Scorching Supreme",
  39: "Blazing Ascendant",
  40: "Fire Legend",
};

void showLevelUpDialog(BuildContext context, int level) {
  String description = levelDescriptions[level] ?? "Unknown Level";

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Level Up!"),
        content:
            Text("Congratulations! You've reached level $level: $description"),
        actions: <Widget>[
          TextButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class CuteLittleWidget extends StatelessWidget {
  final double flameCounterValue;
  final double coinCounterValue;
  final double expCounterValue;
  final double levelMultiplierValue;
  final String flameIconPath;
  final String coinIconPath;
  final String expIconPath;
  final String levelIconPath;

  CuteLittleWidget({
    Key? key,
    required this.flameCounterValue,
    required this.coinCounterValue,
    required this.expCounterValue,
    required this.levelMultiplierValue,
    required this.flameIconPath,
    required this.coinIconPath,
    required this.expIconPath,
    required this.levelIconPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildRow(flameIconPath, flameCounterValue.toStringAsFixed(2)),
        _buildRow(coinIconPath, coinCounterValue.toStringAsFixed(2)),
        _buildRow(expIconPath, expCounterValue.toStringAsFixed(2)),
        _buildRow(levelIconPath, levelMultiplierValue.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildRow(String imagePath, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(imagePath, width: 16, height: 16),
        SizedBox(width: 2), // Small space between icon and text
        Text(value),
      ],
    );
  }
}
