import React from 'react';
import { useLocation } from 'wouter';
import { cn } from '@/lib/utils';

const Header = () => {
  const [, navigate] = useLocation();

  return (
    <header className="bg-[#2D582A] text-white p-4 shadow-md relative">
      <div className="flex justify-between items-center">
        <div className="flex items-center">
          <span className="material-icons text-2xl mr-2">sports_golf</span>
          <h1 className="text-xl font-display font-semibold">GolfTracker Pro</h1>
        </div>
        <div>
          <button 
            onClick={() => navigate('/profile')}
            className="flex items-center justify-center w-10 h-10 rounded-full bg-[#3A6E37] hover:bg-[#4A7E47] transition-colors"
          >
            <span className="material-icons">person</span>
          </button>
        </div>
      </div>
    </header>
  );
};

export default Header;
