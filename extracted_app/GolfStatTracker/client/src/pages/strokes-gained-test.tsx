import React from 'react';
import { useLocation } from 'wouter';
import { Button } from '@/components/ui/button';
import StrokesGainedTestUI from '@/components/stats/strokes-gained-test';
import StrokesGainedChart from '@/components/stats/strokes-gained-chart';

const StrokesGainedTestPage = () => {
  const [, navigate] = useLocation();
  
  return (
    <div className="p-4">
      <div className="mb-4 flex justify-between items-center">
        <h2 className="text-2xl font-display font-semibold text-neutral-darkest">Strokes Gained Test</h2>
        <Button
          variant="outline"
          onClick={() => navigate('/stats')}
          className="flex items-center border border-[#2D582A] text-[#2D582A]"
        >
          <span className="mr-1 text-sm">←</span>
          Back to Stats
        </Button>
      </div>
      
      <StrokesGainedTestUI />

      <div className="mt-8 mb-4">
        <h3 className="text-xl font-display font-semibold text-neutral-darkest">Strokes Gained Visualization</h3>
        <p className="text-neutral-dark">Here's how your strokes gained data will look in charts</p>
      </div>
      
      <StrokesGainedChart />
    </div>
  );
};

export default StrokesGainedTestPage;