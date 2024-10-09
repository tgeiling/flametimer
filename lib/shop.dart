import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neumorphic_ui/neumorphic_ui.dart';
import 'package:timer/stats.dart';

import 'main.dart';

import 'sharedFunctions.dart';

class ShopWidget extends StatefulWidget {
  @override
  _ShopWidgetState createState() => _ShopWidgetState();
}

List<ShopItemData> shopItems = [];
List<FireResearchTierData> tiers = [];

class _ShopWidgetState extends State<ShopWidget>
    with AutomaticKeepAliveClientMixin {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    initializeShopItems();
    timer = Timer.periodic(
        Duration(seconds: 1), (Timer t) => initializeShopItems());
  }

  Future<void> loadSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    coinCount = prefs.getInt("coinCount") ?? 0;

    setState(() {});
  }

  void initializeShopItems() async {
    initializeShopItemsFirst();
    initializeResearchItemsFirst();
    await initializeQuestItemsFirst();
    await updateQuestProgress(flameCounter);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/steelpixel.png"), // Your background image
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        children: [
          Stack(children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 60, right: 30),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width / 1.8,
                  ),
                  child: CoinCountDisplay(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 60, left: 30),
                child: Container(
                  height: 40,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width / 2,
                  ),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/frame3.png'), // Replace with your image path
                      fit: BoxFit.fill,
                    ),
                  ),
                  padding: EdgeInsets.all(3),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => EquipDialog(
                          shopItems:
                              shopItems.where((item) => item.isBought).toList(),
                          equipItemCallback: (item) {
                            equipeItemAndSave(item);
                          },
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Image.asset(
                              'assets/icons/plus.png',
                              width: 25,
                              height: 25,
                            )),
                        SizedBox(width: 10),
                        Container(
                          child: Wrap(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 55,
              child: FlameCounterWidget(flameCounter: flameCounter),
            ),
          ]),
          Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ResearchDialog(tiers: tiers),
                      );
                    },
                    child: Neumorphic(
                      padding: EdgeInsets.all(6),
                      margin: EdgeInsets.only(top: 10, left: 35),
                      //child: Image.asset(width: 40, "assets/icons/research.png"),
                      child: Text(
                        "Research",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => QuestDialog(),
                      );
                    },
                    child: QuestsButton(),
                  ),
                ],
              )),
          ExpManagerWidget(
            expCount: expCount,
            level: level,
          ),
          SingleChildScrollView(
            child: ClipRect(
                child: Container(
                    margin: EdgeInsets.only(top: 20, left: 18, right: 18),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/frame5.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    height: MediaQuery.of(context).size.height * 0.58,
                    child: Padding(
                        padding: EdgeInsets.only(
                            left: 14, right: 14, top: 45, bottom: 32),
                        child: ListView.builder(
                          itemCount: shopItems.length,
                          itemBuilder: (context, index) {
                            return ShopItem(
                              itemData: shopItems[index],
                              onBuy: () => buyItem(shopItems[index]),
                            );
                          },
                        )))),
          ),
        ],
      ),
    );
  }

  void buyItem(ShopItemData item) async {
    if (coinCount >= item.price) {
      setState(() {
        coinCount -= item.price;
        item.isBought = true;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coinCount', coinCount);
      await prefs.setBool(item.id, true); // Save the purchased state
    }
  }

  void equipeItem(ShopItemData item) async {
    setState(() {
      item.isEquiped = !item.isEquiped;
    });
  }

  void equipeItemAndSave(ShopItemData item) async {
    final prefs = await SharedPreferences.getInstance();
    if (shopItems.where((item) => item.isEquiped).length == 4) {
      setState(() {
        item.isEquiped = false;
      });
    } else {
      setState(() {
        item.isEquiped = !item.isEquiped;
      });
    }

    print(item.isEquiped);
    await prefs.setBool(item.id + 'Equiped', item.isEquiped);
  }

  void saveEquippedItems() async {
    final prefs = await SharedPreferences.getInstance();
    for (var item in shopItems) {
      await prefs.setBool(item.id + 'Equiped', item.isEquiped);
    }
  }

  Widget CoinCountDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Ensures the Row takes only required space
        children: <Widget>[
          Image.asset(
            'assets/icons/coinStack.png',
            width: 20,
            height: 20,
          ),
          SizedBox(width: 4), // Optional spacing between image and text
          Center(
            child: Text(
              coinCount.toString().padLeft(8, '0'),
              style: TextStyle(
                fontFamily: 'digi',
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ShopItem extends StatelessWidget {
  final ShopItemData itemData;
  final VoidCallback onBuy;

  ShopItem({
    required this.itemData,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final bool isItemBought = itemData.isBought;
    final bool isLevelSufficient = level >= itemData.levelNeeded;

    final TextStyle disabledTextStyle = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
    );

    final TextStyle disabledTextStyleSmall = TextStyle(
      color: Colors.grey,
      fontSize: 12,
    );

    final BoxDecoration disabledDecoration = BoxDecoration(
      color: Colors.grey.shade300,
      border: Border.all(color: Colors.grey.shade500, width: 2),
      borderRadius: BorderRadius.circular(5),
    );

    final BoxDecoration activeDecoration = BoxDecoration(
      color:
          isLevelSufficient ? Colors.grey.shade100 : Colors.deepPurple.shade700,
      border: Border.all(
          color: isLevelSufficient
              ? Colors.grey.shade700
              : Colors.deepPurple.shade900,
          width: 2),
      borderRadius: BorderRadius.circular(5),
    );

    final TextStyle levelTextStyle = TextStyle(
        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold);

    return Container(
      margin: EdgeInsets.only(right: 14, top: 8, left: 14, bottom: 8),
      decoration: isItemBought ? disabledDecoration : activeDecoration,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Image container
            Container(
              width: 75,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/woodframe.png'),
                  fit: BoxFit.fill,
                  colorFilter: isItemBought
                      ? ColorFilter.mode(Colors.grey, BlendMode.saturation)
                      : null,
                ),
              ),
              child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Container(
                    child: Image.asset(
                      itemData.imagePath,
                      fit: BoxFit.scaleDown,
                    ),
                  )),
            ),
            // Item title and description
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      itemData.title,
                      style: isItemBought
                          ? disabledTextStyle
                          : TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      itemData.description,
                      style: isItemBought
                          ? disabledTextStyleSmall
                          : TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
// Price and Buy button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Image.asset(
                        "assets/icons/coin.png",
                        width: 20,
                        height: 20,
                        color: isItemBought ? Colors.grey : null,
                      ),
                      SizedBox(width: 4),
                      Text(
                        itemData.price.toString(),
                        style: isItemBought ? disabledTextStyle : TextStyle(),
                      ),
                    ],
                  ),
                  if (!isItemBought && !isLevelSufficient)
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Level ${itemData.levelNeeded}',
                        style: levelTextStyle,
                      ),
                    ),
                  if (!isItemBought && isLevelSufficient)
                    ElevatedButton(
                      onPressed: onBuy,
                      child: Text('Buy'),
                    ),
                ],
              ),
            ),
