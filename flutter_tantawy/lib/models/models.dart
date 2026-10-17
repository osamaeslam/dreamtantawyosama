// نماذج البيانات لمجموعة الطنطاوي للتجارة والتوزيع - متوافقة 100% مع Supabase

enum UserRole { admin, branchManager, supervisor, salesRep }

class AppUser {
  final String id;
  final String name;
  final String username;
  final String role;
  final String branchName;
  final String phone;
  final String? supervisorName;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.branchName,
    required this.phone,
    this.supervisorName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'sales_rep',
      branchName: json['branchName']?.toString() ?? json['branch_name']?.toString() ?? 'المركز الرئيسي',
      phone: json['phone']?.toString() ?? '',
      supervisorName: json['supervisorName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'role': role,
    'branch_name': branchName,
    'phone': phone,
    'supervisor_name': supervisorName,
  };
}

class Product {
  final String id;
  final String code;
  final String name;
  final String department;
  final String category;
  final double piecePrice;
  final double cartonPrice;
  final double? promoPrice;
  final int cartonQuantity;
  final int branchStockActual;
  final int branchStockReserved;
  final int mainWarehouseStock;
  final String? imageUrl;
  final String status;
  final String salesPriority;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.category,
    required this.piecePrice,
    required this.cartonPrice,
    this.promoPrice,
    required this.cartonQuantity,
    required this.branchStockActual,
    required this.branchStockReserved,
    required this.mainWarehouseStock,
    this.imageUrl,
    required this.status,
    required this.salesPriority,
  });

  int get availableStock => branchStockActual - branchStockReserved;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? 'عام',
      category: json['category']?.toString() ?? '',
      piecePrice: (json['piecePrice'] ?? json['piece_price'] ?? json['salesPrice'] ?? 0).toDouble(),
      cartonPrice: (json['cartonPrice'] ?? json['carton_price'] ?? 0).toDouble(),
      promoPrice: json['promoPrice'] != null ? (json['promoPrice']).toDouble() : null,
      cartonQuantity: (json['cartonQuantity'] ?? json['factor'] ?? 1).toInt(),
      branchStockActual: (json['branchStockActual'] ?? json['branch_stock_actual'] ?? 0).toInt(),
      branchStockReserved: (json['branchStockReserved'] ?? json['branch_stock_reserved'] ?? 0).toInt(),
      mainWarehouseStock: (json['mainWarehouseActual'] ?? json['main_warehouse_actual'] ?? 0).toInt(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'متاح',
      salesPriority: json['salesPriority']?.toString() ?? 'عادي',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'department': department,
    'category': category,
    'piece_price': piecePrice,
    'carton_price': cartonPrice,
    'promo_price': promoPrice,
    'carton_quantity': cartonQuantity,
    'branch_stock_actual': branchStockActual,
    'branch_stock_reserved': branchStockReserved,
    'main_warehouse_actual': mainWarehouseStock,
    'image_url': imageUrl,
    'status': status,
    'sales_priority': salesPriority,
  };
}

class Customer {
  final String id;
  final String code;
  final String name;
  final String storeName;
  final String phone;
  final String? address;
  final String branchName;
  final String? repName;
  final double currentBalance;
  final double creditLimit;
  final double overdueBalance;
  final String tier;

  Customer({
    required this.id,
    required this.code,
    required this.name,
    required this.storeName,
    required this.phone,
    this.address,
    required this.branchName,
    this.repName,
    required this.currentBalance,
    required this.creditLimit,
    required this.overdueBalance,
    required this.tier,
  });

  bool get isOverCreditLimit => creditLimit > 0 && currentBalance > creditLimit;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? json['store_name']?.toString() ?? json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString(),
      branchName: json['branchName']?.toString() ?? json['branch_name']?.toString() ?? '',
      repName: json['repName']?.toString() ?? json['rep_name']?.toString(),
      currentBalance: (json['balance'] ?? json['currentBalance'] ?? json['current_balance'] ?? 0).toDouble(),
      creditLimit: (json['creditLimit'] ?? json['credit_limit'] ?? 0).toDouble(),
      overdueBalance: (json['overdueBalance'] ?? json['totalOverdue'] ?? 0).toDouble(),
      tier: json['tier']?.toString() ?? 'عادي',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'store_name': storeName,
    'phone': phone,
    'address': address,
    'branch_name': branchName,
    'rep_name': repName,
    'current_balance': currentBalance,
    'credit_limit': creditLimit,
    'overdue_balance': overdueBalance,
    'tier': tier,
  };
}

