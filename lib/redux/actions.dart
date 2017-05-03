library flitter.redux.actions;

import 'package:flitter/services/gitter/gitter.dart';
import 'package:flitter/services/gitter/src/models/token.dart';

abstract class FlitterAction {
  String toString() => '$runtimeType';
}

class InitGitterAction extends FlitterAction {
  final GitterApi api;
  InitGitterAction(this.api);
}

class FetchRoomsAction extends FlitterAction {
  final List<Room> romms;
  FetchRoomsAction(this.romms);
}

class FetchGroupsAction extends FlitterAction {
  final List<Group> groups;
  FetchGroupsAction(this.groups);
}

class LogoutAction extends FlitterAction {
  LogoutAction();
}

class LoginAction extends FlitterAction {
  final GitterApi api;
  final User user;
  LoginAction(this.api, this.user);
}

class SelectRoomAction extends FlitterAction {
  final Room room;
  SelectRoomAction(this.room);
}

class FetchMessagesForRoomAction extends FlitterAction {
  final List<Message> messages;
  final String roomId;
  FetchMessagesForRoomAction(this.messages, this.roomId);
}

class OnMessagesForRoom extends FlitterAction {
  final List<Message> messages;
  final String roomId;
  OnMessagesForRoom(this.messages, this.roomId);
}

class JoinRoomAction extends FlitterAction {
  final Room room;
  JoinRoomAction(this.room);
}

class LeaveRoomAction extends FlitterAction {
  final Room room;
  LeaveRoomAction(this.room);
}

class OnSendMessage extends FlitterAction {
  final Message message;
  final String roomId;
  OnSendMessage(this.message, this.roomId);
}