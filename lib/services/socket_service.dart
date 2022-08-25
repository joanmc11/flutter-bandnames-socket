import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

enum ServerStatus { 
  Connecting,
  Offline,
  Online,
 }

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.Connecting;
  late IO.Socket _socket;

  ServerStatus get serverStatus => _serverStatus;
  IO.Socket get socket => _socket;
  Function get emit => _socket.emit;

  SocketService() {
    _initConfig();
  }

  void _initConfig() {
    //Dart client
    _socket = IO.io(
        'http://192.168.1.46:3000',
        IO.OptionBuilder().
        setTransports(['websocket']).
        enableAutoConnect().
        build());
      
        

    _socket.onConnect((_){
      print("online");
      _serverStatus = ServerStatus.Online;
      notifyListeners();

    } );

    _socket.onDisconnect((_){
      debugPrint("offline");
      _serverStatus = ServerStatus.Offline;
      notifyListeners();
    });

    

  
  }
}