class OrderItem {
  final String productId;
  final String productCode;
  final String productName;
  final int cartons; // عدد الكراتين
  final int pieces; // عدد القطع الفردية
  final double cartonPrice;
  final double piecePrice;
  final double discount;

  OrderItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.cartons,
    required this.pieces,
    required this.cartonPrice,
    required this.piecePrice,
    this.discount = 0.0,
  });

  double get totalPrice => (cartons * cartonPrice) + (pieces * piecePrice) - discount;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? json['product_id']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? json['product_code']?.toString() ?? '',
      productName: json['productName']?.toString() ?? json['product_name']?.toString() ?? '',
      cartons: (json['cartons'] ?? json['quantity'] ?? 0).toInt(),
      pieces: (json['pieces'] ?? 0).toInt(),
      cartonPrice: (json['cartonPrice'] ?? json['carton_price'] ?? 0).toDouble(),
      piecePrice: (json['piecePrice'] ?? json['piece_price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_code': productCode,
    'product_name': productName,
    'cartons': cartons,
    'pieces': pieces,
    'carton_price': cartonPrice,
    'piece_price': piecePrice,
    'discount': discount,
    'total_price': totalPrice,
  };
}

class OrderInvoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String customerCode;
  final String repId;
  final String repName;
  final String branchName;
  final DateTime date;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String status; // 'جديد' | 'معتمد من المشرف' | 'جاهز للصرف' | 'تم الصرف' | 'ملغاة'
  final String paymentType; // 'آجل' | 'نقدي'
  final String? notes;

  OrderInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.repId,
    required this.repName,
    required this.branchName,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.totalAmount,
    required this.status,
    required this.paymentType,
    this.notes,
  });

  factory OrderInvoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return OrderInvoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? '',
      customerCode: json['customerCode']?.toString() ?? json['customer_code']?.toString() ?? '',
      repId: json['repId']?.toString() ?? json['rep_id']?.toString() ?? '',
      repName: json['repName']?.toString() ?? json['rep_name']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? json['branch_name']?.toString() ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      items: rawItems.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? json['total_amount'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'جديد',
      paymentType: json['paymentType']?.toString() ?? json['payment_type']?.toString() ?? 'آجل',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice_number': invoiceNumber,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_code': customerCode,
    'rep_id': repId,
    'rep_name': repName,
    'branch_name': branchName,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'total_amount': totalAmount,
    'status': status,
    'payment_type': paymentType,
    'notes': notes,
  };
}

class CustomerVisit {
  final String id;
  final String customerId;
  final String customerName;
  final String repName;
  final DateTime date;
  final String type;
  final String outcome;
  final double collectedAmount;
  final String? notes;
  final double? latitude;
  final double? longitude;

  CustomerVisit({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.repName,
    required this.date,
    required this.type,
    required this.outcome,
    this.collectedAmount = 0.0,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory CustomerVisit.fromJson(Map<String, dynamic> json) {
    return CustomerVisit(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? '',
      repName: json['repName']?.toString() ?? json['rep_name']?.toString() ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      type: json['type']?.toString() ?? 'زيارة دورية',
      outcome: json['outcome']?.toString() ?? 'متابعة فقط',
      collectedAmount: (json['collectedAmount'] ?? json['collected_amount'] ?? 0).toDouble(),
      notes: json['notes']?.toString(),
      latitude: json['location']?['latitude'] != null ? (json['location']['latitude']).toDouble() : null,
      longitude: json['location']?['longitude'] != null ? (json['location']['longitude']).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'customer_name': customerName,
    'rep_name': repName,
    'date': date.toIso8601String(),
    'type': type,
    'outcome': outcome,
    'collected_amount': collectedAmount,
    'notes': notes,
    if (latitude != null && longitude != null)
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
  };
}