// Level Requirement Display
          ],
        ),
      ),
    );
  }
}

class EquipDialog extends StatefulWidget {
  final List<ShopItemData> shopItems;
  final Function(ShopItemData) equipItemCallback;

  EquipDialog({required this.shopItems, required this.equipItemCallback});

  @override
  _EquipDialogState createState() => _EquipDialogState();
}

class _EquipDialogState extends State<EquipDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Equip Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              'You can only equip 4 items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Divider(),
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.68,
              padding: EdgeInsets.only(left: 8, right: 8),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.shopItems.length,
                itemBuilder: (context, index) {
                  final item = widget.shopItems[index];
                  return InkWell(
                    onTap: () {
                      if (shopItems.where((item) => item.isEquiped).length <=
                          4) {
                        setState(() {
                          widget.equipItemCallback(item);
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: item.isEquiped ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            item.imagePath,
                            width: 50,
                            height: 50,
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(item.description,
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            item.isEquiped
                                ? Icons.check_circle_outline
                                : Icons.circle_outlined,
                            color: item.isEquiped ? Colors.green : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ShopItemData {
  final String id;
  final String title;
  final String description;
  final int price;
  final String imagePath;
  bool isBought;
  bool isEquiped;
  double flameMultiplier;
  double coinMultiplier;
  double expMultiplier;
  int levelNeeded;

  ShopItemData({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imagePath,
    this.isEquiped = false,
    this.isBought = false,
    this.flameMultiplier = 0.0,
    this.coinMultiplier = 0.0,
    this.expMultiplier = 0.0,
    required this.levelNeeded,
  });

  // Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imagePath': imagePath,
      'isBought': isBought,
      'isEquiped': isEquiped,
      'flameMultiplier': flameMultiplier,
      'coinMultiplier': coinMultiplier,
      'expMultiplier': expMultiplier,
      'levelNeeded': levelNeeded,
    };
  }

  // Add fromMap factory constructor
  factory ShopItemData.fromMap(Map<String, dynamic> map) {
    return ShopItemData(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      price: map['price'],
      imagePath: map['imagePath'],
      isBought: map['isBought'] ?? false,
      isEquiped: map['isEquiped'] ?? false,
      flameMultiplier: map['flameMultiplier']?.toDouble() ?? 0.0,
      coinMultiplier: map['coinMultiplier']?.toDouble() ?? 0.0,
      expMultiplier: map['expMultiplier']?.toDouble() ?? 0.0,
      levelNeeded: map['levelNeeded'],
    );
  }
}

class ExpManagerWidget extends StatelessWidget {
  final int expCount;
  final int level;

  ExpManagerWidget({Key? key, required this.expCount, required this.level})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int nextGoal =
        level < expGoals.length ? expGoals[level - 1] : expGoals.last;
    double progress = expCount / nextGoal;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.topRight,
            child: Text(
              'Level $level',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'digi'),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              NeumorphicProgress(
                height: 20,
                style: ProgressStyle(
                  depth: 2,
                  accent: Colors.blue,
                  variant: Colors.blueGrey,
                ),
                percent: progress,
              ),
              Text(
                '$expCount/$nextGoal',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ResearchDialog extends StatefulWidget {
  final List<FireResearchTierData> tiers;

  ResearchDialog({required this.tiers});

  @override
  _ResearchDialogState createState() => _ResearchDialogState();
}

class _ResearchDialogState extends State<ResearchDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Padding(
      padding: EdgeInsets.only(left: 12, right: 12),
      child: Container(height: 500, child: FireResearchScreen()),
    ));
  }
}

class FireResearchTierData {
  final int tier;
  final int levelToUnlock;
  final List<FireResearchItem> researchItems;

  FireResearchTierData({
    required this.tier,
    required this.levelToUnlock,
    required this.researchItems,
  });
}

class FireResearchItem {
  final String type;
  double multiplier;
  int progress;
  String prefKey;
  String imageAsset;
  String description;
  int price;
  final int maxProgress = 100;

  FireResearchItem({
    required this.type,
    required this.multiplier,
    this.progress = 0,
    required this.prefKey,
    required this.imageAsset,
    required this.description,
    required this.price,
  });

  void incrementProgress() async {
    if (progress < maxProgress && coinCount >= price) {
      coinCount -= price;
      progress++;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefKey, progress);
  }
}

class FireResearchTier extends StatefulWidget {
  final FireResearchTierData tierData;
  final VoidCallback onResearch;

  FireResearchTier({required this.tierData, required this.onResearch});

  @override
  _FireResearchTierState createState() => _FireResearchTierState();
}

class _FireResearchTierState extends State<FireResearchTier> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel(); // Ensure any active timers are cancelled
    super.dispose();
  }

  void startBuying(FireResearchItem item, Function onResearch) {
    _timer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      setState(() {
        item.incrementProgress();
      });
    });
  }

  void stopBuying() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    bool isTierUnlocked = level >= widget.tierData.levelToUnlock;

    TextStyle textStyle = isTierUnlocked
        ? TextStyle(fontSize: 16)
        : TextStyle(fontSize: 16, color: Colors.grey);

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border.all(color: isTierUnlocked ? Colors.green : Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Tier ${widget.tierData.tier}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isTierUnlocked ? Colors.black : Colors.grey)),
          if (!isTierUnlocked)
            Text(
              'Unlocked at level ${widget.tierData.levelToUnlock}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ...widget.tierData.researchItems.map((item) => Row(
                children: [
                  Image.asset(width: 40, item.imageAsset),
                  Expanded(
                      child: Container(
                    padding: EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.type} Research', style: textStyle),
                        Text(item.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text("${item.progress}/${item.maxProgress}"),
                        NeumorphicProgress(
                          height: 20,
                          style: ProgressStyle(
                              depth: 2,
                              accent: Colors.blue,
                              variant: Colors.blueGrey),
                          percent: item.progress / item.maxProgress,
                        ),
                      ],
                    ),
                  )),
                  SizedBox(width: 14),
                  GestureDetector(
                    onTap: isTierUnlocked
                        ? () {
                            // Single tap action
                            setState(() {
                              item.incrementProgress();
                            });
                          }
                        : null,
                    onLongPress: isTierUnlocked
                        ? () {
                            startBuying(item, widget.onResearch);
                          }
                        : null,
                    onLongPressUp: () => stopBuying(),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isTierUnlocked ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/icons/coin.png', width: 10),
                          SizedBox(width: 4),
                          Text("${item.price}"),
                        ],
                      ),
                    ),
                  )
                ],
              )),
        ],
      ),
    );
  }
}

