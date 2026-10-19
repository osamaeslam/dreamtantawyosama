// نماذج البيانات لمجموعة الطنطاوي للتجارة والتوزيع - متوافقة 100% مع Supabase
// ومطابقة types.ts (React) — توحيد البنية المشتركة بين Flutter وWeb

double? _toDouble(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
int? _toInt(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));

enum UserRole { admin, manager, branchManager, supervisor, salesRep, developer }

class AppUser {
  final String id;
  final String name;
  final String username;
  final String role;
  final String branchName;
  final String phone;
  final String? supervisorName;
  final String? supervisorId;
  final String? email;
  final String? avatar;
  final bool isActive;
  final String approvalStatus;
  final String? code;
  final double? commissionRate;
  final String? registrationDate;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.branchName,
    required this.phone,
    this.supervisorName,
    this.supervisorId,
    this.email,
    this.avatar,
    this.isActive = true,
    this.approvalStatus = 'active',
    this.code,
    this.commissionRate,
    this.registrationDate,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'sales_rep',
      branchName: json['branchName']?.toString() ?? json['branch_name']?.toString() ?? 'المركز الرئيسي',
      phone: json['phone']?.toString() ?? '',
      supervisorName: json['supervisorName']?.toString() ?? json['supervisor_name']?.toString(),
      supervisorId: json['supervisorId']?.toString() ?? json['supervisor_id']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      approvalStatus: json['approvalStatus']?.toString() ?? json['approval_status']?.toString() ?? 'active',
      code: json['code']?.toString(),
      commissionRate: _toDouble(json['commissionRate'] ?? json['commission_rate']),
      registrationDate: json['registrationDate']?.toString() ?? json['registration_date']?.toString(),
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
        'supervisor_id': supervisorId,
        'email': email,
        'avatar': avatar,
        'is_active': isActive,
        'approval_status': approvalStatus,
        'code': code,
        'commission_rate': commissionRate,
        'registration_date': registrationDate,
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

  // === الحقول الموسعة لتطابق types.ts (React) — جميعها اختيارية للـ backward compatibility ===
  final String? size;                    // الحجم
  final String? color;                   // اللون الأساسي للصنف
  final int? mainWarehouseReserved;      // رصيد مخزن أكتوبر - متاح للطلب
  final Map<String, dynamic>? branchStocks;  // أرصدة الفروع الفردية
  final String? itemGroup;               // المجموعة الرئيسية (Item group)
  final double? promoPiecePrice;         // سعر العرض للقطعة الفردية
  final double? offerPrice;              // مرادف سعر العرض
  final double? discountPercent;         // نسبة الخصم الإضافية
  final double? discountPercentage;      // نسبة الخصم
  final double? salesPrice;              // سعر القطعة (Sales Price) مرادف
  final double? price;                   // السعر العام / سعر القطعة (مرادف)
  final String? barcode;                 // باركود الصنف
  final int? minOrderQuantity;           // الحد الأدنى للطلب
  final String? notes;                   // ملاحظات
  final String? variantId;             // معرف الشباك أو اللون
  final String? variantName;             // اسم الشباك (شباك 1، شباك 2، أحمر)
  final String? unifiedCode;             // الكود الموحد (#)
  final String? classification;          // الفئة / Family Name
  final String? familyName;              // العائلة (Family Name)
  final String? cloudinaryPublicId;      // معرف Cloudinary
  final String? cloudinaryUrl;           // رابط Cloudinary

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
    // الحقول الاختيارية الجديدة
    this.size,
    this.color,
    this.mainWarehouseReserved,
    this.branchStocks,
    this.itemGroup,
    this.promoPiecePrice,
    this.offerPrice,
    this.discountPercent,
    this.discountPercentage,
    this.salesPrice,
    this.price,
    this.barcode,
    this.minOrderQuantity,
    this.notes,
    this.variantId,
    this.variantName,
    this.unifiedCode,
    this.classification,
    this.familyName,
    this.cloudinaryPublicId,
    this.cloudinaryUrl,
  });

  int get availableStock => branchStockActual - branchStockReserved;

  double get effectiveCartonPrice => promoPrice ?? cartonPrice;

  bool get hasPromo => promoPrice != null && promoPrice! > 0 && promoPrice! < cartonPrice;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? 'عام',
      category: json['category']?.toString() ?? '',
      piecePrice: (json['piecePrice'] ?? json['piece_price'] ?? json['salesPrice'] ?? json['price'] ?? 0).toDouble(),
      cartonPrice: (json['cartonPrice'] ?? json['carton_price'] ?? 0).toDouble(),
      promoPrice: _toDouble(json['promoPrice'] ?? json['promo_price']),
      cartonQuantity: (json['cartonQuantity'] ?? json['factor'] ?? 1).toInt(),
      branchStockActual: (json['branchStockActual'] ?? json['branch_stock_actual'] ?? 0).toInt(),
      branchStockReserved: (json['branchStockReserved'] ?? json['branch_stock_reserved'] ?? 0).toInt(),
      mainWarehouseStock: (json['mainWarehouseActual'] ?? json['main_warehouse_actual'] ?? json['mainWarehouseStock'] ?? 0).toInt(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      status: json['status']?.toString() ?? 'متاح',
      salesPriority: json['salesPriority']?.toString() ?? json['sales_priority']?.toString() ?? 'عادي',
      // الحقول الاختيارية الموسعة
      size: json['size']?.toString(),
      color: json['color']?.toString() ?? json['variantName']?.toString(),
      mainWarehouseReserved: _toInt(json['mainWarehouseReserved'] ?? json['main_warehouse_reserved']),
      branchStocks: json['branchStocks'] as Map<String, dynamic>?,
      itemGroup: json['itemGroup']?.toString() ?? json['item_group']?.toString(),
      promoPiecePrice: _toDouble(json['promoPiecePrice'] ?? json['promo_piece_price']),
      offerPrice: _toDouble(json['offerPrice'] ?? json['offer_price']),
      discountPercent: _toDouble(json['discountPercent'] ?? json['discount_percent']),
      discountPercentage: _toDouble(json['discountPercentage'] ?? json['discount_percentage']),
      salesPrice: _toDouble(json['salesPrice'] ?? json['sales_price']),
      price: _toDouble(json['price']),
      barcode: json['barcode']?.toString(),
      minOrderQuantity: _toInt(json['minOrderQuantity'] ?? json['min_order_quantity']),
      notes: json['notes']?.toString(),
      variantId: json['variantId']?.toString() ?? json['variant_id']?.toString(),
      variantName: json['variantName']?.toString(),
      unifiedCode: json['unifiedCode']?.toString() ?? json['unified_code']?.toString() ?? json['#']?.toString(),
      classification: json['classification']?.toString() ?? json['family_name']?.toString(),
      familyName: json['familyName']?.toString() ?? json['family_name']?.toString(),
      cloudinaryPublicId: json['cloudinaryPublicId']?.toString() ?? json['cloudinary_public_id']?.toString(),
      cloudinaryUrl: json['cloudinaryUrl']?.toString() ?? json['cloudinary_url']?.toString(),
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
        'size': size,
        'color': color,
        'main_warehouse_reserved': mainWarehouseReserved,
        'branch_stocks': branchStocks,
        'item_group': itemGroup,
        'promo_piece_price': promoPiecePrice,
        'offer_price': offerPrice,
        'discount_percent': discountPercent,
        'discount_percentage': discountPercentage,
        'sales_price': salesPrice,
        'price': price,
        'barcode': barcode,
        'min_order_quantity': minOrderQuantity,
        'notes': notes,
        'variant_id': variantId,
        'variant_name': variantName,
        'unified_code': unifiedCode,
        'classification': classification,
        'family_name': familyName,
        'cloudinary_public_id': cloudinaryPublicId,
        'cloudinary_url': cloudinaryUrl,
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

  // === الحقول الموسعة لتطابق types.ts (React) ===
  final String? governorate;
  final String? region;
  final String? salesRepName;
  final String? salesRepId;
  final String? supervisorName;
  final String? supervisorId;
  final String? taxNumber;
  final double? balance;
  final double? dueBalance;
  final double? totalOverdueAndDue;
  final String? lastOrderDate;
  final String? lastCollectionDate;
  final double? lastCollectionAmount;
  final int? totalOrdersCount;
  final double? totalSpent;
  final double? annualTarget;
  final String? dealEligibility;
  final String? debtStatus;
  final String? paymentTerms;
  final String? clientType;
  final String? activityType;
  final double? guaranteeAmount;
  final bool? hasGuarantee;
  final String? district;
  final String? route;
  final String? notes;
  final String? createdAt;
  final String? lastVisitDate;
  final String? nextVisitDate;
  
  final int? visitCount2026;

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
    // === الحقول الموسعة لتطابق types.ts (React) — اختيارية ===
    this.governorate,
    this.region,
    this.salesRepName,
    this.salesRepId,
    this.supervisorName,
    this.supervisorId,
    this.taxNumber,
    this.balance,
    this.dueBalance,
    this.totalOverdueAndDue,
    this.lastOrderDate,
    this.lastCollectionDate,
    this.lastCollectionAmount,
    this.totalOrdersCount,
    this.totalSpent,
    this.annualTarget,
    this.dealEligibility,
    this.debtStatus,
    this.paymentTerms,
    this.clientType,
    this.activityType,
    this.guaranteeAmount,
    this.hasGuarantee,
    this.district,
    this.route,
    this.notes,
    this.createdAt,
    this.lastVisitDate,
    this.nextVisitDate,
    this.visitCount2026,
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
      repName: json['repName']?.toString() ?? json['rep_name']?.toString() ?? json['salesRepName']?.toString(),
      currentBalance: (json['balance'] ?? json['currentBalance'] ?? json['current_balance'] ?? 0).toDouble(),
      creditLimit: (json['creditLimit'] ?? json['credit_limit'] ?? 0).toDouble(),
      overdueBalance: (json['overdueBalance'] ?? json['totalOverdue'] ?? 0).toDouble(),
      tier: json['tier']?.toString() ?? 'عادي',
      governorate: json['governorate']?.toString() ?? json['state']?.toString(),
      region: json['region']?.toString() ?? json['area']?.toString(),
      salesRepName: json['salesRepName']?.toString() ?? json['sales_rep_name']?.toString(),
      salesRepId: json['salesRepId']?.toString() ?? json['sales_rep_id']?.toString(),
      supervisorName: json['supervisorName']?.toString() ?? json['supervisor_name']?.toString(),
      supervisorId: json['supervisorId']?.toString() ?? json['supervisor_id']?.toString(),
      taxNumber: json['taxNumber']?.toString() ?? json['tax_number']?.toString() ?? json['taxRegistrationNumber']?.toString(),
      balance: _toDouble(json['balance'] ?? json['currentBalance'] ?? json['current_balance']),
      dueBalance: _toDouble(json['dueBalance'] ?? json['due_balance']),
      totalOverdueAndDue: _toDouble(json['totalOverdueAndDue'] ?? json['total_overdue_and_due']),
      lastOrderDate: json['lastOrderDate']?.toString() ?? json['last_order_date']?.toString(),
      lastCollectionDate: json['lastCollectionDate']?.toString() ?? json['last_collection_date']?.toString(),
      lastCollectionAmount: _toDouble(json['lastCollectionAmount'] ?? json['last_collection_amount']),
      totalOrdersCount: _toInt(json['totalOrdersCount'] ?? json['total_orders_count']),
      totalSpent: _toDouble(json['totalSpent'] ?? json['total_spent']),
      annualTarget: _toDouble(json['annualTarget'] ?? json['annual_target']),
      dealEligibility: json['dealEligibility']?.toString() ?? json['deal_eligibility']?.toString(),
      debtStatus: json['debtStatus']?.toString() ?? json['debt_status']?.toString(),
      paymentTerms: json['paymentTerms']?.toString() ?? json['payment_terms']?.toString(),
      clientType: json['clientType']?.toString() ?? json['client_type']?.toString(),
      activityType: json['activityType']?.toString() ?? json['activity_type']?.toString(),
      guaranteeAmount: _toDouble(json['guaranteeAmount'] ?? json['guarantee_amount']),
      hasGuarantee: json['hasGuarantee'] as bool? ?? json['has_guarantee'] as bool?,
      district: json['district']?.toString(),
      route: json['route']?.toString() ?? json['route_']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      lastVisitDate: json['lastVisitDate']?.toString() ?? json['last_visit_date']?.toString(),
      nextVisitDate: json['nextVisitDate']?.toString() ?? json['next_visit_date']?.toString(),
      visitCount2026: _toInt(json['visitCount2026'] ?? json['visit_count_2026']),
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
        'governorate': governorate,
        'region': region,
        'sales_rep_name': salesRepName,
        'sales_rep_id': salesRepId,
        'supervisor_name': supervisorName,
        'supervisor_id': supervisorId,
        'tax_number': taxNumber,
        'balance': balance,
        'due_balance': dueBalance,
        'total_overdue_and_due': totalOverdueAndDue,
        'last_order_date': lastOrderDate,
        'last_collection_date': lastCollectionDate,
        'last_collection_amount': lastCollectionAmount,
        'total_orders_count': totalOrdersCount,
        'total_spent': totalSpent,
        'annual_target': annualTarget,
        'deal_eligibility': dealEligibility,
        'debt_status': debtStatus,
        'payment_terms': paymentTerms,
        'client_type': clientType,
        'activity_type': activityType,
        'guarantee_amount': guaranteeAmount,
        'has_guarantee': hasGuarantee,
        'district': district,
        'route': route,
        'notes': notes,
        'created_at': createdAt,
        'last_visit_date': lastVisitDate,
        'next_visit_date': nextVisitDate,
        'visit_count_2026': visitCount2026,
      };
}

