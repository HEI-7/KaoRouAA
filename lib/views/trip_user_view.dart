import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:kao_rou_aa/models/trip_user.dart';
import 'package:kao_rou_aa/services/trip_service.dart';

class TripUserListPage extends StatefulWidget {
  const TripUserListPage({
    super.key,
    required this.tripId,
  });

  final int tripId;

  @override
  State<TripUserListPage> createState() => _TripUserListPageState();
}

class _TripUserListPageState extends State<TripUserListPage> {
  Future? tripUserList;
  double payAct = 0.00;
  bool refresh = false;

  refreshTripUserList() async {
    // 计算
    // if (refresh) {
    //   await TripProvider().calculateTripBillToUser(widget.tripId);
    // }
    await TripProvider().calculateTripBillToUser(widget.tripId);
    payAct = await TripProvider().queryTripPay(widget.tripId);
    tripUserList = TripProvider().listTripUser(widget.tripId);

    // refresh = false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refreshTripUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                iconSize: 35,
                icon: Icon(Icons.add_box),
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
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 240, 233, 233),
              ),
              child: tripUserListWidget(),
            ),
          ),
          // SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget tripUserListWidget() {
    return FutureBuilder(
      future: tripUserList,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && !refresh) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: const Text(
                '暂时没有成员',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data.length + 1,
            itemBuilder: (context, index) {
              if (index == snapshot.data.length) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '总计 ${payAct.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18),
                        ),
                        // IconButton(
                        //   iconSize: 35,
                        //   icon: Icon(Icons.refresh),
                        //   onPressed: () async {
                        //     refresh = true;
                        //     setState(() {});
                        //     await refreshTripUserList();
                        //   },
                        // ),
                      ],
                    ),
                  ),
                );
              }

              var item = snapshot.data[index];
              var border = Border();
              if (index < snapshot.data.length - 1) {
                border = Border(bottom: BorderSide(color: Colors.grey, width: 0.5));
              }
              return Slidable(
                key: ValueKey(index),
                endActionPane: ActionPane(
                  motion: ScrollMotion(),
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
                      backgroundColor: Color(0xFFFE4A49),
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
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        child: Image.asset('images/${item.avatar}'),
                      ),
                      // SizedBox(width: 20),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: border,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 7.0, top: 12.0, bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
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
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<bool?> showDeleteConfirmDialog(String name) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return AlertDialog(
          title: Text("提示"),
          content: Text(
            "您确定要删除该成员\n\n$name ？",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("取消"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text("删除"),
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
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('注意'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('该成员存在 AA 流水!'),
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
  final List avatars = [
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
  final ValueNotifier<String> avatarPick = ValueNotifier<String>('');

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
    String desc = '新增成员';
    if (id != null) {
      desc = '修改成员';
    }

    var nameController = TextEditingController();
    if (name != null) {
      nameController.text = name!;
    }
    if (avatar != null) {
      avatarPick.value = avatar!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(desc),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                TextField(
                  maxLength: 20,
                  // autofocus: true,
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '昵称',
                    hintText: '请输入昵称',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 10),

                // avatar
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '选择头像',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 205, 50, 36),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  child: ValueListenableBuilder(
                    valueListenable: avatarPick,
                    builder: (context, value, child) {
                      return GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.0,
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
                ),
                // avatar

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 113, 111, 111),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('取消'),
                    ),
                    SizedBox(width: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 10, 132, 10),
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
                      child: Text('确认'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