class FireResearchScreen extends StatefulWidget {
  @override
  _FireResearchScreenState createState() => _FireResearchScreenState();
}

class _FireResearchScreenState extends State<FireResearchScreen> {
  void onResearch() {
    if (mounted) {
      setState(() {}); // Ensure setState is only called if mounted
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Fire Research',
            style: TextStyle(fontSize: 34, fontFamily: 'digi')),
        Expanded(
          child: ListView.builder(
            itemCount: tiers.length,
            itemBuilder: (context, index) {
              return FireResearchTier(
                  tierData: tiers[index], onResearch: onResearch);
            },
          ),
        ),
      ],
    );
  }
}

class QuestDialog extends StatefulWidget {
  @override
  _QuestDialogState createState() => _QuestDialogState();
}

class _QuestDialogState extends State<QuestDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start a timer that updates every second
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int _getSortKey(QuestItem quest) {
      if (quest.isDone && !quest.isRewardTaken) {
        return 0;
      } else if (!quest.isDone) {
        return 1;
      } else {
        return 2;
      }
    }

    List<QuestItem> sortedQuestItems = List.from(questItems)
      ..sort((a, b) {
        int sortKeyA = _getSortKey(a);
        int sortKeyB = _getSortKey(b);
        return sortKeyA.compareTo(sortKeyB);
      });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quests', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedQuestItems.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: QuestItemWidget(
                        quest: sortedQuestItems[index],
                        onClaimReward: () {
                          if (sortedQuestItems[index].isDone &&
                              !sortedQuestItems[index].isRewardTaken) {
                            _showClaimRewardDialog(
                                context, sortedQuestItems[index], () {
                              setState(
                                  () {}); // Refresh the UI after claiming a reward
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateRewardTakenState(QuestItem quest, bool isTaken) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if the quest has an item reward
    if (quest.rewardItem != null) {
      ShopItemData rewardItem = quest.rewardItem!;

      // Find the item in shopItems and update its isBought property
      int itemIndex = shopItems.indexWhere((item) => item.id == rewardItem.id);
      if (itemIndex != -1) {
        shopItems[itemIndex].isBought = true;
        await prefs.setBool(rewardItem.id, true); // Save the purchased state
      } else {
        // If the item is not found, add it to shopItems
        shopItems.add(rewardItem);
        await prefs.setBool(rewardItem.id, true); // Save the purchased state
      }
    }

    // Update coin count if the quest has a gold reward
    if (quest.isGoldReward && quest.goldValue != null) {
      coinCount += quest.goldValue!;
      await prefs.setInt('coinCount', coinCount); // Save updated coin count
    }

    // Update the quest's isRewardTaken state
    int questIndex = questItems.indexWhere((q) => q.id == quest.id);
    if (questIndex != -1) {
      questItems[questIndex].isRewardTaken = isTaken;
    }

    // Save the updated quests list to SharedPreferences
    await saveQuestsToPreferences();

    // Save the updated shop items
    await saveShopItemsToPreferences();
  }

  void _showClaimRewardDialog(
      BuildContext context, QuestItem quest, VoidCallback onClaimed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Claim Reward"),
          content: Text(
              "Would you like to claim your reward for completing '${quest.title}'?"),
          actions: <Widget>[
            TextButton(
              child: Text('Claim!'),
              onPressed: () async {
                // Update the reward taken state and await its completion
                await _updateRewardTakenState(quest, true);

                Navigator.of(context).pop(); // Close the dialog
                onClaimed(); // Callback to refresh the UI
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
            ),
          ],
        );
      },
    );
  }
}

