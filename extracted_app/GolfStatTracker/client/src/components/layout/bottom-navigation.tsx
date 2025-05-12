import React from 'react';
import { useLocation, Link } from 'wouter';
import { cn } from '@/lib/utils';

const BottomNavigation = () => {
  const [location] = useLocation();

  const isActive = (path: string) => {
    return location === path;
  };

  const navItems = [
    { label: 'Home', icon: 'home', path: '/' },
    { label: 'Rounds', icon: 'list', path: '/rounds' },
    { label: 'Stats', icon: 'insert_chart', path: '/stats' },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white shadow-lg border-t border-neutral-light">
      <div className="flex justify-around">
        {navItems.map((item) => (
          <Link key={item.path} href={item.path}>
            <a className={cn(
              "flex flex-col items-center py-2 px-4",
              isActive(item.path) ? "text-[#2D582A]" : "text-neutral-medium"
            )}>
              <span className="material-icons">{item.icon}</span>
              <span className="text-xs mt-1">{item.label}</span>
            </a>
          </Link>
        ))}
      </div>
    </nav>
  );
};

export default BottomNavigation;