class OrderItem {
  final String productId;
  final String productCode;
  final String productName;
  final int cartons;
  final int pieces;
  final double cartonPrice;
  final double piecePrice;
  final double discount;

  // === الحقول الموسعة لتطابق types.ts InvoiceItem ===
  final String? variantId;
  final String? unifiedCode;
  final String? color;
  final String? itemGroup;
  final String? familyName;
  final String? quantityDescription;
  final double? unitPrice;        // سعر الوحدة الفعلي (alias)
  final double? appliedPrice;      // سعر الكرتونة الفعلي
  final double? totalBeforeTax;
  final double? taxAmount;
  final double? netTotal;
  final String? totalPriceAlias;   // totalPrice alias للتوافق
  final String? fulfilledFrom;     // branch | main_warehouse | mixed
  final bool? fulfillFromMainWarehouse;
  final int? cartonQuantity;
  final int? totalUnits;
  final int? branchStockAtOrder;
  final int? octoberStockAtOrder;
  final String? branchName;
  final bool? isShortage;
  final int? shortageCartons;
  final int? shortagePieces;
  final bool? needsOctoberSupply;
  final String? octoberSupplyStatus;
  final String? productCategory;
  final String? notes;

  OrderItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.cartons,
    required this.pieces,
    required this.cartonPrice,
    required this.piecePrice,
    this.discount = 0.0,
    // الحقول الاختيارية الموسعة
    this.variantId,
    this.unifiedCode,
    this.color,
    this.itemGroup,
    this.familyName,
    this.quantityDescription,
    this.unitPrice,
    this.appliedPrice,
    this.totalBeforeTax,
    this.taxAmount,
    this.netTotal,
    this.totalPriceAlias,
    this.fulfilledFrom,
    this.fulfillFromMainWarehouse,
    this.cartonQuantity,
    this.totalUnits,
    this.branchStockAtOrder,
    this.octoberStockAtOrder,
    this.branchName,
    this.isShortage,
    this.shortageCartons,
    this.shortagePieces,
    this.needsOctoberSupply,
    this.octoberSupplyStatus,
    this.productCategory,
    this.notes,
  });

  double get totalPrice => (cartons * cartonPrice) + (pieces * piecePrice) - discount;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? json['product_id']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? json['product_code']?.toString() ?? '',
      productName: json['productName']?.toString() ?? json['product_name']?.toString() ?? '',
      cartons: (json['cartons'] ?? json['quantity'] ?? 0).toInt(),
      pieces: (json['pieces'] ?? 0).toInt(),
      cartonPrice: _toDouble(json['cartonPrice'] ?? json['carton_price'] ?? 0) ?? 0,
      piecePrice: _toDouble(json['piecePrice'] ?? json['piece_price'] ?? 0) ?? 0,
      cartonQuantity: (json['cartonQuantity'] ?? json['carton_quantity'] ?? json['factor'] ?? 1).toInt(),
      discount: _toDouble(json['discount'] ?? 0) ?? 0,
      variantId: json['variantId']?.toString() ?? json['variant_id']?.toString(),
      unifiedCode: json['unifiedCode']?.toString() ?? json['unified_code']?.toString(),
      color: json['color']?.toString(),
      itemGroup: json['itemGroup']?.toString() ?? json['item_group']?.toString(),
      familyName: json['familyName']?.toString() ?? json['family_name']?.toString(),
      quantityDescription: json['quantityDescription']?.toString() ?? json['quantity_description']?.toString(),
      unitPrice: _toDouble(json['unitPrice'] ?? json['unit_price']),
      appliedPrice: _toDouble(json['appliedPrice'] ?? json['applied_price']),
      totalBeforeTax: _toDouble(json['totalBeforeTax'] ?? json['total_before_tax']),
      taxAmount: _toDouble(json['taxAmount'] ?? json['tax_amount']),
      netTotal: _toDouble(json['netTotal'] ?? json['net_total']),
      fulfilledFrom: json['fulfilledFrom']?.toString() ?? json['fulfilled_from']?.toString(),
      fulfillFromMainWarehouse: json['fulfillFromMainWarehouse'] as bool? ?? json['fulfill_from_main_warehouse'] as bool?,
      totalUnits: _toInt(json['totalUnits'] ?? json['total_units']),
      branchStockAtOrder: _toInt(json['branchStockAtOrder'] ?? json['branch_stock_at_order']),
      octoberStockAtOrder: _toInt(json['octoberStockAtOrder'] ?? json['october_stock_at_order']),
      branchName: json['branchName']?.toString() ?? json['branch_name']?.toString(),
      isShortage: json['isShortage'] as bool? ?? json['is_shortage'] as bool?,
      shortageCartons: _toInt(json['shortageCartons'] ?? json['shortage_cartons']),
      shortagePieces: _toInt(json['shortagePieces'] ?? json['shortage_pieces']),
      needsOctoberSupply: json['needsOctoberSupply'] as bool? ?? json['needs_october_supply'] as bool?,
      octoberSupplyStatus: json['octoberSupplyStatus']?.toString() ?? json['october_supply_status']?.toString(),
      productCategory: json['productCategory']?.toString() ?? json['product_category']?.toString() ?? json['category']?.toString(),
      notes: json['notes']?.toString(),
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
        'carton_quantity': cartonQuantity,
        'discount': discount,
        'total_price': totalPrice,
        'variant_id': variantId,
        'unified_code': unifiedCode,
        'color': color,
        'item_group': itemGroup,
        'family_name': familyName,
        'quantity_description': quantityDescription,
        'unit_price': unitPrice,
        'applied_price': appliedPrice,
        'total_before_tax': totalBeforeTax,
        'tax_amount': taxAmount,
        'net_total': netTotal,
        'fulfilled_from': fulfilledFrom,
        'fulfill_from_main_warehouse': fulfillFromMainWarehouse,
        'total_units': totalUnits,
        'branch_stock_at_order': branchStockAtOrder,
        'october_stock_at_order': octoberStockAtOrder,
        'branch_name': branchName,
        'is_shortage': isShortage,
        'shortage_cartons': shortageCartons,
        'shortage_pieces': shortagePieces,
        'needs_october_supply': needsOctoberSupply,
        'october_supply_status': octoberSupplyStatus,
        'category': productCategory,
        'notes': notes,
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
  final String status;
  final String paymentType; // 'آجل' | 'نقدي'
  final String? notes;

  // === الحقول الموسعة لتطابق types.ts Invoice ===
  final String? supervisorName;
  final String? time;
  final String? createdAt;
  final String? timestamp;
  final int? totalCartons;
  final int? totalPieces;
  final double? discountPercentage;
  final double? discountAmount;
  final double? taxPercentage;
  final double? taxAmount;
  final double? estimatedGrandTotal;
  final bool? syncedToAccounting;
  final String? accountingSyncDate;
  final String? qrPayload;

  // Customer debt & credit
  final double? customerBalanceBefore;
  final double? customerCreditLimit;
  final double? customerBalanceAfter;
  final double? customerOverdueBalance;
  final bool? creditLimitExceeded;
  final double? requiredDownPayment;

  // Shortage & supply (نواقص أكتوبر)
  final bool? isShortageInvoice;
  final String? parentInvoiceId;
  final String? parentInvoiceNumber;
  final bool? hasShortageSplit;
  final String? shortageInvoiceNumber;
  final bool? hasOctoberShortages;
  final int? shortageItemsCount;
  final int? shortageCartonsCount;
  final bool? octoberSupplyRequested;
  final String? octoberSupplyRequestedAt;
  final String? octoberSupplyRequestedBy;
  final bool? octoberSupplyDispatched;
  final String? octoberSupplyDispatchedAt;
  final String? octoberSupplyDispatchedBy;

  // Cancellation & returns
  final String? cancellationReason;
  final String? cancelledBy;
  final String? cancelledAt;
  final String? restoredStockDetails;
  final bool? hasReturns;
  final bool? isPartialReturn;
  final double? totalRefundedAmount;
  final double? netAmountAfterReturns;
  final String? lastReturnDate;

  // Customer contact
  final String? customerPhone;
  final String? customerAddress;
  final String? customerTaxNumber;

  // Invoice items for returns (مرتجعات)
  final List<Map<String, dynamic>>? returnRecords;

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
    // الحقول الموسعة
    this.supervisorName,
    this.time,
    this.createdAt,
    this.timestamp,
    this.totalCartons,
    this.totalPieces,
    this.discountPercentage,
    this.discountAmount,
    this.taxPercentage,
    this.taxAmount,
    this.estimatedGrandTotal,
    this.syncedToAccounting,
    this.accountingSyncDate,
    this.qrPayload,
    this.customerBalanceBefore,
    this.customerCreditLimit,
    this.customerBalanceAfter,
    this.customerOverdueBalance,
    this.creditLimitExceeded,
    this.requiredDownPayment,
    this.isShortageInvoice,
    this.parentInvoiceId,
    this.parentInvoiceNumber,
    this.hasShortageSplit,
    this.shortageInvoiceNumber,
    this.hasOctoberShortages,
    this.shortageItemsCount,
    this.shortageCartonsCount,
    this.octoberSupplyRequested,
    this.octoberSupplyRequestedAt,
    this.octoberSupplyRequestedBy,
    this.octoberSupplyDispatched,
    this.octoberSupplyDispatchedAt,
    this.octoberSupplyDispatchedBy,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.restoredStockDetails,
    this.hasReturns,
    this.isPartialReturn,
    this.totalRefundedAmount,
    this.netAmountAfterReturns,
    this.lastReturnDate,
    this.customerPhone,
    this.customerAddress,
    this.customerTaxNumber,
    this.returnRecords,
  });

  int get computedTotalCartons => items.fold(0, (sum, item) => sum + item.cartons);
  int get computedTotalPieces => items.fold(0, (sum, item) => sum + item.pieces);

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
      subtotal: (_toDouble(json['subtotal']) ?? 0),
      discount: (_toDouble(json['discount']) ?? 0),
      totalAmount: (_toDouble(json['totalAmount'] ?? json['total_amount']) ?? 0),
      status: json['status']?.toString() ?? 'جديد',
      paymentType: json['paymentType']?.toString() ?? json['payment_type']?.toString() ?? 'آجل',
      notes: json['notes']?.toString(),
      supervisorName: json['supervisorName']?.toString() ?? json['supervisor_name']?.toString(),
      time: json['time']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      timestamp: json['timestamp']?.toString(),
      totalCartons: _toInt(json['totalCartons'] ?? json['total_cartons']),
      totalPieces: _toInt(json['totalPieces'] ?? json['total_pieces']),
      discountPercentage: _toDouble(json['discountPercentage'] ?? json['discount_percentage']),
      discountAmount: _toDouble(json['discountAmount'] ?? json['discount_amount']),
      taxPercentage: _toDouble(json['taxPercentage'] ?? json['tax_percentage']),
      taxAmount: _toDouble(json['taxAmount'] ?? json['tax_amount']),
      estimatedGrandTotal: _toDouble(json['estimatedGrandTotal'] ?? json['estimated_grand_total']),
      syncedToAccounting: json['syncedToAccounting'] as bool? ?? json['synced_to_accounting'] as bool?,
      accountingSyncDate: json['accountingSyncDate']?.toString() ?? json['accounting_sync_date']?.toString(),
      qrPayload: json['qrPayload']?.toString() ?? json['qr_payload']?.toString(),
      customerBalanceBefore: _toDouble(json['customerBalanceBefore'] ?? json['customer_balance_before']),
      customerCreditLimit: _toDouble(json['customerCreditLimit'] ?? json['customer_credit_limit']),
      customerBalanceAfter: _toDouble(json['customerBalanceAfter'] ?? json['customer_balance_after']),
      customerOverdueBalance: _toDouble(json['customerOverdueBalance'] ?? json['customer_overdue_balance']),
      creditLimitExceeded: json['creditLimitExceeded'] as bool? ?? json['credit_limit_exceeded'] as bool?,
      requiredDownPayment: _toDouble(json['requiredDownPayment'] ?? json['required_down_payment']),
      isShortageInvoice: json['isShortageInvoice'] as bool? ?? json['is_shortage_invoice'] as bool?,
      parentInvoiceId: json['parentInvoiceId']?.toString() ?? json['parent_invoice_id']?.toString(),
      parentInvoiceNumber: json['parentInvoiceNumber']?.toString() ?? json['parent_invoice_number']?.toString(),
      hasShortageSplit: json['hasShortageSplit'] as bool? ?? json['has_shortage_split'] as bool?,
      shortageInvoiceNumber: json['shortageInvoiceNumber']?.toString() ?? json['shortage_invoice_number']?.toString(),
      hasOctoberShortages: json['hasOctoberShortages'] as bool? ?? json['has_october_shortages'] as bool?,
      shortageItemsCount: _toInt(json['shortageItemsCount'] ?? json['shortage_items_count']),
      shortageCartonsCount: _toInt(json['shortageCartonsCount'] ?? json['shortage_cartons_count']),
      octoberSupplyRequested: json['octoberSupplyRequested'] as bool? ?? json['october_supply_requested'] as bool?,
      octoberSupplyRequestedAt: json['octoberSupplyRequestedAt']?.toString() ?? json['october_supply_requested_at']?.toString(),
      octoberSupplyRequestedBy: json['octoberSupplyRequestedBy']?.toString() ?? json['october_supply_requested_by']?.toString(),
      octoberSupplyDispatched: json['octoberSupplyDispatched'] as bool? ?? json['october_supply_dispatched'] as bool?,
      octoberSupplyDispatchedAt: json['octoberSupplyDispatchedAt']?.toString() ?? json['october_supply_dispatched_at']?.toString(),
      octoberSupplyDispatchedBy: json['octoberSupplyDispatchedBy']?.toString() ?? json['october_supply_dispatched_by']?.toString(),
      cancellationReason: json['cancellationReason']?.toString() ?? json['cancellation_reason']?.toString(),
      cancelledBy: json['cancelledBy']?.toString() ?? json['cancelled_by']?.toString(),
      cancelledAt: json['cancelledAt']?.toString() ?? json['cancelled_at']?.toString(),
      restoredStockDetails: json['restoredStockDetails']?.toString() ?? json['restored_stock_details']?.toString(),
      hasReturns: json['hasReturns'] as bool? ?? json['has_returns'] as bool?,
      isPartialReturn: json['isPartialReturn'] as bool? ?? json['is_partial_return'] as bool?,
      totalRefundedAmount: _toDouble(json['totalRefundedAmount'] ?? json['total_refunded_amount']),
      netAmountAfterReturns: _toDouble(json['netAmountAfterReturns'] ?? json['net_amount_after_returns']),
      lastReturnDate: json['lastReturnDate']?.toString() ?? json['last_return_date']?.toString(),
      customerPhone: json['customerPhone']?.toString() ?? json['customer_phone']?.toString(),
      customerAddress: json['customerAddress']?.toString() ?? json['customer_address']?.toString(),
      customerTaxNumber: json['customerTaxNumber']?.toString() ?? json['customer_tax_number']?.toString(),
      returnRecords: (json['returnRecords'] ?? json['return_records']) as List<Map<String, dynamic>>?,
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
        'supervisor_name': supervisorName,
        'time': time,
        'created_at': createdAt,
        'timestamp': timestamp,
        'total_cartons': totalCartons ?? computedTotalCartons,
        'total_pieces': totalPieces ?? computedTotalPieces,
        'discount_percentage': discountPercentage,
        'discount_amount': discountAmount,
        'tax_percentage': taxPercentage,
        'tax_amount': taxAmount,
        'estimated_grand_total': estimatedGrandTotal,
        'synced_to_accounting': syncedToAccounting,
        'accounting_sync_date': accountingSyncDate,
        'qr_payload': qrPayload,
        'customer_balance_before': customerBalanceBefore,
        'customer_credit_limit': customerCreditLimit,
        'customer_balance_after': customerBalanceAfter,
        'customer_overdue_balance': customerOverdueBalance,
        'credit_limit_exceeded': creditLimitExceeded,
        'required_down_payment': requiredDownPayment,
        'is_shortage_invoice': isShortageInvoice,
        'parent_invoice_id': parentInvoiceId,
        'parent_invoice_number': parentInvoiceNumber,
        'has_shortage_split': hasShortageSplit,
        'shortage_invoice_number': shortageInvoiceNumber,
        'has_october_shortages': hasOctoberShortages,
        'shortage_items_count': shortageItemsCount,
        'shortage_cartons_count': shortageCartonsCount,
        'october_supply_requested': octoberSupplyRequested,
        'october_supply_requested_at': octoberSupplyRequestedAt,
        'october_supply_requested_by': octoberSupplyRequestedBy,
        'october_supply_dispatched': octoberSupplyDispatched,
        'october_supply_dispatched_at': octoberSupplyDispatchedAt,
        'october_supply_dispatched_by': octoberSupplyDispatchedBy,
        'cancellation_reason': cancellationReason,
        'cancelled_by': cancelledBy,
        'cancelled_at': cancelledAt,
        'restored_stock_details': restoredStockDetails,
        'has_returns': hasReturns,
        'is_partial_return': isPartialReturn,
        'total_refunded_amount': totalRefundedAmount,
        'net_amount_after_returns': netAmountAfterReturns,
        'last_return_date': lastReturnDate,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'customer_tax_number': customerTaxNumber,
        'return_records': returnRecords,
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

  // === الحقول المتقدمة من types.ts (React) — اختيارية ===
  final String? customerCode;
  final String? repId;
  final String? branchName;
  final String? supervisorId;
  final String? supervisorName;
  final String? status;
  final String? checkInTime;
  final String? checkOutTime;
  final int? durationMinutes;
  final String? storeStockStatus;
  final String? competitorNotes;
  final int? customerRating;
  final String? nextVisitDate;
  final String? orderId;
  final double? orderAmount;
  final String? syncStatus;
  final bool? isReturn;
  final double? returnValue;
  final String? returnReason;
  final String? returnItems;
  final String? returnStatus;
  final String? returnHandledBy;
  final String? returnHandledAt;
  final String? returnHandledRole;
  final String? returnNote;
  final bool? isArchived;
  final String? archivedAt;
  final String? archivedBy;
  final String? reviewStatus;
  final String? reviewedByName;
  final String? reviewNote;
  final String? reviewedAt;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final String? duplicateOfVisitId;
  final bool? allowSameDaySecondVisit;
  final double? accuracy;
  final String? address;
  final String? mapUrl;
  final String? locationTimestamp;

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
    // الحقول المتقدمة
    this.customerCode,
    this.repId,
    this.branchName,
    this.supervisorId,
    this.supervisorName,
    this.status,
    this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
    this.storeStockStatus,
    this.competitorNotes,
    this.customerRating,
    this.nextVisitDate,
    this.orderId,
    this.orderAmount,
    this.syncStatus,
    this.isReturn,
    this.returnValue,
    this.returnReason,
    this.returnItems,
    this.returnStatus,
    this.returnHandledBy,
    this.returnHandledAt,
    this.returnHandledRole,
    this.returnNote,
    this.isArchived,
    this.archivedAt,
    this.archivedBy,
    this.reviewStatus,
    this.reviewedByName,
    this.reviewNote,
    this.reviewedAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.duplicateOfVisitId,
    this.allowSameDaySecondVisit,
    this.accuracy,
    this.address,
    this.mapUrl,
    this.locationTimestamp,
  });

  factory CustomerVisit.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
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
      latitude: _toDouble(location?['latitude']),
      longitude: _toDouble(location?['longitude']),
      customerCode: json['customerCode']?.toString() ?? json['customer_code']?.toString(),
      repId: json['repId']?.toString() ?? json['rep_id']?.toString(),
      branchName: json['branchName']?.toString() ?? json['branch_name']?.toString(),
      supervisorId: json['supervisorId']?.toString() ?? json['supervisor_id']?.toString(),
      supervisorName: json['supervisorName']?.toString() ?? json['supervisor_name']?.toString(),
      status: json['status']?.toString(),
      checkInTime: json['checkInTime']?.toString() ?? json['check_in_time']?.toString(),
      checkOutTime: json['checkOutTime']?.toString() ?? json['check_out_time']?.toString(),
      durationMinutes: _toInt(json['durationMinutes'] ?? json['duration_minutes']),
      storeStockStatus: json['storeStockStatus']?.toString() ?? json['store_stock_status']?.toString(),
      competitorNotes: json['competitorNotes']?.toString() ?? json['competitor_notes']?.toString(),
      customerRating: _toInt(json['customerRating'] ?? json['customer_rating']),
      nextVisitDate: json['nextVisitDate']?.toString() ?? json['next_visit_date']?.toString(),
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? json['orderCreatedId']?.toString(),
      orderAmount: _toDouble(json['orderAmount'] ?? json['order_amount']),
      syncStatus: json['syncStatus']?.toString() ?? json['sync_status']?.toString(),
      isReturn: json['isReturn'] as bool? ?? json['is_return'] as bool?,
      returnValue: _toDouble(json['returnValue'] ?? json['return_value']),
      returnReason: json['returnReason']?.toString() ?? json['return_reason']?.toString(),
      returnItems: json['returnItems']?.toString() ?? json['return_items']?.toString(),
      returnStatus: json['returnStatus']?.toString() ?? json['return_status']?.toString(),
      returnHandledBy: json['returnHandledBy']?.toString() ?? json['return_handled_by']?.toString(),
      returnHandledAt: json['returnHandledAt']?.toString() ?? json['return_handled_at']?.toString(),
      returnHandledRole: json['returnHandledRole']?.toString() ?? json['return_handled_role']?.toString(),
      returnNote: json['returnNote']?.toString() ?? json['return_note']?.toString(),
      isArchived: json['isArchived'] as bool? ?? json['is_archived'] as bool?,
      archivedAt: json['archivedAt']?.toString() ?? json['archived_at']?.toString(),
      archivedBy: json['archivedBy']?.toString() ?? json['archived_by']?.toString(),
      reviewStatus: json['reviewStatus']?.toString() ?? json['review_status']?.toString(),
      reviewedByName: json['reviewedByName']?.toString() ?? json['reviewed_by_name']?.toString(),
      reviewNote: json['reviewNote']?.toString() ?? json['review_note']?.toString(),
      reviewedAt: json['reviewedAt']?.toString() ?? json['reviewed_at']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
      duplicateOfVisitId: json['duplicateOfVisitId']?.toString() ?? json['duplicate_of_visit_id']?.toString(),
      allowSameDaySecondVisit: json['allowSameDaySecondVisit'] as bool? ?? json['allow_same_day_second_visit'] as bool?,
      accuracy: _toDouble(json['accuracy'] ?? location?['accuracy']),
      address: json['address']?.toString() ?? location?['address']?.toString(),
      mapUrl: json['mapUrl']?.toString() ?? json['map_url']?.toString() ?? location?['mapUrl']?.toString(),
      locationTimestamp: json['timestamp']?.toString() ?? location?['timestamp']?.toString(),
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
            'accuracy': accuracy,
            'address': address,
            'mapUrl': mapUrl,
            'timestamp': locationTimestamp,
          },
        'customer_code': customerCode,
        'rep_id': repId,
        'branch_name': branchName,
        'supervisor_id': supervisorId,
        'supervisor_name': supervisorName,
        'status': status,
        'check_in_time': checkInTime,
        'check_out_time': checkOutTime,
        'duration_minutes': durationMinutes,
        'store_stock_status': storeStockStatus,
        'competitor_notes': competitorNotes,
        'customer_rating': customerRating,
        'next_visit_date': nextVisitDate,
        'order_id': orderId,
        'order_amount': orderAmount,
        'sync_status': syncStatus,
        'is_return': isReturn,
        'return_value': returnValue,
        'return_reason': returnReason,
        'return_items': returnItems,
        'return_status': returnStatus,
        'return_handled_by': returnHandledBy,
        'return_handled_at': returnHandledAt,
        'return_handled_role': returnHandledRole,
        'return_note': returnNote,
        'is_archived': isArchived,
        'archived_at': archivedAt,
        'archived_by': archivedBy,
        'review_status': reviewStatus,
        'reviewed_by_name': reviewedByName,
        'review_note': reviewNote,
        'reviewed_at': reviewedAt,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'duplicate_of_visit_id': duplicateOfVisitId,
        'allow_same_day_second_visit': allowSameDaySecondVisit,
  };
}

