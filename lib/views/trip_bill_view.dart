import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:kao_rou_aa/models/trip_user.dart';
import 'package:kao_rou_aa/models/trip_bill.dart';
import 'package:kao_rou_aa/models/trip_bill_detail.dart';
import 'package:kao_rou_aa/services/trip_service.dart';

Future<Map<int, String>> getTripUserMap(int tripId) async {
  List tripUserList = await TripProvider().listTripUser(tripId);
  return {for (var obj in tripUserList) obj.id: obj.name};
}

class TripBillListPage extends StatefulWidget {
  const TripBillListPage({
    super.key,
    required this.tripId,
  });

  final int tripId;

  @override
  State<TripBillListPage> createState() => _TripBillListPageState();
}

class _TripBillListPageState extends State<TripBillListPage> {
  Map<int, String>? _userMap;
  Future? tripBillList;

  refreshTripBillList() async {
    _userMap ??= await getTripUserMap(widget.tripId);
    tripBillList = TripProvider().listTripBill(widget.tripId, 0);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refreshTripBillList();
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
                    MaterialPageRoute(builder: (context) => TripBillPage(tripId: widget.tripId)),
                  ).then((refreshFlag) {
                    refreshTripBillList();
                    // if (refreshFlag == true) {
                    //   refreshTripBillList();
                    // }
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
              child: tripBillListWidget(),
            ),
          ),
          // SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget tripBillListWidget() {
    return FutureBuilder(
      future: tripBillList,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: const Text(
                '暂时没有流水',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data.length + 1,
            itemBuilder: (context, index) {
              if (index == snapshot.data.length) {
                if (index > 4) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 15.0),
                    child: Center(
                      child: Text(
                        '已经是最后一笔了',
                        style: TextStyle(
                          color: Color.fromARGB(255, 118, 112, 112),
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox();
                }
              }

              var item = snapshot.data[index];
              return Container(
                margin: EdgeInsets.only(bottom: 10.0),
                child: Slidable(
                  key: ValueKey(index),
                  endActionPane: ActionPane(
                    motion: ScrollMotion(),
                    extentRatio: 0.2,
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          String payString = item.pay.toStringAsFixed(2);
                          String desc = '${_userMap![item.userId]}在${item.date}支付的${item.type}费用\n\n$payString';
                          bool? delete = await showDeleteConfirmDialog(desc);
                          if (delete == true) {
                            await TripProvider().deleteTripBillCascade(item.id);
                            snapshot.data.remove(item);
                            setState(() {});
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
                        refreshTripBillList();
                        // if (refreshFlag == true) {
                        //   refreshTripBillList();
                        // }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(left: 17.0, right: 17.0, top: 7.0, bottom: 7.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.only(bottom: 7.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _userMap![item.userId]!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        '¥ ${item.pay.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(top: 7.0, bottom: 5.0),
                              child: Row(
                                children: [
                                  Text(item.type),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(item.date),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'AA：${funcAAUserNameString(item.aaUsers)}',
                              style: TextStyle(
                                color: Color.fromARGB(255, 118, 112, 112),
                              ),
                            ),
                            if (item.remark != '') ...[
                              Container(
                                margin: EdgeInsets.only(top: 7.0),
                                padding: EdgeInsets.only(top: 7.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey, width: 0.5),
                                  ),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    '备注：${item.remark}',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 118, 112, 112),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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

  Future<bool?> showDeleteConfirmDialog(String desc) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("提示"),
          content: Text(
            "您确定要删除该笔流水\n\n$desc",
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

class TripBillPage extends StatefulWidget {
  TripBillPage({
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
  String? _oldUserAA;
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

  void updateTripBill(String payInput, String datePicker, String remarkInput, double pay) async {
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
    if (_oldUserAA != _selectUserAA.join(',') || pay != double.parse(payInput)) {
      updateTripBillDetail(widget.id!, double.parse(payInput));
    }
  }

  // 创建 更新 明细
  void updateTripBillDetail(int billId, double pay) async {
    double payAA = double.parse((pay / _selectUserAA.length).toStringAsFixed(2)); // 平摊
    List<TripBillDetail> objs = _selectUserAA.map<TripBillDetail>((int userId) {
      return TripBillDetail(
        billId: billId,
        userId: userId,
        pay: payAA,
      );
    }).toList();

    await TripProvider().batchTripBillDetail(billId, objs);
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
    _oldUserAA = widget.aaUsers; // 用户
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

      // payInput = double.parse(payInput).toStringAsFixed(2);
      if (widget.id == null || _oneMore) {
        createTripBill(payInput, datePicker, remarkInput);
      } else {
        updateTripBill(payInput, datePicker, remarkInput, widget.pay!);
      }
      return true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(desc),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: FutureBuilder(
              future: TripProvider().listTripUser(widget.tripId),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: [
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return DropdownButtonFormField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              labelText: '成员',
                            ),
                            hint: Text('请选择付款人'),
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
                      SizedBox(height: 10),
                      TextField(
                        maxLength: 10,
                        // autofocus: true,
                        controller: payController,
                        decoration: InputDecoration(
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
                      SizedBox(height: 10),
                      TextField(
                        // autofocus: true,
                        controller: dateController,
                        decoration: InputDecoration(
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
                            locale: Locale('zh'),
                          );
                          if (result != null) {
                            dateController.text = result.toString().substring(0, 10);
                          }
                        },
                        readOnly: true,
                      ),
                      SizedBox(height: 10),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return DropdownButtonFormField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.category),
                              labelText: '类型',
                            ),
                            hint: Text('请选择类型'),
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
                      SizedBox(height: 10),
                      TextField(
                        maxLength: 20,
                        // autofocus: true,
                        controller: remarkController,
                        decoration: InputDecoration(
                          labelText: '备注',
                          hintText: '请输入备注（选填）',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '选择成员来AA',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 205, 50, 36),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                          return GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.0,
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
                          );
                        }),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ElevatedButton(
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Color.fromARGB(255, 113, 111, 111),
                          //     foregroundColor: Colors.white,
                          //   ),
                          //   onPressed: () {
                          //     Navigator.pop(context);
                          //   },
                          //   child: Text('取消'),
                          // ),
                          // SizedBox(width: 30),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 10, 132, 10),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (saveOrUpdate()) {
                                Navigator.pop(context, true);
                              }
                            },
                            child: Text('确认'),
                          ),
                          SizedBox(width: 30),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 205, 50, 36),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (saveOrUpdate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '新增成功',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    backgroundColor: Color.fromARGB(255, 10, 132, 10),
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
                            child: Text('保存并再记一笔'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
