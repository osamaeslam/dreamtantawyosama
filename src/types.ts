// Types for Tantawy Group Sales Management & Mobile App
// 100% Compatible with flutter_tantawy/lib/models/models.dart and Supabase schema

export type UserRole = 'admin' | 'branch_manager' | 'supervisor' | 'sales_rep' | 'developer';

export interface AppUser {
  id: string;
  name: string;
  username: string;
  role: UserRole;
  branchName: string;
  phone: string;
  supervisorName?: string;
  supervisorId?: string;
  email?: string;
  avatar?: string;
  isActive: boolean;
  approvalStatus: string;
  code?: string;
  commissionRate?: number;
  registrationDate?: string;
}

export interface Product {
  id: string;
  code: string;
  name: string;
  department: string;
  category: string;
  piecePrice: number;
  cartonPrice: number;
  promoPrice?: number;
  cartonQuantity: number; // Factor: how many pieces in one carton
  branchStockActual: number;
  branchStockReserved: number;
  mainWarehouseStock: number;
  imageUrl?: string;
  status: string; // 'متاح' | 'منخفض' | 'نفد'
  salesPriority: string; // 'مرتفع' | 'عادي' | 'عرض خاص'
  size?: string;
  color?: string;
  barcode?: string;
  familyName?: string;
  notes?: string;
}

export interface Customer {
  id: string;
  code: string;
  name: string;
  storeName: string;
  phone: string;
  address?: string;
  branchName: string;
  repName?: string;
  currentBalance: number;
  creditLimit: number;
  overdueBalance: number;
  tier: 'A' | 'B' | 'C' | 'VIP';
  governorate?: string;
  region?: string;
  taxNumber?: string;
  lastOrderDate?: string;
  lastCollectionDate?: string;
  notes?: string;
}

export interface InvoiceItem {
  id?: string;
  productId: string;
  productCode: string;
  productName: string;
  unitPrice: number;
  cartonPrice: number;
  quantityCartons: number;
  quantityPieces: number;
  factor: number; // pieces per carton
  totalPieces: number;
  subtotal: number;
  discountPercent?: number;
  total: number;
  notes?: string;
}

export type OrderStatus = 
  | 'مسودة'
  | 'قيد مراجعة المشرف'
  | 'معلقة بانتظار اعتماد الفرع'
  | 'قيد المراجعة'
  | 'معتمدة ومصروفة من المخزن'
  | 'معتمدة'
  | 'ملغاة'
  | 'مرفوضة';

export interface Invoice {
  id: string;
  invoiceNumber: string;
  date: string;
  time?: string;
  customerId: string;
  customerCode: string;
  customerName: string;
  customerPhone?: string;
  branchName: string;
  salesRepId: string;
  salesRepName: string;
  supervisorName?: string;
  supervisorId?: string;
  taxNumber?: string;
  items: InvoiceItem[];
  totalCartons: number;
  totalPieces: number;
  subtotal: number;
  discountAmount: number;
  taxAmount: number;
  totalAmount: number;
  paidAmount: number;
  remainingAmount: number;
  paymentMethod: 'نقدي' | 'آجل' | 'شيك' | 'تحويل بنكي';
  status: OrderStatus;
  notes?: string;
  supervisorNotes?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface CartItem {
  product: Product;
  quantityCartons: number;
  quantityPieces: number;
  unitPrice: number;
  notes?: string;
}

export type VisitType = 
  | 'routine_sale'     // زيارة دورية لطلب بضاعة
  | 'collection'       // تحصيل مديونية أو شيكات
  | 'shelf_audit'      // مراجعة الرفوف والعرض
  | 'complaint'        // شكوى أو مرتجع
  | 'new_lead'         // عميل جديد محتمل
  | 'reconciliation';  // مطابقة كشف حساب

export type VisitOutcome = 
  | 'completed_order'  // تم تحرير طلبية
  | 'collected_cash'   // تم تحصيل مبالغ
  | 'postponed'        // تم التأجيل لموعد آخر
  | 'refused'          // رفض الشراء أو التحصيل
  | 'shop_closed';     // المحل مغلق

export type VisitStatus = 'completed' | 'in_progress' | 'planned' | 'cancelled';

export interface CustomerVisit {
  id: string;
  customerId: string;
  customerName: string;
  customerCode?: string;
  customerPhone?: string;
  customerAddress?: string;
  repName: string;
  repId: string;
  branchName: string;
  date: string;
  time?: string;
  type: VisitType;
  outcome?: VisitOutcome;
  status: VisitStatus;
  collectedAmount: number;
  orderTotal?: number;
  orderId?: string;
  notes?: string;
  latitude?: number;
  longitude?: number;
  locationName?: string;
  checkInTime?: string;
  checkOutTime?: string;
  durationMinutes?: number;
  storeStockStatus?: string;
  competitorNotes?: string;
  rating?: number;
}

export interface TargetRecord {
  id: string;
  branch: string;
  repName: string;
  repId?: string;
  salesTarget: number;
  salesAchieved: number;
  salesPercentage: number;
  collectionTarget: number;
  collectionAchieved: number;
  collectionPercentage: number;
  date: string;
  month: number;
  year: number;
  quarter: string;
  remainingSales: number;
  remainingCollection: number;
  updatedAt?: string;
  notes?: string;
}

export type ForecastStatus = 'draft' | 'submitted' | 'approved' | 'collected' | 'delayed';

export interface CollectionForecastRecord {
  id: string;
  monthKey: string;
  weekIndex: number;
  repId: string;
  repName: string;
  branchName: string;
  customerId: string;
  customerCode: string;
  customerName: string;
  collectionForecast: number;
  salesForecast: number;
  actualCollected?: number;
  status: ForecastStatus;
  notes?: string;
  expectedDate?: string;
  submittedAt: string;
}

export interface SheetConfig {
  offersUrl: string;
  productsUrl: string;
  customersUrl: string;
  targetsUrl: string;
  lastSyncedAt?: string;
  syncCount?: number;
  lastSyncUser?: string;
}

export interface PromoOffer {
  id: string;
  itemCode: string;
  unifiedCode?: string;
  name: string;
  originalPrice: number;
  discountPercentage: number;
  promoPrice: number;
  startDate: string;
  endDate: string;
  minQuantityCartons?: number;
  status: 'active' | 'expired' | 'scheduled';
  notes?: string;
}
