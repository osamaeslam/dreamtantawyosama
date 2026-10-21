import 'package:flutter/material.dart';
import '../models/models.dart';

class NotificationService {
  static Future<void> notifyOrderStatusChange(
    OrderInvoice invoice,
    String newStatus, {
    String? changedBy,
    String? repName,
    String? supervisorName,
  }) async {
  }

  static List<String> getOrderStatuses() {
    return [
      'جديد',
      'موافقة المشرف',
      'جاري التحضير',
      'تم تجهيز الطليةه',
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
        return 'تم تجهيز الطليةه';
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
      case 'تم تجهيز الطليةه':
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
      case 'تم تجهيز الطليةه':
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
      case 'تم تجهيز الطليةه':
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
      case 'تم تجهيز الطليةه':
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
