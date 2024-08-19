import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kao_rou_aa/models/trip_user.dart';
import 'package:kao_rou_aa/models/trip_bill.dart';
import 'package:kao_rou_aa/models/trip_bill_detail.dart';
import 'package:kao_rou_aa/services/trip_service.dart';

class TripBillListPage extends StatefulWidget {
  const TripBillListPage({
    super.key,
    required this.tripId,
    required this.userId,
    required this.refresh,
    required this.onChanged,
  });

  final int tripId;
  final int userId;
  final bool refresh;
  final ValueChanged<bool> onChanged;

  @override
  State<TripBillListPage> createState() => _TripBillListPageState();
}

class _TripBillListPageState extends State<TripBillListPage> {
  Map<int, String>? _userMap;
  Map<int, String>? _avatarMap;
  Future? tripBillList;
  Future? tripUserList;
  final List _userList = [];

  int choiceUserId = 0;
  bool firstScroll = true;
  GlobalKey k = GlobalKey();

  refreshTripBillList(int userId) async {
    if (_userList.isEmpty) {
      tripUserList = TripProvider().listTripUser(widget.tripId);
      for (final userObj in await tripUserList) {
        _userList.add(TripUser(id: userObj.id, name: userObj.name, avatar: userObj.avatar));
      }
      _userMap ??= {for (var obj in _userList) obj.id: obj.name};
      _avatarMap ??= {for (var obj in _userList) obj.id: obj.avatar};
    }

    tripBillList = TripProvider().listTripBill(widget.tripId, userId);
    setState(() {
      choiceUserId = userId;
    });
  }

  @override
  void initState() {
    super.initState();
    refreshTripBillList(widget.userId);
  }

  funcAAUserNameString(String aaUsers) {
    if (aaUsers == '') {
      return '';
    }

    var aaUserIdList = aaUsers.split(',');
    var aaUserNameList = aaUserIdList.map((userId) {
      return _userMap![int.parse(userId)];
    }).toList();
    return aaUserNameList.join('，');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: tripUserList,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox();
            }

