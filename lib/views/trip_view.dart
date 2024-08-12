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
  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  // 列表
  dynamic objs;

  // 路径
  String? path;

  refreshTripList() async {
    path ??= await getApplicationDocumentsDirectoryPath();
    return TripProvider().listTrip();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Expanded(child: tripListWidget()),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget tripListWidget() {
    return FutureBuilder(
      future: refreshTripList(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '欲买桂花同载酒',
                    style: TextStyle(fontSize: 20.0),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '终不似 少年游',
                    style: TextStyle(fontSize: 20.0),
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
            itemCount: snapshot.data.length,
            itemBuilder: _getItem,
          );
        } else {
          return Center(child: CircularProgressIndicator());
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
                  height: 150,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
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
                            icon: Icon(Icons.edit),
                            label: Text('编辑'),
                            style: ElevatedButton.styleFrom(
                              textStyle: TextStyle(fontWeight: FontWeight.bold),
                              backgroundColor: Color(0xFF0392CF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(width: 30),
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
                            icon: Icon(Icons.delete),
                            label: Text('删除'),
                            style: ElevatedButton.styleFrom(
                              textStyle: TextStyle(fontWeight: FontWeight.bold),
                              backgroundColor: Color.fromARGB(255, 205, 50, 36),
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
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            if (item.pic != '') ...[
              Image.file(
                File('$path/${item.pic}'),
              ),
            ] else ...[
              Image(
                image: AssetImage("images/sailimuhu.jpg"),
              ),
            ],
            Container(
              padding: EdgeInsets.all(8),
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
      builder: (context) {
        return AlertDialog(
          title: Text("提示"),
          content: Text(
            "您确定要删除该旅程\n\n$name ？",
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
}

class TripPage extends StatefulWidget {
  const TripPage({
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

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  final ValueNotifier<String> picPath = ValueNotifier<String>('');

  String? path;

  void createTrip(String input) async {
    var trip = Trip(id: widget.id, name: input, pic: picPath.value);
    await TripProvider().insertTrip(trip);
  }

  void updateTrip(String input) async {
    var trip = Trip(id: widget.id, name: input, pic: picPath.value);
    await TripProvider().updateTrip(trip);
  }

  Future getImage() async {
    path ??= await getApplicationDocumentsDirectoryPath();

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (pickedFile != null) {
      pickedFile.saveTo('$path/${pickedFile.name}');
      picPath.value = pickedFile.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    String desc = '新增旅程';
    if (widget.id != null) {
      desc = '修改旅程';
    }

    var nameController = TextEditingController();
    if (widget.name != null) {
      nameController.text = widget.name!;
    }
    if (widget.pic != null) {
      picPath.value = widget.pic!;
    }
    if (widget.path != null) {
      path = widget.path!;
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
                    labelText: '名称',
                    hintText: '请输入名称',
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
                SizedBox(height: 10),

                // image
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.image),
                        label: Text("选择图片"),
                        onPressed: () {
                          getImage();
                        },
                      ),
                      TextButton(
                        child: Text('或使用默认图片', style: TextStyle(color: Colors.grey)),
                        onPressed: () {
                          picPath.value = '';
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                ValueListenableBuilder(
                  valueListenable: picPath,
                  builder: (context, value, child) {
                    if (picPath.value != '') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Image.file(
                          File('$path/${picPath.value}'),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Image(
                          image: AssetImage("images/sailimuhu.jpg"),
                        ),
                      );
                    }
                  },
                ),
                // image

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

                        if (widget.id == null) {
                          createTrip(input);
                        } else {
                          updateTrip(input);
                        }

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage()),
                          (route) => false,
                        );
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
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = TripUserListPage(tripId: widget.tripId);
        break;
      case 1:
        page = TripBillListPage(tripId: widget.tripId);
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.tripName),
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
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '成员'),
            BottomNavigationBarItem(icon: Icon(Icons.feed), label: '流水'),
          ],
        ),
      );
    });
  }
}
