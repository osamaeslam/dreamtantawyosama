import React from 'react';
import { useApp } from './context/AppContext';
import { RoleSwitcherBar } from './components/RoleSwitcherBar';
import { SalesRepMobileApp } from './components/SalesRepMobileApp';
import { AdminWorkflowReviewHub } from './components/AdminWorkflowReviewHub';
import { CustomerDirectoryView } from './components/CustomerDirectoryView';
import { InventoryView } from './components/InventoryView';
import { FieldVisitsManagementHub } from './components/FieldVisitsManagementHub';
import { TargetPerformanceDashboard } from './components/TargetPerformanceDashboard';
import { CollectionForecastView } from './components/CollectionForecastView';
import { DatabaseHubView } from './components/DatabaseHubView';
import { LuxuryLoginPage } from './components/LuxuryLoginPage';
import { ProductLightboxModal } from './components/ProductLightboxModal';
import { ApkDistributionModal } from './components/ApkDistributionModal';
import { LoginModal } from './components/LoginModal';
import { DataManagementModal } from './components/DataManagementModal';

export const AppContent: React.FC = () => {
  const { 
    activeTab, 
    isLoggedIn,
    selectedLightboxProduct, 
    setSelectedLightboxProduct, 
    isApkModalOpen, 
    setIsApkModalOpen,
    isLoginModalOpen,
    setIsLoginModalOpen,
    isDataModalOpen,
    setIsDataModalOpen
  } = useApp();

  // If user is logged out or explicitly navigated to the login screen
  const isViewingLoginPage = !isLoggedIn || activeTab === 'login_screen';

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-['Cairo',sans-serif]">
      {/* Top Navbar with Instant Role Switcher & Navigation Tabs */}
      <RoleSwitcherBar />

      {/* Main Content Area */}
      <main className="flex-1 pb-16">
        {isViewingLoginPage ? (
          <LuxuryLoginPage />
        ) : (
          <>
            {activeTab === 'visits' && <FieldVisitsManagementHub />}
            {activeTab === 'target' && <TargetPerformanceDashboard />}
            {activeTab === 'forecast' && <CollectionForecastView />}
            {activeTab === 'database_hub' && <DatabaseHubView />}
            {activeTab === 'rep_catalog' && <SalesRepMobileApp />}
            {activeTab === 'admin_review' && <AdminWorkflowReviewHub />}
            {activeTab === 'customers' && <CustomerDirectoryView />}
            {activeTab === 'inventory' && <InventoryView />}
          </>
        )}
      </main>

      {/* Modals */}
      {selectedLightboxProduct && (
        <ProductLightboxModal
          product={selectedLightboxProduct}
          onClose={() => setSelectedLightboxProduct(null)}
        />
      )}

      {isApkModalOpen && (
        <ApkDistributionModal
          onClose={() => setIsApkModalOpen(false)}
        />
      )}

      {isLoginModalOpen && (
        <LoginModal
          isOpen={isLoginModalOpen}
          onClose={() => setIsLoginModalOpen(false)}
        />
      )}

      {isDataModalOpen && (
        <DataManagementModal
          isOpen={isDataModalOpen}
          onClose={() => setIsDataModalOpen(false)}
        />
      )}
    </div>
  );
};

export default function App() {
  return <AppContent />;
}
