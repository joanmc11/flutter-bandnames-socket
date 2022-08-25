import 'dart:io';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('BandNames', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: socketService.serverStatus == ServerStatus.Online
                ? Icon(Icons.check_circle, color: Colors.blue[300])
                : Icon(Icons.offline_bolt, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i]),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        onPressed: addNewBand,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: ((_) => socketService.emit('delete-band', {'id': band.id})),
      background: Container(
        padding: const EdgeInsets.only(left: 8.0),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.red])),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Delet Band',
              style: TextStyle(color: Colors.red.withOpacity(0.6)),
            )),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(band.name.substring(0, 2)),
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: TextStyle(fontSize: 20)),
        onTap: (() => socketService.emit('vote-band', {'id': band.id})),
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    if (Platform.isAndroid) {
      return showDialog(
        context: context,
        builder: ((_) => AlertDialog(
              title: const Text('New band name:'),
              content: TextField(
                controller: textController,
              ),
              actions: [
                MaterialButton(
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () => addBandToList(textController.text),
                    child: Text('Add')),
              ],
            )),
      );
    }

    showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
              title: Text('New band name:'),
              content: CupertinoTextField(
                controller: textController,
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: (() => addBandToList(textController.text)),
                  child: const Text('Add'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: (() => Navigator.pop(context)),
                  child: const Text('Dismiss'),
                )
              ],
            ));
  }

  void addBandToList(String name) {
    print(name);
    if (name.length > 1) {
      //Podemos agregar

      //emitir: add-band
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': name});
    }

    Navigator.pop(context);
  }

  //Mostrar grafica
  Widget _showGraph() {
    Map<String, double> dataMap = {};

    bands.forEach(((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    }));

    final List<Color> colorList = [
      Colors.blue,
      Colors.pink,
      Colors.amberAccent,
      Colors.teal,
      Colors.yellow,
      Colors.green.shade200,
      Colors.blue.shade200,
      Colors.black,
      Colors.red,
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: PieChart(
        dataMap: dataMap.isEmpty ? {"No hay datos":0}: dataMap,
        colorList: colorList,
        chartType: ChartType.ring,
      ),
    );
  }
}
