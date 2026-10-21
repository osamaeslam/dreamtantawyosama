import 'package:flutter/material.dart';
import '../models/models.dart';

/// نوع الإشعارات المرتبطة بالزيارات
enum VisitNotificationType {
  registration,
  unsuccessful,
  lowCoverage,
  supervisorAssignment,
}

/// نموذج إشعار زيارة
class VisitNotification {
  final String id;
  final String title;
  final String body;
  final VisitNotificationType type;
  final String? customerName;
  final String? repName;
  final String? region;
  final DateTime timestamp;
  final String? relatedVisitId;
  final String? supervisorName;
  bool isRead;

  VisitNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.customerName,
    this.repName,
    this.region,
    required this.timestamp,
    this.relatedVisitId,
    this.supervisorName,
    this.isRead = false,
  });

  factory VisitNotification.fromJson(Map<String, dynamic> json) {
    return VisitNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: _parseType(json['type']?.toString() ?? 'registration'),
      customerName: json['customerName']?.toString(),
      repName: json['repName']?.toString(),
      region: json['region']?.toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      relatedVisitId: json['relatedVisitId']?.toString(),
      supervisorName: json['supervisorName']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'customerName': customerName,
        'repName': repName,
        'region': region,
        'timestamp': timestamp.toIso8601String(),
        'relatedVisitId': relatedVisitId,
        'supervisorName': supervisorName,
        'isRead': isRead,
      };

  static VisitNotificationType _parseType(String value) {
    switch (value) {
      case 'registration':
        return VisitNotificationType.registration;
      case 'unsuccessful':
        return VisitNotificationType.unsuccessful;
      case 'lowCoverage':
        return VisitNotificationType.lowCoverage;
      case 'supervisorAssignment':
        return VisitNotificationType.supervisorAssignment;
      default:
        return VisitNotificationType.registration;
    }
  }
}

class NotificationService {
  static final List<VisitNotification> _visitNotifications = [];

  static List<VisitNotification> get visitNotifications =>
      List.unmodifiable(_visitNotifications);

  static int get unreadVisitNotificationCount =>
      _visitNotifications.where((n) => !n.isRead).length;

  static void addVisitNotification(VisitNotification notification) {
    _visitNotifications.insert(0, notification);
  }

  static void markAllVisitNotificationsAsRead() {
    for (var n in _visitNotifications) {
      n.isRead = true;
    }
  }

  static void clearVisitNotifications() {
    _visitNotifications.clear();
  }

  static void notifyVisitRegistered(
    CustomerVisit visit, {
    String? supervisorName,
    String? region,
  }) {
    final title = 'زيارة مسجلة';
    final body = 'تم تسجيل زيارة إلى ${visit.customerName}'
        ' في ${region ?? visit.branchName ?? ''}';

    addVisitNotification(VisitNotification(
      id: 'visit_${visit.id}',
      title: title,
      body: body,
      type: VisitNotificationType.registration,
      customerName: visit.customerName,
      repName: visit.repName,
      region: region ?? visit.branchName,
      timestamp: DateTime.now(),
      relatedVisitId: visit.id,
      supervisorName: supervisorName,
    ));
  }

  static void notifyUnsuccessfulVisit(
    CustomerVisit visit, {
    String? supervisorName,
    String? region,
  }) {
    final title = 'زيارة غير ناجحة';
    final body = 'زيارة ${visit.customerName} انتهت بدون نتيجة: ${visit.outcome}';

    addVisitNotification(VisitNotification(
      id: 'visit_fail_${visit.id}',
      title: title,
      body: body,
      type: VisitNotificationType.unsuccessful,
      customerName: visit.customerName,
      repName: visit.repName,
      region: region ?? visit.branchName,
      timestamp: DateTime.now(),
      relatedVisitId: visit.id,
      supervisorName: supervisorName,
    ));
  }