// ============================================================
// === نماذج جديدة تطابق types.ts (React) ===
// ============================================================

/// نموذج متغير/شباك المنتج (ProductVariant في types.ts)
/// يمثل ألوان ونوافذ/شبابيك مرتبطة بمنتج رئيسي
class ProductVariant {
  final String id;
  final String productId;
  final String code;
  final String? unifiedCode;
  final String name;
  final int? windowNumber;
  final String color;
  final String? colorCode;
  final String? imageUrl;
  final int branchStockActual;
  final int branchStockReserved;
  final int mainWarehouseActual;
  final int mainWarehouseReserved;
  final int cartonQuantity;
  final double piecePrice;
  final double cartonPrice;
  final double? promoPrice;
  final double? promoPiecePrice;
  final String status;
  final String? barcode;
  final Product? rawProduct;
  final String? notes;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.code,
    this.unifiedCode,
    required this.name,
    this.windowNumber,
    required this.color,
    this.colorCode,
    this.imageUrl,
    this.branchStockActual = 0,
    this.branchStockReserved = 0,
    this.mainWarehouseActual = 0,
    this.mainWarehouseReserved = 0,
    this.cartonQuantity = 1,
    this.piecePrice = 0,
    this.cartonPrice = 0,
    this.promoPrice,
    this.promoPiecePrice,
    this.status = 'متاح',
    this.barcode,
    this.rawProduct,
    this.notes,
  });

  int get availableStock => (branchStockActual - branchStockReserved).clamp(0, branchStockActual);

  double get effectiveCartonPrice => promoPrice ?? cartonPrice;

  bool get hasPromo => promoPrice != null && promoPrice! > 0 && promoPrice! < cartonPrice;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? json['product_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      unifiedCode: json['unifiedCode']?.toString() ?? json['unified_code']?.toString() ?? json['#']?.toString(),
      name: json['name']?.toString() ?? '',
      windowNumber: _toInt(json['windowNumber'] ?? json['window_number']),
      color: json['color']?.toString() ?? 'أبيض',
      colorCode: json['colorCode']?.toString() ?? json['color_code']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      branchStockActual: (json['branchStockActual'] ?? json['branch_stock_actual'] ?? 0).toInt(),
      branchStockReserved: (json['branchStockReserved'] ?? json['branch_stock_reserved'] ?? 0).toInt(),
      mainWarehouseActual: (json['mainWarehouseActual'] ?? json['main_warehouse_actual'] ?? 0).toInt(),
      mainWarehouseReserved: (json['mainWarehouseReserved'] ?? json['main_warehouse_reserved'] ?? 0).toInt(),
      cartonQuantity: (json['cartonQuantity'] ?? json['factor'] ?? 1).toInt(),
      piecePrice: _toDouble(json['piecePrice'] ?? json['piece_price'] ?? json['salesPrice'] ?? 0) ?? 0,
      cartonPrice: _toDouble(json['cartonPrice'] ?? json['carton_price'] ?? 0) ?? 0,
      promoPrice: _toDouble(json['promoPrice'] ?? json['promo_price']),
      promoPiecePrice: _toDouble(json['promoPiecePrice'] ?? json['promo_piece_price']),
      status: json['status']?.toString() ?? 'متاح',
      barcode: json['barcode']?.toString(),
      rawProduct: json['rawProduct'] != null ? Product.fromJson(json['rawProduct'] as Map<String, dynamic>) : null,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'code': code,
        'unified_code': unifiedCode,
        'name': name,
        'window_number': windowNumber,
        'color': color,
        'color_code': colorCode,
        'image_url': imageUrl,
        'branch_stock_actual': branchStockActual,
        'branch_stock_reserved': branchStockReserved,
        'main_warehouse_actual': mainWarehouseActual,
        'main_warehouse_reserved': mainWarehouseReserved,
        'carton_quantity': cartonQuantity,
        'piece_price': piecePrice,
        'carton_price': cartonPrice,
        'promo_price': promoPrice,
        'promo_piece_price': promoPiecePrice,
        'status': status,
        'barcode': barcode,
        'notes': notes,
      };
}

