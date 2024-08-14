import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kao_rou_aa/models/trip.dart';
import 'package:kao_rou_aa/services/trip_service.dart';
import 'package:kao_rou_aa/main.dart';
import 'package:kao_rou_aa/views/trip_user_view.dart';
import 'package:kao_rou_aa/views/trip_bill_view.dart';

Future<String> getApplicationDocumentsDirectoryPath() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  Future? tripList;
  dynamic objs; // 列表
  String? path; // 路径

  refreshTripList() async {
    path ??= await getApplicationDocumentsDirectoryPath();
    tripList ??= TripProvider().listTrip();
    return tripList;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: tripListWidget()),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget tripListWidget() {
    return FutureBuilder(
      future: refreshTripList(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '欲买桂花同载酒',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '终不似 少年游',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            );
          }

          objs = snapshot.data;

          // 瀑布流
          return MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: objs.length,
            itemBuilder: _getItem,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _getItem(BuildContext context, index) {
    var item = objs[index];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailPage(
              tripId: item.id,
              tripName: item.name,
            ),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return BottomSheet(
              onClosing: () {},
              builder: (BuildContext context) {
                return SizedBox(
                  height: 120,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TripPage(
                                    id: item.id,
                                    name: item.name,
                                    pic: item.pic,
                                    path: path,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('编辑'),
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 30),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop(); // 关闭
                              bool? delete = await showDeleteConfirmDialog(item.name);
                              if (delete == true) {
                                await TripProvider().deleteTripCascade(item.id);
                                objs.remove(item);
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('删除'),
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              backgroundColor: const Color.fromARGB(255, 205, 50, 36),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            if (item.pic != '') ...[
              Image.file(
                File('$path/${item.pic}'),
              ),
            ] else ...[
              const Image(
                image: AssetImage("images/sailimuhu.jpg"),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.centerLeft,
              child: Text(item.name),
            ),
          ],
        ),
      ),
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
            "您确定要删除该旅程\n\n$name ？",
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
}

class TripPage extends StatelessWidget {
  TripPage({
    super.key,
    this.id,
    this.name,
    this.pic,
    this.path,
  });

  final int? id;
  final String? name;
  final String? pic;
  final String? path;

  final nameController = TextEditingController();
  final picPath = ValueNotifier<String>('');

  void createTrip(String input) async {
    var trip = Trip(id: id, name: input, pic: picPath.value);
    await TripProvider().insertTrip(trip);
  }

  void updateTrip(String input) async {
    var trip = Trip(id: id, name: input, pic: picPath.value);
    await TripProvider().updateTrip(trip);
  }

  @override
  Widget build(BuildContext context) {
    String desc = '新增旅程';
    if (id != null) {
      desc = '修改旅程';
    }

    if (name != null) {
      nameController.text = name!;
    }
    if (pic != null) {
      picPath.value = pic!;
    }
    String? savePath = path;

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
                  labelText: '名称',
                  hintText: '请输入名称',
                  prefixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 10),

              // image
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text("选择图片"),
                    onPressed: () async {
                      savePath ??= await getApplicationDocumentsDirectoryPath();

                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 10);
                      if (pickedFile != null) {
                        pickedFile.saveTo('$savePath/${pickedFile.name}');
                        picPath.value = pickedFile.name;
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('或使用默认图片', style: TextStyle(color: Colors.grey)),
                    onPressed: () {
                      picPath.value = '';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: picPath,
                builder: (context, value, child) {
                  if (picPath.value != '') {
                    return Image.file(
                      File('$savePath/${picPath.value}'),
                    );
                  } else {
                    return const Image(
                      image: AssetImage("images/sailimuhu.jpg"),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              // image

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
                              '请输入名称',
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
                        createTrip(input);
                      } else {
                        updateTrip(input);
                      }

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MyHomePage()),
                        (route) => false,
                      );
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

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  final int tripId;
  final String tripName;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  int selectedIndex = 0;

  bool _refresh = false;
  void _handleRefreshChanged(bool newValue) {
    _refresh = newValue;
    // setState(() {
    //   _refresh = newValue;
    // });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = TripUserListPage(tripId: widget.tripId, refresh: _refresh, onChanged: _handleRefreshChanged);
        break;
      case 1:
        page = TripBillListPage(tripId: widget.tripId, refresh: _refresh, onChanged: _handleRefreshChanged, userId: 0);
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.tripName,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      body: SafeArea(child: page),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: '团员',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed_outlined),
            activeIcon: Icon(Icons.feed),
            label: '流水',
          ),
        ],
        selectedItemColor: const Color.fromARGB(255, 205, 50, 36),
      ),
    );
  }
}
