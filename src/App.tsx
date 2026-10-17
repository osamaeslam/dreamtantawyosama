import React, { Component, ErrorInfo } from 'react';
import { Package, WifiOff } from 'lucide-react';
import { LoginPage } from './components/LoginPage';
import { Navbar } from './components/Navbar';
import { AppProvider, useApp } from './context/AppContext';
import { FlutterAppExperience } from './components/FlutterAppExperience';

const MainLayout: React.FC = () => {
  const { isOffline, currentUser, isAuthenticated } = useApp();
  const [activeTab, setActiveTab] = React.useState<string>('flutter_app');

  if (!isAuthenticated || !currentUser) {
    return <LoginPage />;
  }

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col text-slate-100 font-sans antialiased selection:bg-amber-400 selection:text-slate-950">
      
      {/* Offline Status Top Bar if offline */}
      {isOffline && (
        <div className="bg-amber-600 text-white text-xs py-1.5 px-4 text-center font-bold flex items-center justify-center gap-2 shadow-inner">
          <WifiOff className="w-3.5 h-3.5" />
          <span>أنت دون اتصال: البيانات المحفوظة متاحة محلياً وتُزامن عند عودة الإنترنت.</span>
        </div>
      )}

      {/* Main Responsive Navbar */}
      <Navbar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onOpenCart={() => {}}
      />

      {/* Main Flutter Multiplatform Application View - Exclusive */}
      <main className="flex-1 max-w-[1600px] w-full mx-auto px-2 sm:px-4 lg:px-6 py-3 pb-8">
        <FlutterAppExperience />
      </main>
    </div>
  );
};

// ErrorBoundary to catch any runtime exceptions and prevent white screens
interface ErrorBoundaryProps {
  children: React.ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

class MobileErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('App runtime error caught by MobileErrorBoundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-slate-950 text-white flex flex-col items-center justify-center p-6 text-center font-sans">
          <div className="w-16 h-16 rounded-2xl bg-amber-400 text-slate-950 flex items-center justify-center font-black mb-4 shadow-xl">
            <Package className="w-8 h-8" />
          </div>
          <h2 className="text-xl font-black text-amber-300 mb-2">منظومة مجموعة الطنطاوي للتجارة والتوزيع</h2>
          <p className="text-sm text-slate-300 max-w-md mb-6 leading-relaxed">
            حدث خطأ أثناء تحميل التطبيق. أعد تشغيل التطبيق للمحاولة مجدداً.
          </p>
          <button
            onClick={() => {
              this.setState({ hasError: false, error: null });
              window.location.reload();
            }}
            className="bg-amber-400 hover:bg-amber-300 text-slate-950 font-black px-6 py-3 rounded-2xl text-sm shadow-lg transition cursor-pointer active:scale-95"
          >
            إعادة تشغيل التطبيق 🔄
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

export function App() {
  return (
    <MobileErrorBoundary>
      <AppProvider>
        <MainLayout />
      </AppProvider>
    </MobileErrorBoundary>
  );
}

export default App;