/// نموذج المنتج الأصلي/المجمع (ParentProduct في types.ts)
/// يجمّع المتغيّرات (الألوان/النوافذ) تحت كود موحد
class ParentProduct {
  final String id;
  final String primaryCode;
  final String? unifiedCode;
  final String name;
  final String department;
  final String category;
  final String? classification;
  final String? familyName;
  final String salesPriority;
  final String status;
  final int cartonQuantity;
  final String? imageUrl;
  final double minPrice;
  final double maxPrice;
  final int totalBranchStock;
  final int totalOctoberStock;
  final List<ProductVariant> variants;
  final int variantsCount;
  final bool hasMultipleVariants;
  final ProductVariant? defaultVariant;

  ParentProduct({
    required this.id,
    required this.primaryCode,
    this.unifiedCode,
    required this.name,
    required this.department,
    required this.category,
    this.classification,
    this.familyName,
    this.salesPriority = 'عادي',
    this.status = 'متاح',
    this.cartonQuantity = 1,
    this.imageUrl,
    this.minPrice = 0,
    this.maxPrice = 0,
    this.totalBranchStock = 0,
    this.totalOctoberStock = 0,
    this.variants = const [],
    this.variantsCount = 0,
    this.hasMultipleVariants = false,
    this.defaultVariant,
  });

  bool get hasPromo => variants.any((v) => v.hasPromo);

  factory ParentProduct.fromJson(Map<String, dynamic> json) {
    final variantsData = json['variants'] as List<dynamic>? ?? [];
    final variants = variantsData.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>)).toList();
    final defaultVariant = variants.isNotEmpty ? variants.firstWhere(
      (v) => v.availableStock > 0,
      orElse: () => variants.first,
    ) : null;

    return ParentProduct(
      id: json['id']?.toString() ?? '',
      primaryCode: json['primaryCode']?.toString() ?? json['primary_code']?.toString() ?? '',
      unifiedCode: json['unifiedCode']?.toString() ?? json['unified_code']?.toString(),
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? 'عام',
      category: json['category']?.toString() ?? '',
      classification: json['classification']?.toString() ?? json['family_name']?.toString(),
      familyName: json['familyName']?.toString() ?? json['family_name']?.toString(),
      salesPriority: json['salesPriority']?.toString() ?? json['sales_priority']?.toString() ?? 'عادي',
      status: json['status']?.toString() ?? 'متاح',
      cartonQuantity: (json['cartonQuantity'] ?? json['factor'] ?? 1).toInt(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      minPrice: _toDouble(json['minPrice'] ?? json['min_price']) ?? 0,
      maxPrice: _toDouble(json['maxPrice'] ?? json['max_price']) ?? 0,
      totalBranchStock: (json['totalBranchStock'] ?? json['total_branch_stock'] ?? 0).toInt(),
      totalOctoberStock: (json['totalOctoberStock'] ?? json['total_october_stock'] ?? 0).toInt(),
      variants: variants,
      variantsCount: variants.length,
      hasMultipleVariants: variants.length > 1,
      defaultVariant: defaultVariant,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'primary_code': primaryCode,
        'unified_code': unifiedCode,
        'name': name,
        'department': department,
        'category': category,
        'classification': classification,
        'family_name': familyName,
        'sales_priority': salesPriority,
        'status': status,
        'carton_quantity': cartonQuantity,
        'image_url': imageUrl,
        'min_price': minPrice,
        'max_price': maxPrice,
        'total_branch_stock': totalBranchStock,
        'total_october_stock': totalOctoberStock,
        'variants': variants.map((v) => v.toJson()).toList(),
        'variants_count': variantsCount,
        'has_multiple_variants': hasMultipleVariants,
      };
}

/// نموذج عرض ترويجي (PromotionOffer في types.ts)
class PromotionOffer {
  final String id;
  final String title;
  final String productCode;
  final String? unifiedCode;
  final String productName;
  final String? category;
  final double discountPercentage;
  final double? promoPrice;
  final double? originalPrice;
  final String? startDate;
  final String? endDate;
  final String? branchName;
  final String status;
  final String? notes;
  final String? createdAt;
  final String? sourceSheet;

  PromotionOffer({
    required this.id,
    required this.title,
    required this.productCode,
    this.unifiedCode,
    required this.productName,
    this.category,
    this.discountPercentage = 0,
    this.promoPrice,
    this.originalPrice,
    this.startDate,
    this.endDate,
    this.branchName,
    this.status = 'نشط',
    this.notes,
    this.createdAt,
    this.sourceSheet,
  });

