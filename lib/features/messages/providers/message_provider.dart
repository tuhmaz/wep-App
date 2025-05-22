import 'package:flutter/material.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/api_service.dart';

class MessageProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<MessageModel> _messages = [];
  List<MessageModel> _sentMessages = [];
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = false;

  MessageProvider(this._apiService);

  List<MessageModel> get messages => _messages;
  List<MessageModel> get sentMessages => _sentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get allUsers => _allUsers;
  bool get isLoadingUsers => _isLoadingUsers;

  int get unreadCount => _messages.where((message) => !message.read).length;

  bool get hasUnreadMessages => unreadCount > 0;

  Future<void> fetchMessages() async {
    try {

      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get('/dashboard/messages');
     
      if (response != null && response['messages'] != null) {

        _messages = (response['messages'] as List)
            .map((message) => MessageModel.fromJson(message))
            .toList();


      } else {

      }
    } catch (e) {

      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();

    }
  }

  Future<void> fetchSentMessages() async {
    try {

      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get('/dashboard/messages/sent');
     
      if (response != null && response['sent_messages'] != null) {

        _sentMessages = (response['sent_messages'] as List)
            .map((message) => MessageModel.fromJson(message))
            .toList();


      } else {

        _sentMessages = [];
      }
    } catch (e) {

      _error = e.toString();
      _sentMessages = [];
    } finally {
      _isLoading = false;
      notifyListeners();

    }
  }

  Future<void> fetchAllUsers() async {
    if (_isLoadingUsers) return; // Prevent multiple simultaneous calls
    
    try {
      _isLoadingUsers = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get('/dashboard/users');
     
      if (response != null) {
        // تحقق من هيكل البيانات
        if (response['data'] != null && response['data']['users'] != null) {
          // هيكل البيانات: {status: true, message: null, data: {users: [...]}}  
          _allUsers = List<Map<String, dynamic>>.from(response['data']['users']);
        } else if (response['users'] != null) {
          // هيكل البيانات: {users: [...]}  
          _allUsers = List<Map<String, dynamic>>.from(response['users']);
        } else if (response['data'] != null) {
          // هيكل البيانات: {data: [...]}  
          _allUsers = List<Map<String, dynamic>>.from(response['data']);
        } else {
          _allUsers = [];
        }
        
      
      } else {
        _allUsers = [];
      }
    } catch (e) {

      _error = e.toString();
      _allUsers = [];
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }


  Future<Map<String, dynamic>?> composeMessage() async {
    try {
     
      final response = await _apiService.get('/dashboard/messages/compose');
     
      if (response != null) {
        return response;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    }
    return null;
  }

  Future<MessageModel?> sendMessage({
    required int recipientId,
    required String subject,
    required String body,
  }) async {
    try {
          _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post('/dashboard/messages/send', {
        'recipient_id': recipientId,
        'subject': subject,
        'body': body,
      });

      if (response != null && response['message_details'] != null) {
       
        final messageData = response['message_details'];
        final newMessage = MessageModel.fromJson(messageData);
        _sentMessages.insert(0, newMessage);
        notifyListeners();
        
        // Show success message
        _error = null;
        return newMessage;
      }else {
        _error = 'فشل في إرسال الرسالة';
      }
      return null;
    } catch (e) {
     
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
     
    }
  }

  Future<MessageModel?> replyToMessage({
    required int messageId,
    required String body,
  }) async {
    try {
           
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post('/dashboard/messages/$messageId/reply', {
        'body': body,
      });     

      if (response != null && response['reply'] != null) {

        final replyMessage = MessageModel.fromJson(response['reply']);
        _sentMessages.insert(0, replyMessage);
        notifyListeners();
        return replyMessage;
      } else {
    
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsRead(int messageId) async {
    try {

      print('📨 الرسالة: $messageId');
      final response = await _apiService.post('/dashboard/messages/$messageId/mark-as-read', {});
      if (response != null) {
        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
         if (messageIndex != -1) {
          final updatedMessage = MessageModel.fromJson({
            ..._messages[messageIndex].toJson(),
            'read': true,
          });
          _messages[messageIndex] = updatedMessage;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
     
      _error = e.toString();
      return false;
    }
  }

  Future<bool> toggleImportant(int messageId) async {
    try {

      print('📨 الرسالة: $messageId');
      final response = await _apiService.post('/dashboard/messages/$messageId/toggle-important', {});
       if (response != null && response['important_status'] != null) {

        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final updatedMessage = MessageModel.fromJson({
            ..._messages[messageIndex].toJson(),
            'is_important': response['important_status'],
          });
          _messages[messageIndex] = updatedMessage;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
     
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    try {

      print('📨 الرسالة: $messageId');
      final response = await _apiService.delete('/dashboard/messages/$messageId');
         if (response != null) {

        _messages.removeWhere((m) => m.id == messageId);
        _sentMessages.removeWhere((m) => m.id == messageId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
     
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteSelectedMessages(List<int> messageIds) async {
    try {


           final response = await _apiService.post('/dashboard/messages/delete-selected', {
        'selected_messages': messageIds,});
      if (response != null) {

        _messages.removeWhere((m) => messageIds.contains(m.id));
        _sentMessages.removeWhere((m) => messageIds.contains(m.id));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
          
      _error = e.toString();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {

           
      final response = await _apiService.get('/dashboard/users/search', queryParameters: {'query': query});
      
     
      if (response != null && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response != null && response['users'] != null) {
        return List<Map<String, dynamic>>.from(response['users']);
      } else {
        return [];
      }
    } catch (e) {
     
      _error = e.toString();
      return [];
    }
  }

  Future<bool> markMessageAsRead(int messageId) async {
      try {
      await _apiService.post('/dashboard/messages/$messageId/mark-as-read', {});
      return true;
    } catch (e) {
      return false;
    }
  }
}