  static void notifyLowCoverageWarning(
    String region,
    double coveragePercentage, {
    String? supervisorName,
  }) {
    final title = 'تحذير انخفاض التغطية';
    final body =
        'تغطية المنطقة $region منخفضة: ${coveragePercentage.toStringAsFixed(1)}%';

    addVisitNotification(VisitNotification(
      id: 'coverage_${region}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: VisitNotificationType.lowCoverage,
      region: region,
      timestamp: DateTime.now(),
      supervisorName: supervisorName,
    ));
  }

  static Future<void> notifyOrderStatusChange(
    OrderInvoice invoice,
    String newStatus, {
    String? changedBy,
    String? repName,
    String? supervisorName,
  }) async {}

  static List<String> getOrderStatuses() {
    return [
      'جديد',
      'موافقة المشرف',
      'جاري التحضير',
      'تم تجهيظ الطليةه',
      'في انتظار التوصيل',
      'تم التوصيل',
      'مكتمل',
      'ملغي',
    ];
  }

  static String getStatusLabel(String status) {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'confirmed':
        return 'موافقة المشرف';
      case 'preparing':
        return 'جاري التحضير';
      case 'ready':
        return 'تم تجهيظ الطليةه';
      case 'awaiting_delivery':
        return 'في انتظار التوصيل';
      case 'delivered':
        return 'تم التوصيل';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  static String getNextStatus(String status) {
    switch (status) {
      case 'new':
      case 'جديد':
        return 'confirmed';
      case 'confirmed':
      case 'موافقة المشرف':
        return 'preparing';
      case 'preparing':
      case 'جاري التحضير':
        return 'ready';
      case 'ready':
      case 'تم تجهيظ الطليةه':
        return 'awaiting_delivery';
      case 'awaiting_delivery':
      case 'في انتظار التوصيل':
        return 'delivered';
      case 'delivered':
      case 'تم التوصيل':
        return 'completed';
      default:
        return 'new';
    }
  }

  static String getStatusIcon(String status) {
    switch (status) {
      case 'new':
      case 'جديد':
        return '📋';
      case 'confirmed':
      case 'موافقة المشرف':
        return '✅';
      case 'preparing':
      case 'جاري التحضير':
        return '📦';
      case 'ready':
      case 'تم تجهيظ الطليةه':
        return '🚚';
      case 'awaiting_delivery':
      case 'في انتظار التوصيل':
        return '📍';
      case 'delivered':
      case 'تم التوصيل':
        return '🏠';
      case 'completed':
      case 'مكتمل':
        return '✅';
      case 'cancelled':
      case 'ملغي':
        return '❌';
      default:
        return '📋';
    }
  }

  static Color getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'new':
      case 'جديد':
        return isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
      case 'confirmed':
      case 'موافقة المشرف':
        return const Color(0xFF059669);
      case 'preparing':
      case 'جاري التحضير':
        return const Color(0xFFD97706);
      case 'ready':
      case 'تم تجهيظ الطليةه':
        return const Color(0xFF7C3AED);
      case 'awaiting_delivery':
      case 'في انتظار التوصيل':
        return const Color(0xFF0EA5E9);
      case 'delivered':
      case 'تم التوصيل':
        return const Color(0xFF10B981);
      case 'completed':
      case 'مكتمل':
        return const Color(0xFF15803D);
      case 'cancelled':
      case 'ملغي':
        return const Color(0xFFDC2626);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  static int getStatusStep(String status) {
    switch (status) {
      case 'new':
      case 'جديد':
        return 1;
      case 'confirmed':
      case 'موافقة المشرف':
        return 2;
      case 'preparing':
      case 'جاري التحضير':
        return 3;
      case 'ready':
      case 'تم تجهيظ الطليةه':
        return 4;
      case 'awaiting_delivery':
      case 'في انتظار التوصيل':
        return 5;
      case 'delivered':
      case 'تم التوصيل':
        return 6;
      case 'completed':
      case 'مكتمل':
        return 7;
      case 'cancelled':
      case 'ملغي':
        return -1;
      default:
        return 0;
    }
  }
}
