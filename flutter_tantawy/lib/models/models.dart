// نماذج البيانات لمجموعة الطنطاوي للتجارة والتوزيع - متوافقة 100% مع Supabase
// ومطابقة types.ts (React) — توحيد البنية المشتركة بين Flutter وWeb

double? _toDouble(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
int? _toInt(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));

enum UserRole { admin, branchManager, supervisor, salesRep, developer }

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
      latitude: location?['latitude'] != null ? (location['latitude'] as num).toDouble() : null,
      longitude: location?['longitude'] != null ? (location['longitude'] as num).toDouble() : null,
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
