import React, { useState } from 'react';
import Header from './header';
import BottomNavigation from './bottom-navigation';
import { useLocation } from 'wouter';

interface AppShellProps {
  children: React.ReactNode;
}

const AppShell: React.FC<AppShellProps> = ({ children }) => {
  const [location] = useLocation();
  
  // Check if we're on a hole tracking page (to hide bottom navigation)
  const isHoleTracking = location.includes('/round/') && location.includes('/hole/');

  return (
    <div className="flex flex-col h-screen">
      <Header />
      <main className="flex-1 overflow-y-auto pb-16 md:pb-0">
        {children}
      </main>
      {!isHoleTracking && <BottomNavigation />}
    </div>
  );
};

export default AppShell;