            if (choiceUserId != 0 && firstScroll) {
              firstScroll = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Scrollable.ensureVisible(k.currentContext!, duration: const Duration(seconds: 1));
              });
            }

            return Padding(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: Row(
                children: [
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          return choiceUserId == 0 ? const Color.fromARGB(255, 129, 201, 132) : null;
                        },
                      ),
                    ),
                    child: const Text('全部'),
                    onPressed: () {
                      if (choiceUserId != 0) {
                        refreshTripBillList(0);
                      }
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _userList.map<TextButton>((obj) {
                          return TextButton(
                            key: obj.id == choiceUserId ? k : null,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  return choiceUserId == obj.id ? const Color.fromARGB(255, 129, 201, 132) : null;
                                },
                              ),
                            ),
                            child: Text(obj.name),
                            onPressed: () {
                              if (choiceUserId != obj.id) {
                                refreshTripBillList(obj.id);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(child: tripBillListWidget()),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton.small(
              elevation: 1,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripBillPage(
                      tripId: widget.tripId,
                      userId: choiceUserId == 0 ? null : choiceUserId,
                    ),
                  ),
                ).then((refreshFlag) {
                  if (refreshFlag != null) {
                    if (widget.refresh) {
                      widget.onChanged(false);
                    }
                    refreshTripBillList(choiceUserId == 0 ? 0 : refreshFlag[1]);
                  }
                });
              },
              backgroundColor: Colors.lightBlue,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget tripBillListWidget() {
    return FutureBuilder(
      future: tripBillList,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '暂时没有流水',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setListState) {
              return ListView.builder(
                itemCount: snapshot.data.length + 1,
                itemBuilder: (context, index) {
                  if (index == snapshot.data.length) {
                    if (index > 4) {
                      return const Padding(
                        padding: EdgeInsets.all(15),
                        child: Center(
                          child: Text(
                            '已经是最后一笔了',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }

                  var item = snapshot.data[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripBillPage(
                            tripId: widget.tripId,
                            id: item.id,
                            userId: item.userId,
                            pay: item.pay,
                            date: item.date,
                            type: item.type,
                            remark: item.remark,
                            aaUsers: item.aaUsers,
                          ),
                        ),
                      ).then((refreshFlag) {
                        if (refreshFlag != null) {
                          if (widget.refresh) {
                            widget.onChanged(false);
                          }
                          refreshTripBillList(choiceUserId == 0 ? 0 : refreshFlag[1]);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              children: [
                                Image.asset(
                                  'images/${_avatarMap![item.userId]}',
                                  width: 40,
                                ),
                                Text(
                                  _userMap![item.userId]!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.date,
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '¥ ${item.pay.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(item.type),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.remark,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.only(top: 7),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(color: Colors.grey, width: 0.5),
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          '${funcAAUserNameString(item.aaUsers)}',
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 118, 112, 112),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
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
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class TripBillPage extends StatefulWidget {
  const TripBillPage({
    super.key,
    required this.tripId,
    this.id,
    this.userId,
    this.pay,
    this.date,
    this.type,
    this.remark,
    this.aaUsers,
  });

  final int tripId;
  final int? id;
  final int? userId; // 付款
  final double? pay; // 金额
  final String? date; // 日期
  final String? type; // 分类
  final String? remark; // 备注
  final String? aaUsers; // 用户

  @override
  State<TripBillPage> createState() => _TripBillPageState();
}

class _TripBillPageState extends State<TripBillPage> {
  bool _oneMore = false;
  int? _selectUserId; // 付款
  String? _selectType; // 分类
  List<int> _selectUserAA = []; // 用户
  final List<String> types = [
    '餐饮',
    '住宿',
    '出行',
    '游玩',
    '其他',
  ];

  // 用户
  Future? tripUserList;
  refreshTripUserList() async {
    tripUserList ??= TripProvider().listTripUser(widget.tripId);
    return tripUserList;
  }

  void createTripBill(String payInput, String datePicker, String remarkInput) async {
    var tripBill = TripBill(
      // id: widget.id,
      tripId: widget.tripId,
      userId: _selectUserId,
      pay: double.parse(payInput),
      date: datePicker,
      type: _selectType,
      remark: remarkInput,
      aaUsers: _selectUserAA.join(','),
    );

    var id = await TripProvider().insertTripBill(tripBill);
    updateTripBillDetail(id, double.parse(payInput));
  }

  void updateTripBill(String payInput, String datePicker, String remarkInput) async {
    var tripBill = TripBill(
      id: widget.id,
      tripId: widget.tripId,
      userId: _selectUserId,
      pay: double.parse(payInput),
      date: datePicker,
      type: _selectType,
      remark: remarkInput,
      aaUsers: _selectUserAA.join(','),
    );

    await TripProvider().updateTripBill(tripBill);
    if (widget.aaUsers != _selectUserAA.join(',') || widget.pay != double.parse(payInput)) {
      updateTripBillDetail(widget.id!, double.parse(payInput));
    }
  }

  // 创建 更新 明细
  void updateTripBillDetail(int billId, double pay) async {
    double payAA = pay / _selectUserAA.length; // 平摊
    List<TripBillDetail> objs = _selectUserAA.map<TripBillDetail>((int userId) {
      return TripBillDetail(
        billId: billId,
        userId: userId,
        pay: payAA,
      );
    }).toList();

    await TripProvider().batchTripBillDetail(billId, objs);
  }

  // 删除
  Future<bool?> showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "提示",
            style: TextStyle(fontSize: 20),
          ),
          content: const Text(
            "您确定要删除该笔流水 ？",
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

  var payController = TextEditingController(); // 金额
  var dateController = TextEditingController(); // 日期
  var remarkController = TextEditingController(); // 备注

  @override
  Widget build(BuildContext context) {
    String desc = '新增流水';
    if (widget.id != null && !_oneMore) {
      desc = '修改流水';
    }

    if (widget.pay != null && !_oneMore) {
      payController.text = widget.pay!.toStringAsFixed(2);
    }
    if (widget.date != null && !_oneMore) {
      dateController.text = widget.date!;
    }
    if (widget.remark != null && !_oneMore) {
      remarkController.text = widget.remark!;
    }
    if (widget.aaUsers != null && widget.aaUsers != '' && !_oneMore) {
      _selectUserAA = widget.aaUsers!.split(',').map(int.parse).toList();
    }
    if (!_oneMore) {
      _selectUserId = widget.userId;
      _selectType = widget.type;
    }

    bool saveOrUpdate() {
      String payInput = payController.text;
      String datePicker = dateController.text;
      String remarkInput = remarkController.text;
      if (_selectUserId == null || payInput == '' || datePicker == '' || _selectType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '信息请填写完整',
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
        return false;
      }
      if (double.parse(payInput) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '请输入一个合理金额',
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
        return false;
      }
      if (_selectUserAA.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '请至少选择一个用户',
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
        return false;
      }
      _selectUserAA.sort();

      if (widget.id == null || _oneMore) {
        createTripBill(payInput, datePicker, remarkInput);
      } else {
        updateTripBill(payInput, datePicker, remarkInput);
      }
      return true;
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
          child: FutureBuilder(
            future: refreshTripUserList(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      '\n\n请先返回添加团员\n\n',
                      style: TextStyle(fontSize: 20),
                    ),
                  );
                }

                return Column(
                  children: [
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return DropdownButtonFormField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            labelText: '团员',
                          ),
                          hint: const Text('请选择付款人'),
                          items: snapshot.data.map<DropdownMenuItem<int>>((TripUser tripUser) {
                            return DropdownMenuItem(
                              value: tripUser.id,
                              child: Text(tripUser.name),
                            );
                          }).toList(),
                          value: _selectUserId,
                          onChanged: (newValue) {
                            setState(() {
                              _selectUserId = newValue;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLength: 10,
                      controller: payController,
                      decoration: const InputDecoration(
                        labelText: '金额',
                        hintText: '请输入金额',
                        prefixIcon: Icon(Icons.money),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: '日期',
                        hintText: '请选择日期',
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      onTap: () async {
                        var dateNow = DateTime.now();
                        if (dateController.text != '') {
                          dateNow = DateTime.parse(dateController.text);
                        }

                        final result = await showDatePicker(
                          context: context,
                          initialDate: dateNow,
                          firstDate: DateTime(2020, 01),
                          lastDate: DateTime(2050, 12),
                          locale: const Locale('zh'),
                        );
                        if (result != null) {
                          dateController.text = result.toString().substring(0, 10);
                        }
                      },
                      readOnly: true,
                    ),
                    const SizedBox(height: 10),
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return DropdownButtonFormField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category),
                            labelText: '类型',
                          ),
                          hint: const Text('请选择类型'),
                          items: types.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          value: _selectType,
                          onChanged: (newValue) {
                            setState(() {
                              _selectType = newValue;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLength: 20,
                      controller: remarkController,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '请输入备注（选填）',
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.person_add),
                                label: const Text("选择 AA 的团员"),
                                onPressed: () {},
                              ),
                              TextButton(
                                child: const Text('全选', style: TextStyle(color: Colors.blue)),
                                onPressed: () {
                                  _selectUserAA = [];
                                  for (final obj in snapshot.data) {
                                    _selectUserAA.add(obj.id);
                                  }
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            padding: const EdgeInsets.all(0),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: snapshot.data.length,
                            itemBuilder: (context, index) {
                              if (_selectUserAA.contains(snapshot.data[index].id)) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectUserAA.remove(snapshot.data[index].id);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('images/${snapshot.data[index].avatar}'),
                                        Text(snapshot.data[index].name),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectUserAA.add(snapshot.data[index].id);
                                    });
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('images/${snapshot.data[index].avatar}'),
                                      Text(snapshot.data[index].name),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.id != null && !_oneMore) ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              backgroundColor: const Color.fromARGB(255, 205, 50, 36),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              bool? delete = await showDeleteConfirmDialog();
                              if (delete == true) {
                                await TripProvider().deleteTripBillCascade(widget.id!);
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.pop(context, [true, _selectUserId]);
                              }
                            },
                            child: const Text('删除'),
                          ),
                          const SizedBox(width: 20),
                        ],
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (saveOrUpdate()) {
                              Navigator.pop(context, [true, _selectUserId]);
                            }
                          },
                          child: const Text('确认'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (saveOrUpdate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '保存成功',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Durations.long3,
                                ),
                              );

                              setState(() {
                                payController.text = '';
                                remarkController.text = '';
                                _oneMore = true;
                              });
                            }
                          },
                          child: const Text('保存并再记一笔'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}
