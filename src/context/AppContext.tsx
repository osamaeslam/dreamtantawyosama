import React, { createContext, useContext, useState, useEffect } from 'react';
import { AppUser, Customer, Invoice, Product, CartItem, UserRole, CustomerVisit, TargetRecord, CollectionForecastRecord } from '../types';
import { INITIAL_USERS, INITIAL_PRODUCTS, INITIAL_CUSTOMERS, INITIAL_INVOICES, INITIAL_VISITS, INITIAL_TARGETS, INITIAL_FORECASTS } from '../data/mockData';

interface AppContextType {
  currentUser: AppUser;
  setCurrentUser: (user: AppUser) => void;
  isLoggedIn: boolean;
  setIsLoggedIn: (loggedIn: boolean) => void;
  isOnline: boolean;
  switchRole: (role: UserRole) => void;
  login: (username: string, password?: string) => boolean;
  logout: () => void;
  users: AppUser[];
  products: Product[];
  setProducts: React.Dispatch<React.SetStateAction<Product[]>>;
  customers: Customer[];
  setCustomers: React.Dispatch<React.SetStateAction<Customer[]>>;
  invoices: Invoice[];
  visits: CustomerVisit[];
  setVisits: React.Dispatch<React.SetStateAction<CustomerVisit[]>>;
  addVisit: (visit: Omit<CustomerVisit, 'id'>) => CustomerVisit;
  updateVisit: (id: string, updates: Partial<CustomerVisit>) => void;
  deleteVisit: (id: string) => void;
  targets: TargetRecord[];
  setTargets: React.Dispatch<React.SetStateAction<TargetRecord[]>>;
  updateTarget: (id: string, updates: Partial<TargetRecord>) => void;
  forecasts: CollectionForecastRecord[];
  setForecasts: React.Dispatch<React.SetStateAction<CollectionForecastRecord[]>>;
  addForecast: (forecast: Omit<CollectionForecastRecord, 'id' | 'submittedAt'>) => CollectionForecastRecord;
  updateForecast: (id: string, updates: Partial<CollectionForecastRecord>) => void;
  cart: CartItem[];
  addToCart: (product: Product, cartons?: number, pieces?: number) => void;
  removeFromCart: (productId: string) => void;
  updateCartItem: (productId: string, cartons: number, pieces: number) => void;
  clearCart: () => void;
  selectedCustomer: Customer | null;
  setSelectedCustomer: (customer: Customer | null) => void;
  createOrder: (data: Partial<Invoice>) => Invoice;
  approveInvoice: (invoiceId: string, notes?: string) => void;
  rejectInvoice: (invoiceId: string, reason?: string) => void;
  activeTab: string;
  setActiveTab: (tab: string) => void;
  isApkModalOpen: boolean;
  setIsApkModalOpen: (open: boolean) => void;
  isLoginModalOpen: boolean;
  setIsLoginModalOpen: (open: boolean) => void;
  isDataModalOpen: boolean;
  setIsDataModalOpen: (open: boolean) => void;
  selectedLightboxProduct: Product | null;
  setSelectedLightboxProduct: (prod: Product | null) => void;
  totalCartValue: number;
  totalCartItemsCount: number;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [users] = useState<AppUser[]>(INITIAL_USERS);
  