  bool get isActive => status == 'نشط' && startDate != null && endDate != null &&
      DateTime.now().isAfter(DateTime.tryParse(startDate!) ?? DateTime.now()) &&
      DateTime.now().isBefore(DateTime.tryParse(endDate!)?.add(const Duration(days: 1)) ?? DateTime.now());

  factory PromotionOffer.fromJson(Map<String, dynamic> json) {
    return PromotionOffer(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? json['product_code']?.toString() ?? '',
      unifiedCode: json['unifiedCode']?.toString() ?? json['unified_code']?.toString(),
      productName: json['productName']?.toString() ?? json['product_name']?.toString() ?? '',
      category: json['category']?.toString(),
      discountPercentage: _toDouble(json['discountPercentage'] ?? json['discount_percentage']) ?? 0,
      promoPrice: _toDouble(json['promoPrice'] ?? json['promo_price']),
      originalPrice: _toDouble(json['originalPrice'] ?? json['original_price']),
      startDate: json['startDate']?.toString() ?? json['start_date']?.toString(),
      endDate: json['endDate']?.toString() ?? json['end_date']?.toString(),
      branchName: json['branchName']?.toString() ?? json['branch_name']?.toString(),
      status: json['status']?.toString() ?? 'نشط',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      sourceSheet: json['sourceSheet']?.toString() ?? json['source_sheet']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'product_code': productCode,
        'unified_code': unifiedCode,
        'product_name': productName,
        'category': category,
        'discount_percentage': discountPercentage,
        'promo_price': promoPrice,
        'original_price': originalPrice,
        'start_date': startDate,
        'end_date': endDate,
        'branch_name': branchName,
        'status': status,
        'notes': notes,
        'created_at': createdAt,
        'source_sheet': sourceSheet,
      };
}

// ============================================================
// === أنواع مساعدة وـ Enums إضافية ===
// ============================================================

enum UserApprovalStatus { active, pendingApproval, rejected }

enum CustomerTier { premier, raqi, medium, regular }

enum CustomerVisitStatus { scheduled, executed, canceled, notDone }

enum VisitReviewStatus { pending, approved, needsFix }

enum OrderStatus {
  draft,
  pendingSupervisorReview,
  pendingBranchApproval,
  inReview,
  approvedAndDispatched,
  approved,
  preparing,
  preparingProducts,
  productsArrived,
  shipping,
  delivered,
  closed,
  returned,
  partialReturn,
  rejectedCancelled,
  cancelled,
}

enum PaymentMethod {
  cash,
  credit30Days,
  credit60Days,
  bankTransfer,
  cheque,
}

enum AuditActionType {
  createInvoice,
  updateInvoiceStatus,
  approveInvoice,
  cancelInvoice,
  returnInvoice,
  deleteInvoice,
  importProducts,
  stockAdjustment,
  userLogin,
  createUser,
  updateUser,
}

enum ForecastStatusType { draft, submitted, approved, changeRequested }

enum SyncStatus { synced, pendingSync, localOnly }

String formatOrderStatus(OrderStatus status) {
  switch (status) {
    case OrderStatus.draft:
      return 'مسودة';
    case OrderStatus.pendingSupervisorReview:
      return 'قيد مراجعة المشرف';
    case OrderStatus.pendingBranchApproval:
      return 'معلقة بانتظار اعتماد الفرع';
    case OrderStatus.inReview:
      return 'قيد المراجعة';
    case OrderStatus.approvedAndDispatched:
      return 'معتمدة ومصروفة من المخزن';
    case OrderStatus.approved:
      return 'معتمدة';
    case OrderStatus.preparing:
      return 'جاري التحضير';
    case OrderStatus.preparingProducts:
      return 'جاري تحضير المنتجات';
    case OrderStatus.productsArrived:
      return 'تم وصول المنتجات';
    case OrderStatus.shipping:
      return 'قيد التوصيل';
    case OrderStatus.delivered:
      return 'تم التسليم';
    case OrderStatus.closed:
      return 'إغلاق الطلبية';
    case OrderStatus.returned:
      return 'مرتجع';
    case OrderStatus.partialReturn:
      return 'مرتجع جزئي';
    case OrderStatus.rejectedCancelled:
      return 'مرفوضة / ملغاة';
    case OrderStatus.cancelled:
      return 'ملغاة';
  }
}

String formatPaymentMethod(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'نقدي (كاش)';
    case PaymentMethod.credit30Days:
      return 'آجل (30 يوم)';
    case PaymentMethod.credit60Days:
      return 'آجل (60 يوم)';
    case PaymentMethod.bankTransfer:
      return 'تحويل بنكي';
    case PaymentMethod.cheque:
      return 'شيك';
  }
}

String formatAuditActionType(AuditActionType action) {
  switch (action) {
    case AuditActionType.createInvoice:
      return 'إنشاء فاتورة';
    case AuditActionType.updateInvoiceStatus:
      return 'تحديث حالة الفاتورة';
    case AuditActionType.approveInvoice:
      return 'اعتماد الفاتورة';
    case AuditActionType.cancelInvoice:
      return 'إلغاء الفاتورة';
    case AuditActionType.returnInvoice:
      return 'مرتجع فاتورة';
    case AuditActionType.deleteInvoice:
      return 'حذف الفاتورة';
    case AuditActionType.importProducts:
      return 'استيراد منتجات';
    case AuditActionType.stockAdjustment:
      return 'تعديل مخزون';
    case AuditActionType.userLogin:
      return 'تسجيل دخول';
    case AuditActionType.createUser:
      return 'إنشاء مستخدم';
    case AuditActionType.updateUser:
      return 'تحديث مستخدم';
  }
}

String formatSyncStatus(SyncStatus status) {
  switch (status) {
    case SyncStatus.synced:
      return 'تم المزامنة';
    case SyncStatus.pendingSync:
      return 'معلق المزامنة';
    case SyncStatus.localOnly:
      return 'محلي فقط';
  }
}

// ============================================================
// === Branch (فروع) ===
// ============================================================