class QuestItemWidget extends StatelessWidget {
  final QuestItem quest;
  final VoidCallback? onClaimReward; // Optional callback for claiming rewards

  QuestItemWidget({required this.quest, this.onClaimReward});

  @override
  Widget build(BuildContext context) {
    bool isLevelMet = level >=
        quest
            .level; // Ensure 'level' is defined in your scope or passed to the widget

    return Opacity(
      opacity: quest.isRewardTaken ? 0.5 : 1.0, // Grey out if reward is taken
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:
              quest.isDone ? Border.all(color: Colors.green, width: 2) : null,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300, spreadRadius: 1, blurRadius: 5)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(quest.title,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (quest.isDone && !quest.isRewardTaken)
                  GestureDetector(
                    onTap:
                        onClaimReward, // Use the provided callback to claim the reward
                    child: Icon(Icons.card_giftcard,
                        color: Colors.blue), // Icon to indicate claiming reward
                  )
                else if (quest.isDone)
                  Icon(Icons.check_circle,
                      color: Colors.green), // Indicate completed quest
              ],
            ),
            SizedBox(height: 4),
            Text(quest.description,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 4),
            Text("${quest.progress}/${quest.maxValue}",
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 8),
            NeumorphicProgress(
              percent: quest.progress / quest.maxValue,
              style: ProgressStyle(
                depth: 4,
                border: NeumorphicBorder.none(),
                accent: Colors.blue,
                variant: Colors.blue.shade200,
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showRewardDialog(context, quest),
              child: Row(
                children: [
                  quest.isGoldReward
                      ? Image.asset('assets/icons/coin.png', width: 24)
                      : Image.asset(quest.itemImagePath ?? '', width: 24),
                  SizedBox(width: 4),
                  Text(quest.rewardValue),
                ],
              ),
            ),
            if (!isLevelMet)
              Text('Requires level ${quest.level}',
                  style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _showRewardDialog(BuildContext context, QuestItem quest) {
    if (!quest.isGoldReward && quest.rewardDescription != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(quest.rewardValue),
            content: Text(quest.rewardDescription!),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}

class QuestsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Calculate the number of quests that are done but not claimed
    int unclaimedQuests = questItems
        .where((quest) => quest.isDone && !quest.isRewardTaken)
        .length;

    return Stack(
      clipBehavior: Clip.none, // Allow overflow to show the badge properly
      children: [
        Neumorphic(
          padding: EdgeInsets.all(6),
          margin: EdgeInsets.only(top: 10, left: 5),
          child: Text(
            "Quests",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        if (unclaimedQuests > 0)
          Positioned(
            // Adjust position as needed
            right: -5,
            top: -5,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unclaimedQuests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
