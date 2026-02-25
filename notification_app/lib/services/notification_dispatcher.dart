import 'dart:math';
import 'backend_notification_service.dart';

class NotificationDispatcherBackend {
  /// Map your old "type" to backend "event"
  String _mapTypeToEvent(String type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
        return 'booking_confirmation';
      case 'PAYMENT_SUCCESS':
        return 'payment_success';
      case 'PASSWORD_CREATED':
        return 'user_signup';
      default:
        return 'account_update';
    }
  }

  Future<bool> dispatch({
    required String userId,
    required String type,
    required Map<String, dynamic> metadata,

    /// ['in_app'] or ['sms'] or ['email'] or ['email','sms']
    List<String> channel = const ['in_app'],
  }) async {
    final event = _mapTypeToEvent(type);

    // Normalize channel to what backend expects (string)
    final channelStr = channel.join(',');

    // Ensure required fields exist for backend
    final title = (metadata['title'] ?? _defaultTitle(type)).toString();
    final message = (metadata['message'] ?? _defaultMessage(type, metadata)).toString();

    // If SMS is requested, we MUST have phoneNumber
    final phoneNumber = metadata['phoneNumber']?.toString();

    final payload = <String, dynamic>{
      'title': title,
      'message': message,
      'type': type,
      'channel': channelStr,

      // Only include when present
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      if (metadata['email'] != null) 'email': metadata['email'],

      // Keep any extra metadata too
      ...metadata,
    };

    // Debug (remove later)
    // print('DISPATCH -> userId=$userId event=$event channel=$channelStr phone=$phoneNumber');

    final idempotencyKey = '${userId}_${type}_${Random().nextInt(999999)}';

    return BackendNotificationService.send(
      userId: userId,
      event: event,
      payload: payload,
      idempotencyKey: idempotencyKey,
    );
  }

  String _defaultTitle(String type) {
    switch (type) {
      case 'PAYMENT_SUCCESS':
        return 'Payment Successful';
      case 'BOOKING_CONFIRMED':
        return 'Booking Confirmed';
      case 'PASSWORD_CREATED':
        return 'Account Created';
      default:
        return 'Notification';
    }
  }

  String _defaultMessage(String type, Map<String, dynamic> metadata) {
    switch (type) {
      case 'PAYMENT_SUCCESS':
        final amount = metadata['amount'] ?? '';
        final ref = metadata['reference'] ?? '';
        return 'Payment successful. Amount: $amount Ref: $ref';
      case 'BOOKING_CONFIRMED':
        final hostel = metadata['hostelName'] ?? '';
        final room = metadata['roomNumber'] ?? '';
        return 'Your booking is confirmed. $hostel Room: $room';
      case 'PASSWORD_CREATED':
        return 'Welcome! Your account is ready.';
      default:
        return metadata['message']?.toString() ?? 'You have a new update.';
    }
  }
}