class Branch {
  final String id;
  final String name;
  final String code;
  final String city;
  final String address;
  final String managerName;
  final String phone;
  final bool? isMainWarehouse;
  final String? email;
  final List<String>? notificationEmails;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.managerName,
    required this.phone,
    this.isMainWarehouse,
    this.email,
    this.notificationEmails,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      managerName: json['manager_name']?.toString() ?? json['managerName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isMainWarehouse: json['is_main_warehouse'] as bool? ?? json['isMainWarehouse'] as bool?,
      email: json['email']?.toString(),
      notificationEmails: (json['notification_emails'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'city': city,
    'address': address,
    'manager_name': managerName,
    'phone': phone,
    'is_main_warehouse': isMainWarehouse,
    'email': email,
    'notification_emails': notificationEmails,
  };
}

// ============================================================
// === CompanyInfo (معلومات الشركة) ===
// ============================================================

class CompanyInfo {
  final String name;
  final String nameArabic;
  final String nameEnglish;
  final String? commercialNameEn;
  final String taxNumber;
  final String? taxRegistrationNumber;
  final String commercialRegister;
  final String activity;
  final String address;
  final String headquarters;
  final String phone;
  final String customerService;
  final String email;
  final String website;
  final String? logoLetter;
  final String? logoUrl;
  final String? footerNotes;
  final List<String>? notificationEmails;

  CompanyInfo({
    required this.name,
    required this.nameArabic,
    required this.nameEnglish,
    this.commercialNameEn,
    required this.taxNumber,
    this.taxRegistrationNumber,
    required this.commercialRegister,
    required this.activity,
    required this.address,
    required this.headquarters,
    required this.phone,
    required this.customerService,
    required this.email,
    required this.website,
    this.logoLetter,
    this.logoUrl,
    this.footerNotes,
    this.notificationEmails,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name']?.toString() ?? '',
      nameArabic: json['name_arabic']?.toString() ?? json['nameArabic']?.toString() ?? '',
      nameEnglish: json['name_english']?.toString() ?? json['nameEnglish']?.toString() ?? '',
      commercialNameEn: json['commercial_name_en']?.toString() ?? json['commercialNameEn']?.toString(),
      taxNumber: json['tax_number']?.toString() ?? json['taxNumber']?.toString() ?? '',
      taxRegistrationNumber: json['tax_registration_number']?.toString() ?? json['taxRegistrationNumber']?.toString(),
      commercialRegister: json['commercial_register']?.toString() ?? json['commercialRegister']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      headquarters: json['headquarters']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      customerService: json['customer_service']?.toString() ?? json['customerService']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      logoLetter: json['logo_letter']?.toString() ?? json['logoLetter']?.toString(),
      logoUrl: json['logo_url']?.toString() ?? json['logoUrl']?.toString(),
      footerNotes: json['footer_notes']?.toString() ?? json['footerNotes']?.toString(),
      notificationEmails: (json['notification_emails'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'name_arabic': nameArabic,
    'name_english': nameEnglish,
    'commercial_name_en': commercialNameEn,
    'tax_number': taxNumber,
    'tax_registration_number': taxRegistrationNumber,
    'commercial_register': commercialRegister,
    'activity': activity,
    'address': address,
    'headquarters': headquarters,
    'phone': phone,
    'customer_service': customerService,
    'email': email,
    'website': website,
    'logo_letter': logoLetter,
    'logo_url': logoUrl,
    'footer_notes': footerNotes,
    'notification_emails': notificationEmails,
  };
}

// ============================================================
// === ReturnedItem (صنف مرتجع) ===
// ============================================================

class ReturnedItem {
  final String productId;
  final String productCode;
  final String productName;
  final int cartonCount;
  final int pieceCount;
  final int cartonQuantity;
  final int totalPieces;
  final double pricePerCarton;
  final double pricePerPiece;
  final double refundAmount;
  final String? returnReason;
  final String? condition;

  ReturnedItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.cartonCount,
    required this.pieceCount,
    required this.cartonQuantity,
    required this.totalPieces,
    required this.pricePerCarton,
    required this.pricePerPiece,
    required this.refundAmount,
    this.returnReason,
    this.condition = 'good_condition',
  });

  factory ReturnedItem.fromJson(Map<String, dynamic> json) {
    return ReturnedItem(
      productId: json['product_id']?.toString() ?? json['productId']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? json['productCode']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? json['productName']?.toString() ?? '',
      cartonCount: (json['carton_count'] ?? json['cartonCount'] ?? 0).toInt(),
      pieceCount: (json['piece_count'] ?? json['pieceCount'] ?? 0).toInt(),
      cartonQuantity: (json['carton_quantity'] ?? json['cartonQuantity'] ?? 1).toInt(),
      totalPieces: (json['total_pieces'] ?? json['totalPieces'] ?? 0).toInt(),
      pricePerCarton: _toDouble(json['price_per_carton'] ?? json['pricePerCarton']) ?? 0,
      pricePerPiece: _toDouble(json['price_per_piece'] ?? json['pricePerPiece']) ?? 0,
      refundAmount: _toDouble(json['refund_amount'] ?? json['refundAmount']) ?? 0,
      returnReason: json['return_reason']?.toString() ?? json['returnReason']?.toString(),
      condition: json['condition']?.toString() ?? 'good_condition',
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_code': productCode,
    'product_name': productName,
    'carton_count': cartonCount,
    'piece_count': pieceCount,
    'carton_quantity': cartonQuantity,
    'total_pieces': totalPieces,
    'price_per_carton': pricePerCarton,
    'price_per_piece': pricePerPiece,
    'refund_amount': refundAmount,
    'return_reason': returnReason,
    'condition': condition,
  };
}

// ============================================================
// === ReturnRecord (سجل مرتجع) ===
// ============================================================

class ReturnRecord {
  final String id;
  final String returnVoucherNumber;
  final String invoiceId;
  final String invoiceNumber;
  final String customerName;
  final String? customerCode;
  final String branchName;
  final String repName;
  final String date;
  final String time;
  final List<ReturnedItem> returnedItems;
  final double totalRefundAmount;
  final int totalReturnedCartons;
  final int totalReturnedPieces;
  final String reason;
  final String handledBy;
  final bool restockedToInventory;
  final String? notes;

  ReturnRecord({
    required this.id,
    required this.returnVoucherNumber,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    this.customerCode,
    required this.branchName,
    required this.repName,
    required this.date,
    required this.time,
    required this.returnedItems,
    required this.totalRefundAmount,
    this.totalReturnedCartons = 0,
    this.totalReturnedPieces = 0,
    required this.reason,
    required this.handledBy,
    this.restockedToInventory = false,
    this.notes,
  });

  factory ReturnRecord.fromJson(Map<String, dynamic> json) {
    return ReturnRecord(
      id: json['id']?.toString() ?? '',
      returnVoucherNumber: json['returnVoucherNumber']?.toString() ?? json['return_voucher_number']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? json['invoice_id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerCode: json['customer_code']?.toString(),
      branchName: json['branch_name']?.toString() ?? '',
      repName: json['rep_name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      returnedItems: (json['returned_items'] as List<dynamic>? ?? []).map((e) => ReturnedItem.fromJson(e as Map<String, dynamic>)).toList(),
      totalRefundAmount: _toDouble(json['total_refund_amount'] ?? json['totalRefundAmount']) ?? 0,
      totalReturnedCartons: (json['total_returned_cartons'] ?? json['totalReturnedCartons'] ?? 0).toInt(),
      totalReturnedPieces: (json['total_returned_pieces'] ?? json['totalReturnedPieces'] ?? 0).toInt(),
      reason: json['reason']?.toString() ?? '',
      handledBy: json['handled_by']?.toString() ?? json['handledBy']?.toString() ?? '',
      restockedToInventory: json['restocked_to_inventory'] as bool? ?? json['restockedToInventory'] as bool? ?? false,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'return_voucher_number': returnVoucherNumber,
    'invoice_id': invoiceId,
    'invoice_number': invoiceNumber,
    'customer_name': customerName,
    'customer_code': customerCode,
    'branch_name': branchName,
    'rep_name': repName,
    'date': date,
    'time': time,
    'returned_items': returnedItems.map((i) => i.toJson()).toList(),
    'total_refund_amount': totalRefundAmount,
    'total_returned_cartons': totalReturnedCartons,
    'total_returned_pieces': totalReturnedPieces,
    'reason': reason,
    'handled_by': handledBy,
    'restocked_to_inventory': restockedToInventory,
    'notes': notes,
  };
}

// ============================================================
// === InventoryTransaction (معاملة مخزون) ===
// ============================================================

class InventoryTransaction {
  final String id;
  final String timestamp;
  final String date;
  final String productId;
  final String productCode;
  final String productName;
  final String type;
  final int quantityPieces;
  final int branchStockBefore;
  final int branchStockAfter;
  final String branchName;
  final String userName;
  final String userRole;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? notes;

  InventoryTransaction({
    required this.id,
    required this.timestamp,
    required this.date,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.type,
    required this.quantityPieces,
    required this.branchStockBefore,
    required this.branchStockAfter,
    required this.branchName,
    required this.userName,
    required this.userRole,
    this.invoiceId,
    this.invoiceNumber,
    this.notes,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? json['created_at']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? json['productId']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? json['productCode']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? json['productName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      quantityPieces: (json['quantity_pieces'] ?? json['quantityPieces'] ?? 0).toInt(),
      branchStockBefore: (json['branch_stock_before'] ?? json['branchStockBefore'] ?? 0).toInt(),
      branchStockAfter: (json['branch_stock_after'] ?? json['branchStockAfter'] ?? 0).toInt(),
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['userName']?.toString() ?? '',
      userRole: json['user_role']?.toString() ?? json['userRole']?.toString() ?? 'sales_rep',
      invoiceId: json['invoice_id']?.toString() ?? json['invoiceId']?.toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? json['invoiceNumber']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'date': date,
    'product_id': productId,
    'product_code': productCode,
    'product_name': productName,
    'quantity_pieces': quantityPieces,
    'branch_stock_before': branchStockBefore,
    'branch_stock_after': branchStockAfter,
    'branch_name': branchName,
    'user_name': userName,
    'user_role': userRole,
    'invoice_id': invoiceId,
    'invoice_number': invoiceNumber,
    'notes': notes,
  };
}

// ============================================================
// === AuditLog (سجل التدقيق) ===
// ============================================================

class AuditLog {
  final String id;
  final String timestamp;
  final String formattedTime;
  final String userId;
  final String userName;
  final String userRole;
  final String branchName;
  final AuditActionType action;
  final String actionTitle;
  final String details;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? ipAddress;
  final String? badgeType;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.formattedTime,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.branchName,
    required this.action,
    required this.actionTitle,
    required this.details,
    this.invoiceId,
    this.invoiceNumber,
    this.ipAddress,
    this.badgeType,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    final actionStr = json['action']?.toString() ?? '';
    return AuditLog(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      formattedTime: json['formatted_time']?.toString() ?? json['formattedTime']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['userName']?.toString() ?? '',
      userRole: json['user_role']?.toString() ?? json['userRole']?.toString() ?? 'sales_rep',
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? '',
      action: _parseAuditActionType(actionStr),
      actionTitle: json['action_title']?.toString() ?? json['actionTitle']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      invoiceId: json['invoice_id']?.toString() ?? json['invoiceId']?.toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? json['invoiceNumber']?.toString(),
      ipAddress: json['ip_address']?.toString() ?? json['ipAddress']?.toString(),
      badgeType: json['badge_type']?.toString() ?? json['badgeType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'formatted_time': formattedTime,
    'user_id': userId,
    'user_name': userName,
    'user_role': userRole,
    'branch_name': branchName,
    'action': _auditActionTypeToString(action),
    'action_title': actionTitle,
    'details': details,
    'invoice_id': invoiceId,
    'invoice_number': invoiceNumber,
    'ip_address': ipAddress,
    'badge_type': badgeType,
  };
}

AuditActionType _parseAuditActionType(String s) {
  switch (s) {
    case 'create_invoice':
      return AuditActionType.createInvoice;
    case 'update_invoice_status':
      return AuditActionType.updateInvoiceStatus;
    case 'approve_invoice':
      return AuditActionType.approveInvoice;
    case 'cancel_invoice':
      return AuditActionType.cancelInvoice;
    case 'return_invoice':
      return AuditActionType.returnInvoice;
    case 'delete_invoice':
      return AuditActionType.deleteInvoice;
    case 'import_products':
      return AuditActionType.importProducts;
    case 'stock_adjustment':
      return AuditActionType.stockAdjustment;
    case 'user_login':
      return AuditActionType.userLogin;
    case 'create_user':
      return AuditActionType.createUser;
    case 'update_user':
      return AuditActionType.updateUser;
    default:
      return AuditActionType.userLogin;
  }
}

String _auditActionTypeToString(AuditActionType action) {
  switch (action) {
    case AuditActionType.createInvoice:
      return 'create_invoice';
    case AuditActionType.updateInvoiceStatus:
      return 'update_invoice_status';
    case AuditActionType.approveInvoice:
      return 'approve_invoice';
    case AuditActionType.cancelInvoice:
      return 'cancel_invoice';
    case AuditActionType.returnInvoice:
      return 'return_invoice';
    case AuditActionType.deleteInvoice:
      return 'delete_invoice';
    case AuditActionType.importProducts:
      return 'import_products';
    case AuditActionType.stockAdjustment:
      return 'stock_adjustment';
    case AuditActionType.userLogin:
      return 'user_login';
    case AuditActionType.createUser:
      return 'create_user';
    case AuditActionType.updateUser:
      return 'update_user';
  }
}

// ============================================================
// === TargetRecord (سجل هدف مبيعات) ===
// ============================================================

class TargetRecord {
  final String id;
  final String branch;
  final String repName;
  final double salesTarget;
  final double salesAchieved;
  final double salesPercentage;
  final double collectionTarget;
  final double collectionAchieved;
  final double collectionPercentage;
  final String date;
  final int month;
  final int year;
  final String quarter;
  final double remainingSales;
  final double remainingCollection;
  final String? updatedAt;
  final String? notes;

  TargetRecord({
    required this.id,
    required this.branch,
    required this.repName,
    this.salesTarget = 0,
    this.salesAchieved = 0,
    this.salesPercentage = 0,
    this.collectionTarget = 0,
    this.collectionAchieved = 0,
    this.collectionPercentage = 0,
    required this.date,
    this.month = 0,
    this.year = 0,
    this.quarter = 'Q1',
    this.remainingSales = 0,
    this.remainingCollection = 0,
    this.updatedAt,
    this.notes,
  });

  factory TargetRecord.fromJson(Map<String, dynamic> json) {
    return TargetRecord(
      id: json['id']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      repName: json['rep_name']?.toString() ?? json['repName']?.toString() ?? '',
      salesTarget: _toDouble(json['sales_target'] ?? json['salesTarget']) ?? 0,
      salesAchieved: _toDouble(json['sales_achieved'] ?? json['salesAchieved']) ?? 0,
      salesPercentage: _toDouble(json['sales_percentage'] ?? json['salesPercentage']) ?? 0,
      collectionTarget: _toDouble(json['collection_target'] ?? json['collectionTarget']) ?? 0,
      collectionAchieved: _toDouble(json['collection_achieved'] ?? json['collectionAchieved']) ?? 0,
      collectionPercentage: _toDouble(json['collection_percentage'] ?? json['collectionPercentage']) ?? 0,
      date: json['date']?.toString() ?? '',
      month: (json['month'] ?? 0).toInt(),
      year: (json['year'] ?? 0).toInt(),
      quarter: json['quarter']?.toString() ?? 'Q1',
      remainingSales: _toDouble(json['remaining_sales'] ?? json['remainingSales']) ?? 0,
      remainingCollection: _toDouble(json['remaining_collection'] ?? json['remainingCollection']) ?? 0,
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch': branch,
    'rep_name': repName,
    'sales_target': salesTarget,
    'sales_achieved': salesAchieved,
    'sales_percentage': salesPercentage,
    'collection_target': collectionTarget,
    'collection_achieved': collectionAchieved,
    'collection_percentage': collectionPercentage,
    'date': date,
    'month': month,
    'year': year,
    'quarter': quarter,
    'remaining_sales': remainingSales,
    'remaining_collection': remainingCollection,
    'updated_at': updatedAt,
    'notes': notes,
  };
}

// ============================================================
// === CustomerCommentRecord (ملاحظة عميل) ===
// ============================================================

class CustomerCommentRecord {
  final String id;
  final String customerId;
  final String customerCode;
  final String customerName;
  final String branchName;
  final String repName;
  final String kind;
  final String body;
  final String authorName;
  final String createdAt;
  final String? updatedAt;
  final bool? isArchived;
  final String? archivedAt;
  final String? archivedBy;

  CustomerCommentRecord({
    required this.id,
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.branchName,
    required this.repName,
    required this.kind,
    required this.body,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isArchived,
    this.archivedAt,
    this.archivedBy,
  });

  factory CustomerCommentRecord.fromJson(Map<String, dynamic> json) {
    return CustomerCommentRecord(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      customerCode: json['customer_code']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? '',
      repName: json['rep_name']?.toString() ?? json['repName']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'note',
      body: json['body']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? json['authorName']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
      isArchived: json['is_archived'] as bool? ?? json['isArchived'] as bool?,
      archivedAt: json['archived_at']?.toString() ?? json['archivedAt']?.toString(),
      archivedBy: json['archived_by']?.toString() ?? json['archivedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'customer_code': customerCode,
    'customer_name': customerName,
    'branch_name': branchName,
    'rep_name': repName,
    'kind': kind,
    'body': body,
    'author_name': authorName,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'is_archived': isArchived,
    'archived_at': archivedAt,
    'archived_by': archivedBy,
  };
}

// ============================================================
// === Forecast Types (توقع التحصيلات) ===
// ============================================================

class ForecastWeek {
  final int index;
  final String start;
  final String end;
  final String? label;

  ForecastWeek({
    required this.index,
    required this.start,
    required this.end,
    this.label,
  });

  factory ForecastWeek.fromJson(Map<String, dynamic> json) {
    return ForecastWeek(
      index: (json['index'] ?? 0).toInt(),
      start: json['start']?.toString() ?? '',
      end: json['end']?.toString() ?? '',
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'start': start,
    'end': end,
    'label': label,
  };
}

class ForecastMonthPlan {
  final String id;
  final int year;
  final int month;
  final String monthStart;
  final String monthEnd;
  final List<ForecastWeek> weeks;
  final bool isClosed;
  final String? createdBy;
  final String? createdAt;
  final String? updatedBy;
  final String? updatedAt;

  ForecastMonthPlan({
    required this.id,
    required this.year,
    required this.month,
    required this.monthStart,
    required this.monthEnd,
    this.weeks = const [],
    this.isClosed = false,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory ForecastMonthPlan.fromJson(Map<String, dynamic> json) {
    return ForecastMonthPlan(
      id: json['id']?.toString() ?? '',
      year: (json['year'] ?? 0).toInt(),
      month: (json['month'] ?? 0).toInt(),
      monthStart: json['month_start']?.toString() ?? json['monthStart']?.toString() ?? '',
      monthEnd: json['month_end']?.toString() ?? json['monthEnd']?.toString() ?? '',
      weeks: (json['weeks'] as List<dynamic>? ?? []).map((e) => ForecastWeek.fromJson(e as Map<String, dynamic>)).toList(),
      isClosed: json['is_closed'] as bool? ?? json['isClosed'] as bool? ?? false,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedBy: json['updated_by']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'year': year,
    'month': month,
    'month_start': monthStart,
    'month_end': monthEnd,
    'weeks': weeks.map((w) => w.toJson()).toList(),
    'is_closed': isClosed,
    'created_by': createdBy,
    'created_at': createdAt,
    'updated_by': updatedBy,
    'updated_at': updatedAt,
  };
}

class CollectionForecastRecord {
  final String id;
  final String monthKey;
  final int weekIndex;
  final String repId;
  final String repName;
  final String branchName;
  final String customerId;
  final String customerCode;
  final String customerName;
  final double collectionForecast;
  final double salesForecast;
  final ForecastStatusType status;
  final String? submittedAt;
  final String? approvedBy;
  final String? approvedAt;
  final String? changeRequestNote;
  final String? changeRequestedBy;
  final String? changeRequestedAt;
  final String? updatedBy;
  final String? updatedAt;

  CollectionForecastRecord({
    required this.id,
    required this.monthKey,
    this.weekIndex = 0,
    required this.repId,
    required this.repName,
    required this.branchName,
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    this.collectionForecast = 0,
    this.salesForecast = 0,
    this.status = ForecastStatusType.draft,
    this.submittedAt,
    this.approvedBy,
    this.approvedAt,
    this.changeRequestNote,
    this.changeRequestedBy,
    this.changeRequestedAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory CollectionForecastRecord.fromJson(Map<String, dynamic> json) {
    return CollectionForecastRecord(
      id: json['id']?.toString() ?? '',
      monthKey: json['month_key']?.toString() ?? json['monthKey']?.toString() ?? '',
      weekIndex: (json['week_index'] ?? json['weekIndex'] ?? 0).toInt(),
      repId: json['rep_id']?.toString() ?? '',
      repName: json['rep_name']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerCode: json['customer_code']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      collectionForecast: _toDouble(json['collection_forecast'] ?? json['collectionForecast']) ?? 0,
      salesForecast: _toDouble(json['sales_forecast'] ?? json['salesForecast']) ?? 0,
      status: _parseForecastStatus(json['status']?.toString() ?? 'draft'),
      submittedAt: json['submitted_at']?.toString() ?? json['submittedAt']?.toString(),
      approvedBy: json['approved_by']?.toString() ?? json['approvedBy']?.toString(),
      approvedAt: json['approved_at']?.toString() ?? json['approvedAt']?.toString(),
      changeRequestNote: json['change_request_note']?.toString() ?? json['changeRequestNote']?.toString(),
      changeRequestedBy: json['change_requested_by']?.toString() ?? json['changeRequestedBy']?.toString(),
      changeRequestedAt: json['change_requested_at']?.toString() ?? json['changeRequestedAt']?.toString(),
      updatedBy: json['updated_by']?.toString() ?? json['updatedBy']?.toString(),
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'month_key': monthKey,
    'week_index': weekIndex,
    'rep_id': repId,
    'rep_name': repName,
    'branch_name': branchName,
    'customer_id': customerId,
    'customer_code': customerCode,
    'customer_name': customerName,
    'collection_forecast': collectionForecast,
    'sales_forecast': salesForecast,
    'status': _forecastStatusToString(status),
    'submitted_at': submittedAt,
    'approved_by': approvedBy,
    'approved_at': approvedAt,
    'change_request_note': changeRequestNote,
    'change_requested_by': changeRequestedBy,
    'change_requested_at': changeRequestedAt,
    'updated_by': updatedBy,
    'updated_at': updatedAt,
  };
}

ForecastStatusType _parseForecastStatus(String s) {
  switch (s) {
    case 'submitted':
      return ForecastStatusType.submitted;
    case 'approved':
      return ForecastStatusType.approved;
    case 'change_requested':
      return ForecastStatusType.changeRequested;
    case 'draft':
    default:
      return ForecastStatusType.draft;
  }
}

String _forecastStatusToString(ForecastStatusType status) {
  switch (status) {
    case ForecastStatusType.draft:
      return 'draft';
    case ForecastStatusType.submitted:
      return 'submitted';
    case ForecastStatusType.approved:
      return 'approved';
    case ForecastStatusType.changeRequested:
      return 'change_requested';
  }
}

// ============================================================
// === CloudinaryConfig (إعدادات Cloudinary) ===
// ============================================================

class CloudinaryConfig {
  final String cloudName;
  final String folderPrefix;
  final String defaultTransformation;
  final String matchingPattern;
  final String fileExtension;
  final String baseUrlPattern;

  CloudinaryConfig({
    required this.cloudName,
    required this.folderPrefix,
    required this.defaultTransformation,
    required this.matchingPattern,
    required this.fileExtension,
    required this.baseUrlPattern,
  });

  factory CloudinaryConfig.fromJson(Map<String, dynamic> json) {
    return CloudinaryConfig(
      cloudName: json['cloud_name']?.toString() ?? json['cloudName']?.toString() ?? '',
      folderPrefix: json['folder_prefix']?.toString() ?? json['folderPrefix']?.toString() ?? '',
      defaultTransformation: json['default_transformation']?.toString() ?? json['defaultTransformation']?.toString() ?? '',
      matchingPattern: json['matching_pattern']?.toString() ?? json['matchingPattern']?.toString() ?? 'auto',
      fileExtension: json['file_extension']?.toString() ?? json['fileExtension']?.toString() ?? 'jpg',
      baseUrlPattern: json['base_url_pattern']?.toString() ?? json['baseUrlPattern']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'cloud_name': cloudName,
    'folder_prefix': folderPrefix,
    'default_transformation': defaultTransformation,
    'matching_pattern': matchingPattern,
    'file_extension': fileExtension,
    'base_url_pattern': baseUrlPattern,
  };
}

// ============================================================
// === ExcelColumnMapping ===
// ============================================================

class ExcelColumnMapping {
  final String code;
  final String name;
  final String salesPriority;
  final String category;
  final String status;
  final String cartonQuantity;
  final String size;
  final String color;
  final String branchStockActual;
  final String branchStockReserved;
  final String mainWarehouseActual;
  final String mainWarehouseReserved;
  final String department;
  final String classification;
  final String promoPrice;
  final String piecePrice;
  final String cartonPrice;
  final String branchName;
  final String? imageUrl;

  ExcelColumnMapping({
    required this.code,
    required this.name,
    required this.salesPriority,
    required this.category,
    required this.status,
    required this.cartonQuantity,
    required this.size,
    required this.color,
    required this.branchStockActual,
    required this.branchStockReserved,
    required this.mainWarehouseActual,
    required this.mainWarehouseReserved,
    required this.department,
    required this.classification,
    required this.promoPrice,
    required this.piecePrice,
    required this.cartonPrice,
    required this.branchName,
    this.imageUrl,
  });

  factory ExcelColumnMapping.fromJson(Map<String, dynamic> json) {
    return ExcelColumnMapping(
      code: json['code']?.toString() ?? 'A',
      name: json['name']?.toString() ?? 'B',
      salesPriority: json['sales_priority']?.toString() ?? json['salesPriority']?.toString() ?? 'C',
      category: json['category']?.toString() ?? 'D',
      status: json['status']?.toString() ?? 'E',
      cartonQuantity: json['carton_quantity']?.toString() ?? json['cartonQuantity']?.toString() ?? 'F',
      size: json['size']?.toString() ?? 'G',
      color: json['color']?.toString() ?? 'H',
      branchStockActual: json['branch_stock_actual']?.toString() ?? json['branchStockActual']?.toString() ?? 'I',
      branchStockReserved: json['branch_stock_reserved']?.toString() ?? json['branchStockReserved']?.toString() ?? 'J',
      mainWarehouseActual: json['main_warehouse_actual']?.toString() ?? json['mainWarehouseActual']?.toString() ?? 'K',
      mainWarehouseReserved: json['main_warehouse_reserved']?.toString() ?? json['mainWarehouseReserved']?.toString() ?? 'L',
      department: json['department']?.toString() ?? 'M',
      classification: json['classification']?.toString() ?? 'N',
      promoPrice: json['promo_price']?.toString() ?? json['promoPrice']?.toString() ?? 'O',
      piecePrice: json['piece_price']?.toString() ?? json['piecePrice']?.toString() ?? 'P',
      cartonPrice: json['carton_price']?.toString() ?? json['cartonPrice']?.toString() ?? 'Q',
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? 'R',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'sales_priority': salesPriority,
    'category': category,
    'status': status,
    'carton_quantity': cartonQuantity,
    'size': size,
    'color': color,
    'branch_stock_actual': branchStockActual,
    'branch_stock_reserved': branchStockReserved,
    'main_warehouse_actual': mainWarehouseActual,
    'main_warehouse_reserved': mainWarehouseReserved,
    'department': department,
    'classification': classification,
    'promo_price': promoPrice,
    'piece_price': piecePrice,
    'carton_price': cartonPrice,
    'branch_name': branchName,
    'image_url': imageUrl,
  };
}

// ============================================================
// === AccountingSyncLog (سجل مزامنة المحاسبة) ===
// ============================================================

class AccountingSyncLog {
  final String id;
  final String timestamp;
  final String invoiceNumber;
  final String status;
  final String systemName;
  final String responseMessage;

  AccountingSyncLog({
    required this.id,
    required this.timestamp,
    required this.invoiceNumber,
    required this.status,
    required this.systemName,
    required this.responseMessage,
  });

  factory AccountingSyncLog.fromJson(Map<String, dynamic> json) {
    return AccountingSyncLog(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? json['invoiceNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      systemName: json['system_name']?.toString() ?? json['systemName']?.toString() ?? '',
      responseMessage: json['response_message']?.toString() ?? json['responseMessage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'invoice_number': invoiceNumber,
    'status': status,
    'system_name': systemName,
    'response_message': responseMessage,
  };
}

// ============================================================
// === CartItem (عنصر سلة) ===
// ============================================================

class CartItem {
  final Product product;
  final String? unifiedCode;
  final String orderType;
  final int cartonCount;
  final int pieceCount;
  final int? cartonQuantity;
  final int totalPieces;
  final double unitPrice;
  final double? pricePerPiece;
  final double totalPrice;
  final String? quantityDescription;
  final String? notes;
  final bool? fulfillFromMainWarehouse;

  CartItem({
    required this.product,
    this.unifiedCode,
    this.orderType = 'carton',
    this.cartonCount = 0,
    this.pieceCount = 0,
    this.cartonQuantity,
    required this.totalPieces,
    required this.unitPrice,
    this.pricePerPiece,
    required this.totalPrice,
    this.quantityDescription,
    this.notes,
    this.fulfillFromMainWarehouse,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      unifiedCode: json['unified_code']?.toString() ?? json['unifiedCode']?.toString(),
      orderType: json['order_type']?.toString() ?? json['orderType']?.toString() ?? 'carton',
      cartonCount: (json['carton_count'] ?? json['cartonCount'] ?? 0).toInt(),
      pieceCount: (json['piece_count'] ?? json['pieceCount'] ?? 0).toInt(),
      cartonQuantity: _toInt(json['carton_quantity'] ?? json['cartonQuantity']),
      totalPieces: (json['total_pieces'] ?? json['totalPieces'] ?? 0).toInt(),
      unitPrice: _toDouble(json['unit_price'] ?? json['unitPrice']) ?? 0,
      pricePerPiece: _toDouble(json['price_per_piece'] ?? json['pricePerPiece']),
      totalPrice: _toDouble(json['total_price'] ?? json['totalPrice']) ?? 0,
      quantityDescription: json['quantity_description']?.toString() ?? json['quantityDescription']?.toString(),
      notes: json['notes']?.toString(),
      fulfillFromMainWarehouse: json['fulfill_from_main_warehouse'] as bool? ?? json['fulfillFromMainWarehouse'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'unified_code': unifiedCode,
    'order_type': orderType,
    'carton_count': cartonCount,
    'piece_count': pieceCount,
    'carton_quantity': cartonQuantity,
    'total_pieces': totalPieces,
    'unit_price': unitPrice,
    'price_per_piece': pricePerPiece,
    'total_price': totalPrice,
    'quantity_description': quantityDescription,
    'notes': notes,
    'fulfill_from_main_warehouse': fulfillFromMainWarehouse,
  };
}

// ============================================================
// === RepPerformance (أداء المندوب) — لاستخدامه في لوحة المشرف ===
// ============================================================

class RepPerformance {
  final String repId;
  final String repName;
  final String branchName;
  final double sales2026;
  final double collections2026;
  final double salesTarget;
  final double collectionTarget;
  final double salesAchieved;
  final double collectionAchieved;
  final int ordersCount;
  final int visitsCount;
  final int returnsCount;
  final double creditLimitExceededCount;
  final String performanceGrade;

  RepPerformance({
    required this.repId,
    required this.repName,
    required this.branchName,
    this.sales2026 = 0,
    this.collections2026 = 0,
    this.salesTarget = 0,
    this.collectionTarget = 0,
    this.salesAchieved = 0,
    this.collectionAchieved = 0,
    this.ordersCount = 0,
    this.visitsCount = 0,
    this.returnsCount = 0,
    this.creditLimitExceededCount = 0,
    this.performanceGrade = 'متوسط',
  });

  factory RepPerformance.fromJson(Map<String, dynamic> json) {
    return RepPerformance(
      repId: json['rep_id']?.toString() ?? json['repId']?.toString() ?? '',
      repName: json['rep_name']?.toString() ?? json['repName']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? '',
      sales2026: _toDouble(json['sales_2026'] ?? json['sales2026']) ?? 0,
      collections2026: _toDouble(json['collections_2026'] ?? json['collections2026']) ?? 0,
      salesTarget: _toDouble(json['sales_target'] ?? json['salesTarget']) ?? 0,
      collectionTarget: _toDouble(json['collection_target'] ?? json['collectionTarget']) ?? 0,
      salesAchieved: _toDouble(json['sales_achieved'] ?? json['salesAchieved']) ?? 0,
      collectionAchieved: _toDouble(json['collection_achieved'] ?? json['collectionAchieved']) ?? 0,
      ordersCount: (json['orders_count'] ?? json['ordersCount'] ?? 0).toInt(),
      visitsCount: (json['visits_count'] ?? json['visitsCount'] ?? 0).toInt(),
      returnsCount: (json['returns_count'] ?? json['returnsCount'] ?? 0).toInt(),
      creditLimitExceededCount: (_toDouble(json['credit_limit_exceeded_count'] ?? json['creditLimitExceededCount']) ?? 0).toDouble(),
      performanceGrade: json['performance_grade']?.toString() ?? json['performanceGrade']?.toString() ?? 'متوسط',
    );
  }

  Map<String, dynamic> toJson() => {
    'rep_id': repId,
    'rep_name': repName,
    'branch_name': branchName,
    'sales_2026': sales2026,
    'collections_2026': collections2026,
    'sales_target': salesTarget,
    'collection_target': collectionTarget,
    'sales_achieved': salesAchieved,
    'collection_achieved': collectionAchieved,
    'orders_count': ordersCount,
    'visits_count': visitsCount,
    'returns_count': returnsCount,
    'credit_limit_exceeded_count': creditLimitExceededCount,
    'performance_grade': performanceGrade,
  };
}

// ============================================================
// === CustomerAnalytics (تحليلات عملاء) ===
// ============================================================

class CustomerAnalytics {
  final String customerId;
  final String customerName;
  final String customerCode;
  final String branchName;
  final double totalSales;
  final double totalCollections;
  final double balance;
  final double overdueBalance;
  final int ordersCount;
  final int visitsCount;
  final int returnsCount;
  final String lastOrderDate;
  final String lastVisitDate;
  final String? tier;
  final String? status2026;
  final bool hasDealtIn2026;
  final double? annualTarget;
  final double? targetAchievementPercentage;

  CustomerAnalytics({
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.branchName,
    this.totalSales = 0,
    this.totalCollections = 0,
    this.balance = 0,
    this.overdueBalance = 0,
    this.ordersCount = 0,
    this.visitsCount = 0,
    this.returnsCount = 0,
    this.lastOrderDate = '',
    this.lastVisitDate = '',
    this.tier,
    this.status2026,
    this.hasDealtIn2026 = false,
    this.annualTarget,
    this.targetAchievementPercentage,
  });

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerAnalytics(
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString() ?? '',
      customerCode: json['customer_code']?.toString() ?? json['customerCode']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? '',
      totalSales: _toDouble(json['total_sales'] ?? json['totalSales']) ?? 0,
      totalCollections: _toDouble(json['total_collections'] ?? json['totalCollections']) ?? 0,
      balance: _toDouble(json['balance']) ?? 0,
      overdueBalance: _toDouble(json['overdue_balance'] ?? json['overdueBalance']) ?? 0,
      ordersCount: (json['orders_count'] ?? json['ordersCount'] ?? 0).toInt(),
      visitsCount: (json['visits_count'] ?? json['visitsCount'] ?? 0).toInt(),
      returnsCount: (json['returns_count'] ?? json['returnsCount'] ?? 0).toInt(),
      lastOrderDate: json['last_order_date']?.toString() ?? json['lastOrderDate']?.toString() ?? '',
      lastVisitDate: json['last_visit_date']?.toString() ?? json['lastVisitDate']?.toString() ?? '',
      tier: json['tier']?.toString(),
      status2026: json['status_2026']?.toString() ?? json['status2026']?.toString(),
      hasDealtIn2026: json['has_dealt_in_2026'] as bool? ?? json['hasDealtIn2026'] as bool? ?? false,
      annualTarget: _toDouble(json['annual_target'] ?? json['annualTarget']),
      targetAchievementPercentage: _toDouble(json['target_achievement_percentage'] ?? json['targetAchievementPercentage']),
    );
  }

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_code': customerCode,
    'branch_name': branchName,
    'total_sales': totalSales,
    'total_collections': totalCollections,
    'balance': balance,
    'overdue_balance': overdueBalance,
    'orders_count': ordersCount,
    'visits_count': visitsCount,
    'returns_count': returnsCount,
    'last_order_date': lastOrderDate,
    'last_visit_date': lastVisitDate,
    'tier': tier,
    'status_2026': status2026,
    'has_dealt_in_2026': hasDealtIn2026,
    'annual_target': annualTarget,
    'target_achievement_percentage': targetAchievementPercentage,
  };
}

// ===== Offline Queue Models =====

/// نوع العملية المخزّنة في الطابور غير المتصل.
/// تغطي كل العمليات اللي يطلبها المستخدم من غير إنترنت.
enum OfflineActionType {
  salesOrder,
  customerVisit,
  materialRequest,
  customerRegistration,
  expenseClaim,
  vehicleLogEntry,
  returnRequest,
}

/// حالة العنصر في الطابور
enum OfflineItemStatus { pending, processing, failed, completed, skipped }

/// عنصر في طابور المزامنة غير المتصل.
/// يُخزّن في shared_preferences ويُعاد محاكاتها حسب الحاجة.
class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final String branchName;
  final String repName;
  final String repId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final OfflineItemStatus status;
  final String? errorMessage;
  final int retryCount;
  final List<String>? attachedImagePaths;
  final String? serverId;

  OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.branchName,
    required this.repName,
    required this.repId,
    required this.createdAt,
    this.updatedAt,
    this.status = OfflineItemStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
    this.attachedImagePaths,
    this.serverId,
  });

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
        id: json['id']?.toString() ?? '',
        type: OfflineActionType.values.firstWhere(
          (e) => e.name == json['type']?.toString(),
          orElse: () => OfflineActionType.salesOrder,
        ),
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
        branchName: json['branchName']?.toString() ?? '',
        repName: json['repName']?.toString() ?? '',
        repId: json['repId']?.toString() ?? '',
        createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        status: OfflineItemStatus.values.firstWhere(
          (e) => e.name == json['status']?.toString(),
          orElse: () => OfflineItemStatus.pending,
        ),
        errorMessage: json['errorMessage']?.toString(),
        retryCount: (json['retryCount'] ?? 0).toInt(),
        attachedImagePaths: (json['attachedImagePaths'] as List?)?.map((e) => e.toString()).toList(),
        serverId: json['serverId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'branchName': branchName,
        'repName': repName,
        'repId': repId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'status': status.name,
        'errorMessage': errorMessage,
        'retryCount': retryCount,
        'attachedImagePaths': attachedImagePaths,
        'serverId': serverId,
      };
}

/// حالة الاتصال — يُستَخدم في ConnectionStatusBar
enum ConnectionStatus { online, offline, checking, disconnected }

String formatOfflineItemType(OfflineActionType type) {
  switch (type) {
    case OfflineActionType.salesOrder:
      return 'طلب مبيعات';
    case OfflineActionType.customerVisit:
      return 'زيارة عميل';
    case OfflineActionType.materialRequest:
      return 'طلب مواد';
    case OfflineActionType.customerRegistration:
      return 'تسجيل عميل';
    case OfflineActionType.expenseClaim:
      return 'مطالبة بمصروف';
    case OfflineActionType.vehicleLogEntry:
      return 'سجل مركبة';
    case OfflineActionType.returnRequest:
      return 'إرجاع بضاعة';
  }
}