  const [currentUser, setCurrentUser] = useState<AppUser>(() => {
    const saved = localStorage.getItem('tantawy_current_user');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        // fallback
      }
    }
    return INITIAL_USERS[0]; // Starts as Sales Rep
  });

  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(() => {
    const saved = localStorage.getItem('tantawy_is_logged_in');
    return saved !== null ? saved === 'true' : true;
  });

  const [products, setProducts] = useState<Product[]>(() => {
    const saved = localStorage.getItem('tantawy_products');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        // fallback
      }
    }
    return INITIAL_PRODUCTS;
  });

  const [customers, setCustomers] = useState<Customer[]>(() => {
    const saved = localStorage.getItem('tantawy_customers');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        // fallback
      }
    }
    return INITIAL_CUSTOMERS;
  });

  const [invoices, setInvoices] = useState<Invoice[]>(() => {
    const saved = localStorage.getItem('tantawy_invoices');
    return saved ? JSON.parse(saved) : INITIAL_INVOICES;
  });

  const [visits, setVisits] = useState<CustomerVisit[]>(() => {
    const saved = localStorage.getItem('tantawy_visits');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        // fallback
      }
    }
    return INITIAL_VISITS;
  });

  const [isOnline, setIsOnline] = useState<boolean>(typeof navigator !== 'undefined' ? navigator.onLine : true);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const [targets, setTargets] = useState<TargetRecord[]>(() => {
    const saved = localStorage.getItem('tantawy_targets');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {}
    }
    return INITIAL_TARGETS;
  });

  const [forecasts, setForecasts] = useState<CollectionForecastRecord[]>(() => {
    const saved = localStorage.getItem('tantawy_forecasts');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {}
    }
    return INITIAL_FORECASTS;
  });

  const [cart, setCart] = useState<CartItem[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(INITIAL_CUSTOMERS[0]);
  const [activeTab, setActiveTab] = useState<string>('rep_catalog'); // 'rep_catalog' | 'admin_review' | 'customers' | 'inventory' | 'visits' | 'target' | 'forecast' | 'database_hub' | 'login_screen'
  const [isApkModalOpen, setIsApkModalOpen] = useState(false);
  const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);
  const [isDataModalOpen, setIsDataModalOpen] = useState(false);
  const [selectedLightboxProduct, setSelectedLightboxProduct] = useState<Product | null>(null);

  // Sync to localStorage
  useEffect(() => {
    localStorage.setItem('tantawy_current_user', JSON.stringify(currentUser));
  }, [currentUser]);

  useEffect(() => {
    localStorage.setItem('tantawy_is_logged_in', String(isLoggedIn));
  }, [isLoggedIn]);

  useEffect(() => {
    localStorage.setItem('tantawy_products', JSON.stringify(products));
  }, [products]);

  useEffect(() => {
    localStorage.setItem('tantawy_customers', JSON.stringify(customers));
  }, [customers]);

  useEffect(() => {
    localStorage.setItem('tantawy_invoices', JSON.stringify(invoices));
  }, [invoices]);

  useEffect(() => {
    localStorage.setItem('tantawy_visits', JSON.stringify(visits));
  }, [visits]);

  useEffect(() => {
    localStorage.setItem('tantawy_targets', JSON.stringify(targets));
  }, [targets]);

  useEffect(() => {
    localStorage.setItem('tantawy_forecasts', JSON.stringify(forecasts));
  }, [forecasts]);

  const updateTarget = (id: string, updates: Partial<TargetRecord>) => {
    setTargets((prev) => prev.map((t) => (t.id === id ? { ...t, ...updates, updatedAt: new Date().toISOString() } : t)));
  };

  const addForecast = (forecastData: Omit<CollectionForecastRecord, 'id' | 'submittedAt'>): CollectionForecastRecord => {
    const created: CollectionForecastRecord = {
      ...forecastData,
      id: `fc-${Date.now()}`,
      submittedAt: new Date().toISOString(),
    };
    setForecasts((prev) => [created, ...prev]);
    return created;
  };

  const updateForecast = (id: string, updates: Partial<CollectionForecastRecord>) => {
    setForecasts((prev) => prev.map((f) => (f.id === id ? { ...f, ...updates } : f)));
  };

  const switchRole = (role: UserRole) => {
    const matchedUser = users.find((u) => u.role === role) || {
      id: `user-${role}`,
      name: role === 'sales_rep' ? 'أحمد علي النجار' :
            role === 'supervisor' ? 'محمود عبد الله' :
            role === 'branch_manager' ? 'م. طارق الصاوي' : 'الحاج مصطفى الطنطاوي',
      username: `${role}_user`,
      role,
      branchName: 'فرع القاهرة الكبرى',
      phone: '01012345678',
      isActive: true,
      approvalStatus: 'active',
    };
    setCurrentUser(matchedUser);
    setIsLoggedIn(true);

    if (role === 'sales_rep') {
      setActiveTab('rep_catalog');
    } else {
      setActiveTab('admin_review');
    }
  };

  const login = (username: string, _password?: string): boolean => {
    const trimmed = username.trim().toLowerCase();
    setIsLoggedIn(true);

    const found = users.find(
      (u) => u.username.toLowerCase() === trimmed || 
             u.id.toLowerCase() === trimmed || 
             u.role.toLowerCase() === trimmed
    );
    if (found) {
      setCurrentUser(found);
      if (found.role === 'sales_rep') {
        setActiveTab('rep_catalog');
      } else {
        setActiveTab('admin_review');
      }
      return true;
    }

    // Allow custom login for admin/rep keywords
    if (trimmed.includes('admin') || trimmed.includes('مدير')) {
      switchRole('admin');
      return true;
    }
    if (trimmed.includes('sup') || trimmed.includes('مشرف')) {
      switchRole('supervisor');
      return true;
    }
    if (trimmed.includes('rep') || trimmed.includes('مندوب')) {
      switchRole('sales_rep');
      return true;
    }

    // Default match first user
    setCurrentUser(INITIAL_USERS[0]);
    setActiveTab('rep_catalog');
    return true;
  };

  const logout = () => {
    setIsLoggedIn(false);
    setActiveTab('login_screen');
    setIsLoginModalOpen(false);
  };

  const addVisit = (newVisitData: Omit<CustomerVisit, 'id'>): CustomerVisit => {
    const created: CustomerVisit = {
      ...newVisitData,
      id: `vis-${Date.now()}`,
    };
    setVisits((prev) => [created, ...prev]);
    return created;
  };

  const updateVisit = (id: string, updates: Partial<CustomerVisit>) => {
    setVisits((prev) =>
      prev.map((v) => (v.id === id ? { ...v, ...updates } : v))
    );
  };

  const deleteVisit = (id: string) => {
    setVisits((prev) => prev.filter((v) => v.id !== id));
  };

  const addToCart = (product: Product, cartons = 1, pieces = 0) => {
    setCart((prev) => {
      const existing = prev.find((item) => item.product.id === product.id);
      const price = product.promoPrice || product.cartonPrice;
      if (existing) {
        return prev.map((item) =>
          item.product.id === product.id
            ? {
                ...item,
                quantityCartons: item.quantityCartons + cartons,
                quantityPieces: item.quantityPieces + pieces,
              }
            : item
        );
      }
      return [
        ...prev,
        {
          product,
          quantityCartons: cartons,
          quantityPieces: pieces,
          unitPrice: price,
        },
      ];
    });
  };

  const removeFromCart = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.product.id !== productId));
  };

  const updateCartItem = (productId: string, cartons: number, pieces: number) => {
    if (cartons <= 0 && pieces <= 0) {
      removeFromCart(productId);
      return;
    }
    setCart((prev) =>
      prev.map((item) =>
        item.product.id === productId
          ? { ...item, quantityCartons: Math.max(0, cartons), quantityPieces: Math.max(0, pieces) }
          : item
      )
    );
  };

  const clearCart = () => {
    setCart([]);
  };

  const createOrder = (data: Partial<Invoice>): Invoice => {
    const now = new Date();
    const invNumber = data.invoiceNumber || `INV-${now.getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const newInvoice: Invoice = {
      id: data.id || `inv-${Date.now()}`,
      invoiceNumber: invNumber,
      date: data.date || now.toISOString().split('T')[0],
      time: data.time || now.toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' }),
      customerId: data.customerId || selectedCustomer?.id || 'cust-201',
      customerCode: data.customerCode || selectedCustomer?.code || 'CUST-000',
      customerName: data.customerName || selectedCustomer?.name || 'عميل نقدي',
      customerPhone: data.customerPhone || selectedCustomer?.phone,
      branchName: data.branchName || currentUser.branchName || 'فرع القاهرة الكبرى',
      salesRepId: currentUser.id,
      salesRepName: currentUser.name,
      supervisorName: currentUser.supervisorName || 'محمود عبد الله',
      supervisorId: currentUser.supervisorId || 'user-sup-1',
      taxNumber: data.taxNumber || selectedCustomer?.taxNumber,
      items: data.items || [],
      totalCartons: data.totalCartons || 0,
      totalPieces: data.totalPieces || 0,
      subtotal: data.subtotal || 0,
      discountAmount: data.discountAmount || 0,
      taxAmount: data.taxAmount || 0,
      totalAmount: data.totalAmount || 0,
      paidAmount: data.paidAmount || 0,
      remainingAmount: data.remainingAmount ?? (data.totalAmount || 0),
      paymentMethod: data.paymentMethod || 'آجل',
      status: 'قيد مراجعة المشرف', // Forward for supervisor review
      notes: data.notes || '',
      createdAt: now.toISOString(),
    };

    setInvoices((prev) => [newInvoice, ...prev]);
    clearCart();
    return newInvoice;
  };

  const approveInvoice = (invoiceId: string, notes?: string) => {
    setInvoices((prev) =>
      prev.map((inv) =>
        inv.id === invoiceId
          ? {
              ...inv,
              status: 'معتمدة ومصروفة من المخزن',
              supervisorNotes: notes || 'تم الاعتماد والصرف من المخزن',
              updatedAt: new Date().toISOString(),
            }
          : inv
      )
    );
  };

  const rejectInvoice = (invoiceId: string, reason?: string) => {
    setInvoices((prev) =>
      prev.map((inv) =>
        inv.id === invoiceId
          ? {
              ...inv,
              status: 'مرفوضة',
              supervisorNotes: reason || 'مرفوضة من المشرف للتعديل',
              updatedAt: new Date().toISOString(),
            }
          : inv
      )
    );
  };

  const totalCartValue = cart.reduce((acc, item) => {
    const cartonPrice = item.product.promoPrice || item.product.cartonPrice;
    const piecePrice = item.product.piecePrice;
    return acc + item.quantityCartons * cartonPrice + item.quantityPieces * piecePrice;
  }, 0);

  const totalCartItemsCount = cart.reduce((acc, item) => acc + item.quantityCartons, 0);

  return (
    <AppContext.Provider
      value={{
        currentUser,
        setCurrentUser,
        isLoggedIn,
        setIsLoggedIn,
        isOnline,
        switchRole,
        login,
        logout,
        users,
        products,
        setProducts,
        customers,
        setCustomers,
        invoices,
        visits,
        setVisits,
        addVisit,
        updateVisit,
        deleteVisit,
        targets,
        setTargets,
        updateTarget,
        forecasts,
        setForecasts,
        addForecast,
        updateForecast,
        cart,
        addToCart,
        removeFromCart,
        updateCartItem,
        clearCart,
        selectedCustomer,
        setSelectedCustomer,
        createOrder,
        approveInvoice,
        rejectInvoice,
        activeTab,
        setActiveTab,
        isApkModalOpen,
        setIsApkModalOpen,
        isLoginModalOpen,
        setIsLoginModalOpen,
        isDataModalOpen,
        setIsDataModalOpen,
        selectedLightboxProduct,
        setSelectedLightboxProduct,
        totalCartValue,
        totalCartItemsCount,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
};
