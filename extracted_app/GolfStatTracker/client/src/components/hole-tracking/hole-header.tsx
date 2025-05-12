import React from 'react';
import { Hole } from '@shared/schema';
import { ChevronLeft, ChevronRight, List, ArrowLeft, Flag } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useLocation } from 'wouter';

interface HoleHeaderProps {
  hole: Hole;
  roundId: number;
  totalHoles: number;
  currentHoleNumber?: number; // Allows overriding hole.holeNumber if it doesn't match URL
}

export function HoleHeader({ hole, roundId, totalHoles, currentHoleNumber }: HoleHeaderProps) {
  const [_, navigate] = useLocation();
  
  // Use the provided currentHoleNumber if available, otherwise use hole.holeNumber
  const holeNumber = currentHoleNumber || hole.holeNumber;
  
  const goToPreviousHole = () => {
    if (holeNumber > 1) {
      console.log(`Navigating to previous hole: ${holeNumber - 1}`);
      navigate(`/round/${roundId}/hole/${holeNumber - 1}`);
    }
  };
  
  const goToNextHole = () => {
    if (holeNumber < totalHoles) {
      console.log(`Navigating to next hole: ${holeNumber + 1}`);
      navigate(`/round/${roundId}/hole/${holeNumber + 1}`);
    } else {
      console.log(`Navigating to round summary`);
      navigate(`/round/${roundId}/summary`);
    }
  };
  
  const goToScorecard = () => {
    navigate(`/round/${roundId}/summary`);
  };
  
  const goToRounds = () => {
    navigate('/rounds');
  };
  
  return (
    <div className="bg-[#2D582A] text-white sticky top-0 z-10 shadow-md">
      {/* Subtle top navigation */}
      <div className="flex items-center justify-between px-4 py-2 border-b border-green-700">
        <Button 
          onClick={goToRounds}
          variant="ghost" 
          size="sm"
          className="text-white hover:bg-green-800 p-0 h-auto flex items-center gap-1"
        >
          <ArrowLeft size={14} />
          <span className="text-xs">Rounds</span>
        </Button>
        
        <span className="text-xs font-medium">Round {roundId}</span>
        
        <Button 
          onClick={goToScorecard}
          variant="ghost" 
          size="sm"
          className="text-white hover:bg-green-800 p-0 h-auto flex items-center gap-1"
        >
          <List size={14} />
          <span className="text-xs">Scorecard</span>
        </Button>
      </div>
      
      {/* Hole info and navigation */}
      <div className="p-4 flex items-center justify-between">
        <Button 
          onClick={goToPreviousHole} 
          disabled={holeNumber === 1}
          variant="ghost" 
          className="h-10 w-10 rounded-full p-0 text-white hover:bg-green-800 disabled:opacity-50"
          title="Previous Hole"
        >
          <ChevronLeft size={24} />
        </Button>
        
        <div className="text-center">
          <h1 className="text-2xl font-bold flex items-center justify-center gap-1">
            <Flag size={20} className="inline-block" />
            Hole {holeNumber}
          </h1>
          <div className="text-lg">
            Par {hole.par} • {hole.distance || '—'} yards
          </div>
          <div className="text-xs opacity-80 mt-1 bg-green-800 rounded-full px-3 py-1 inline-block">
            {holeNumber} of {totalHoles}
          </div>
        </div>
        
        <Button 
          onClick={goToNextHole} 
          disabled={holeNumber === totalHoles}
          variant="ghost" 
          className="h-10 w-10 rounded-full p-0 text-white hover:bg-green-800 disabled:opacity-50"
          title="Next Hole"
        >
          <ChevronRight size={24} />
        </Button>
      </div>
      
      {/* Hole navigation bar */}
      <div className="bg-green-700 py-2 px-2 overflow-x-auto">
        <div className="flex gap-1 min-w-max">
          {Array.from({ length: totalHoles }, (_, i) => i + 1).map((holeNum) => (
            <Button
              key={holeNum}
              variant={holeNum === holeNumber ? "default" : "ghost"}
              size="sm"
              className={`w-8 h-8 p-0 rounded-full ${
                holeNum === holeNumber 
                  ? "bg-white text-green-800 font-bold" 
                  : "text-white hover:bg-green-800"
              }`}
              onClick={() => navigate(`/round/${roundId}/hole/${holeNum}`)}
            >
              {holeNum}
            </Button>
          ))}
        </div>
      </div>
    </div>
  );
}