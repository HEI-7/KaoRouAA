import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:kao_rou_aa/models/trip_user.dart';
import 'package:kao_rou_aa/services/trip_service.dart';

class TripUserListPage extends StatefulWidget {
  const TripUserListPage({
    super.key,
    required this.tripId,
    required this.refresh,
    required this.onChanged,
  });

  final int tripId;
  final bool refresh;
  final ValueChanged<bool> onChanged;

  @override
  State<TripUserListPage> createState() => _TripUserListPageState();
}

class _TripUserListPageState extends State<TripUserListPage> {
  Future? tripUserList;
  double payAct = 0.00;
  // bool refresh = false;

  refreshTripUserList() async {
    print(widget.refresh);

    // 计算
    // if (refresh) {
    //   await TripProvider().calculateTripBillToUser(widget.tripId);
    // }
    await TripProvider().calculateTripBillToUser(widget.tripId);
    payAct = await TripProvider().queryTripPay(widget.tripId);
    tripUserList = TripProvider().listTripUser(widget.tripId);

    widget.onChanged(!widget.refresh);

    print(1);
    // refresh = false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    print(0);
    refreshTripUserList();
  }

  void _handleTap() {
    widget.onChanged(!widget.refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: tripUserListWidget()),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton.small(
              elevation: 1,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TripUserPage(tripId: widget.tripId)),
                ).then((refreshFlag) {
                  if (refreshFlag == true) {
                    refreshTripUserList();
                  }
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget tripUserListWidget() {
    return FutureBuilder(
      future: tripUserList,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '暂时没有团员',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data.length + 1,
            itemBuilder: (context, index) {
              if (index == snapshot.data.length) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        '总计 ${payAct.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }

              var item = snapshot.data[index];
              var border = const Border(bottom: BorderSide(color: Colors.grey, width: 0.5));
              if (index == snapshot.data.length - 1) {
                border = const Border();
              }
              return Slidable(
                key: ValueKey(index),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.2,
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                        bool? delete = await showDeleteConfirmDialog(item.name);
                        if (delete == true) {
                          if (await TripProvider().deleteTripUserCascade(item.id)) {
                            snapshot.data.remove(item);
                            setState(() {});
                          } else {
                            _showErrorDialog();
                          }
                        }
                      },
                      backgroundColor: Colors.red,
                      icon: Icons.delete,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripUserPage(
                          tripId: widget.tripId,
                          id: item.id,
                          name: item.name,
                          avatar: item.avatar,
                        ),
                      ),
                    ).then((refreshFlag) {
                      if (refreshFlag == true) {
                        refreshTripUserList();
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Image.asset(
                          'images/${item.avatar}',
                          width: 45,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: border,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 7, top: 12, bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text("应付 ${item.pay.toStringAsFixed(2)}，实付 ${item.payAct.toStringAsFixed(2)}"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<bool?> showDeleteConfirmDialog(String name) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "提示",
            style: TextStyle(fontSize: 20),
          ),
          content: Text(
            "您确定要删除该团员\n\n$name ？",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                "删除",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '注意',
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('该团员存在 AA 流水!'),
                SizedBox(height: 10),
                Text('请修改相关流水后再删除!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('确认'),
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

class TripUserPage extends StatelessWidget {
  TripUserPage({
    super.key,
    required this.tripId,
    this.id,
    this.name,
    this.avatar,
  });

  final int tripId;
  final int? id;
  final String? name;
  final String? avatar;

  final avatars = [
    'p1.png',
    'p2.png',
    'p3.png',
    'p4.png',
    'p5.png',
    'p6.png',
    'p7.png',
    'p8.png',
    'p9.png',
    'p10.png',
    'p11.png',
    'p12.png',
  ];
  final avatarPick = ValueNotifier<String>('');
  final nameController = TextEditingController();

  void createTripUser(String input) async {
    var tripUser = TripUser(id: id, tripId: tripId, name: input, avatar: avatarPick.value);
    await TripProvider().insertTripUser(tripUser);
  }

  void updateTripUser(String input) async {
    var tripUser = TripUser(id: id, tripId: tripId, name: input, avatar: avatarPick.value);
    await TripProvider().updateTripUser(tripUser);
  }

  @override
  Widget build(BuildContext context) {
    String desc = '新增团员';
    if (id != null) {
      desc = '修改团员';
    }

    if (name != null) {
      nameController.text = name!;
    }
    if (avatar != null) {
      avatarPick.value = avatar!;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          desc,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              TextField(
                maxLength: 20,
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  hintText: '请输入昵称',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),

              // avatar
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text("选择头像"),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: avatarPick,
                builder: (context, value, child) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(0),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      // mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: avatars.length,
                    itemBuilder: (context, index) {
                      if (avatarPick.value == avatars[index]) {
                        return GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Image.asset('images/${avatarPick.value}'),
                          ),
                        );
                      } else {
                        return GestureDetector(
                          onTap: () {
                            avatarPick.value = avatars[index];
                          },
                          child: Image.asset('images/${avatars[index]}'),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              // avatar

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      String input = nameController.text;
                      if (input == '') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '请输入昵称',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            backgroundColor: Color.fromARGB(255, 205, 50, 36),
                            duration: Durations.long3,
                          ),
                        );
                        return;
                      }
                      if (avatarPick.value == '') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '请选择头像',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            backgroundColor: Color.fromARGB(255, 205, 50, 36),
                            duration: Durations.long3,
                          ),
                        );
                        return;
                      }

                      if (id == null) {
                        createTripUser(input);
                      } else {
                        updateTripUser(input);
                      }
                      Navigator.pop(context, true);
                    },
                    child: const Text('确认'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
