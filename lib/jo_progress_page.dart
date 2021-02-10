import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class JoProgressPage extends StatefulWidget {

  final Map<String, dynamic> message;

  JoProgressPage({this.message});

  @override
  State<StatefulWidget> createState() {
    return JoProgressPageState();
  }
}

class JoProgressPageState extends State<JoProgressPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var data;
  var woList;

  @override
  void initState() {
    super.initState();

    data = widget.message['data'];

    //print(data);
    //print(data['preparedDate']);
    //print(data['woList']);

    woList = json.decode(data['woList']);

    /*
    var woList = json.decode(data['woList']);
    print(woList);
    print(woList.length);
    print(woList[0]['scopeOfWork']);*/
  }

  @override
  Widget build(BuildContext context) {

    final _width = MediaQuery.of(context).size.width;
    final _height = MediaQuery.of(context).size.height;

    var titleStyle = TextStyle(color: Colors.black54, fontWeight: FontWeight.normal, fontSize: 15,);
    var subStyle = TextStyle(color: Colors.black87, fontSize: 17);
    var modelmake = data['model'].toString().isEmpty ? 'None' : data['model'].toString()+' '+data['make'].toString();

    final _headerList = ListView(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.format_list_numbered),
          title: Text('JO#', style: titleStyle,),
          subtitle: Text(data['joNum'].toString(), style: subStyle,),
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text('CSA', style: titleStyle,),
          subtitle: Text(data['csa'].toString(), style: subStyle,),
        ),
        ListTile(
          leading: Icon(Icons.category),
          title: Text('Model & Make', style: titleStyle,),
          subtitle: Text(modelmake, style: subStyle,),
        ),
        ListTile(
          leading: Icon(Icons.linear_scale),
          title: Text('Serial', style: titleStyle,),
          subtitle: Text(data['serialNum'].toString(), style: subStyle,),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Date Commit', style: titleStyle,),
          subtitle: Text(data['dateCommit'].toString(), style: subStyle,),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Prepared Data', style: titleStyle,),
          subtitle: Text(data['preparedDate'].toString(), style: subStyle,),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Date Finished', style: titleStyle,),
          subtitle: Text(data['dateFinished'].toString(), style: subStyle,),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Your Progress'),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Expanded(
              child: _headerList,
            ),
            Text('WORKORDERS', style: TextStyle(color: Colors.black45),),

            Expanded(
              child: ListView.builder(
                itemCount: woList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return new SimpleDialog(
                              children: <Widget>[
                                new Container(
                                  height: 300.0,
                                  width: _width,
                                  child: new ListView(
                                    children: <Widget>[
                                      ListTile(
                                        leading: Icon(Icons.group_work),
                                        title: Text('Scope Group', style: titleStyle,),
                                        subtitle: Text(woList[index]['scopeGroup'], style: subStyle,),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.work),
                                        title: Text('Scope of Work', style: titleStyle,),
                                        subtitle: Text(woList[index]['scopeOfWork'], style: subStyle,),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.category),
                                        title: Text('Job Type', style: titleStyle,),
                                        subtitle: Text(woList[index]['jobType'], style: subStyle,),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.date_range),
                                        title: Text('Start', style: titleStyle,),
                                        subtitle: Text(woList[index]['dStart'], style: subStyle,),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.date_range),
                                        title: Text('End', style: titleStyle,),
                                        subtitle: Text(woList[index]['dEnd'], style: subStyle,),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            );
                          },
                        );

                      },
                      leading: Icon(Icons.work),
                      title: Text(woList[index]['scopeGroup'], style: titleStyle,),
                      subtitle: Text(woList[index]['scopeOfWork'], style: subStyle,),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}