library flitter.routes.room;

import 'dart:async';

import 'package:flitter/app.dart';
import 'package:flitter/redux/actions.dart';
import 'package:flitter/redux/store.dart';
import 'package:flitter/services/flitter_request.dart';
import 'package:flitter/widgets/common/chat_room.dart';
import 'package:flutter/material.dart';
import 'package:gitter/gitter.dart';
import 'package:gitter/src/models/faye_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RoomMenuAction { leave, autoMarkAsRead }

class RoomView extends StatefulWidget {
  static const path = "/room";

  RoomView();

  @override
  _RoomViewState createState() => new _RoomViewState();
}

class _RoomViewState extends State<RoomView> with WidgetsBindingObserver {
  Iterable<Message> get messages => flitterStore.state.selectedRoom.messages;
  Iterable<User> get users => flitterStore.state.selectedRoom.users;
  var _autoMarkAsRead = true;

  Room get room => flitterStore.state.selectedRoom.room;

  var _subscription;
  Timer _unreadTimer;

  @override
  void initState() {
    super.initState();
    _subscription = flitterStore.onChange.listen((flitterAppState) {
      setState(() {
        _readMessages();
      });
    });

    _fetchMessages();
    _fetchUsers();
    _getMarkAsReadPref();

    gitterSubscriber.subscribeToChatMessages(room.id, _onMessageHandler);
    WidgetsBinding.instance.addObserver(this);
  }

  _onMessageHandler(List<GitterFayeMessage> msgs) {
    for (GitterFayeMessage msg in msgs) {
      String roomId = msg.channel
          .split("/api/v1/rooms/")
          .last
          .split("/")
          .first;
      if (msg.data != null && roomId == room.id) {
        switch (msg.data["operation"]) {
          case "create":
            flitterStore.dispatch(new OnMessageForCurrentRoom(
                new Message.fromJson(msg.data["model"])));
            break;
          case "remove":
            flitterStore.dispatch(new OnDeletedMessageForCurrentRoom(
                new Message.fromJson(msg.data["model"])));
            break;
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    gitterSubscriber.unsubscribeToChatMessages(room.id);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var body;

    if (messages != null) {
      final ChatRoom chatRoom =
      new ChatRoom(messages: messages
          .toList()
          .reversed,
          users: users != null ? users.toList() : [],
          room: room);
      chatRoom.onNeedDataStream.listen((_) => _fetchMessages());
      body = chatRoom;
    } else {
      body = new LoadingView();
    }

    return new Scaffold(
        appBar: new AppBar(title: new Text(room.name), actions: [_buildMenu()]),
        body: body,
        floatingActionButton:
        _userHasJoined || messages == null ? null : _joinRoomButton());
  }

  _fetchMessages([bool fetchBefore = true]) {
    if (fetchBefore) {
      String id = messages?.isNotEmpty == true ? messages.first.id : null;
      fetchMessagesOfRoom(roomId: room.id, beforeId: id);
    } else {
      String id = messages?.isNotEmpty == true ? messages.last.id : null;
      fetchMessagesOfRoom(roomId: room.id, afterId: id);
    }
  }

  _fetchUsers() {
    fetchUsersOfRoom(roomId: room.id, limit: room.userCount);
  }

  Widget _buildMenu() =>
      new PopupMenuButton(
          itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<RoomMenuAction>>[
            new PopupMenuItem<RoomMenuAction>(
                value: RoomMenuAction.leave,
                child: const ListTile(leading: const Icon(null),
                    title: const Text('Leave room'))),
            const PopupMenuDivider(),
            new CheckedPopupMenuItem<RoomMenuAction>(
              checked: _autoMarkAsRead,
              value: RoomMenuAction.autoMarkAsRead,
              child: const Text('Auto mark as read'),
            )
          ],
          onSelected: (RoomMenuAction action) async {
            switch (action) {
              case RoomMenuAction.leave:
                _onLeaveRoom();
                break;
              case RoomMenuAction.autoMarkAsRead:
                SharedPreferences prefs = await SharedPreferences.getInstance();
                _autoMarkAsRead = !_autoMarkAsRead;
                prefs.setBool("autoMarkAsRead:${room.id}", _autoMarkAsRead);
                if (_autoMarkAsRead) {
                  _readMessages();
                }
                break;
            }
          });

  _onLeaveRoom() async {
    bool success = await leaveRoom(room);
    if (success == true) {
      Navigator.of(context).pop();
    } else {
      // Todo: show error
    }
  }

  Widget _joinRoomButton() {
    return new FloatingActionButton(
        child: new Icon(Icons.message), onPressed: _onTapJoinRoom);
  }

  void _onTapJoinRoom() {
    joinRoom(room);
  }

  bool get _userHasJoined =>
      flitterStore.state.rooms.any((Room r) => r.id == room.id);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _fetchMessages(false);
        break;
      default:
        break;
    }
  }

  Future _getMarkAsReadPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _autoMarkAsRead = prefs.getBool("autoMarkAsRead:${room.id}") ?? true;
  }

  _markAllAsRead() {
    List<String> messageIds = messages
        .where((message) => message.unread)
        .map((message) => message.id).toList();
    if (messageIds.length > 0) {
      markMessagesAsReadOfRoom(room.id, messageIds);
    }
  }

  _readMessages() {
    if (_autoMarkAsRead) {
      if (_unreadTimer != null) {
        _unreadTimer.cancel();
      }
      _unreadTimer =
      new Timer(new Duration(milliseconds: 2000), _markAllAsRead);
    }
  }
}
