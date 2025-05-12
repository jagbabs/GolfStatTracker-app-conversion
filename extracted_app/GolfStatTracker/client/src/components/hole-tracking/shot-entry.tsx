import React, { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Slider } from '@/components/ui/slider';
import { Button } from '@/components/ui/button';
import { useClubs } from '@/hooks/use-clubs';
import { Shot } from '@shared/schema';
import { cn } from '@/lib/utils';

interface ShotEntryProps {
  shotType: 'tee' | 'approach' | 'chip' | 'bunker';
  holeId: number;
  shotNumber: number;
  distanceToTarget?: number;
  onSaveShot: (shotData: Partial<Shot>) => void;
  existingShot?: Shot;
}

// Define custom button variant types to add "success" variant
type ExtendedButtonVariant = 'link' | 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'success';

interface OutcomeOption {
  value: string;
  label: string;
  successClass: boolean;
}

const ShotEntry: React.FC<ShotEntryProps> = ({
  shotType,
  holeId,
  shotNumber,
  distanceToTarget,
  onSaveShot,
  existingShot
}) => {
  const { clubs } = useClubs();
  
  // Filter clubs by type appropriate for the shot
  const getAppropriateClubs = () => {
    switch (shotType) {
      case 'tee':
        return clubs.filter(c => ['driver', 'wood', 'iron'].includes(c.type));
      case 'approach':
        return clubs; // All clubs including putter
      case 'chip':
        return clubs.filter(c => ['wedge', 'iron'].includes(c.type));
      case 'bunker':
        return clubs.filter(c => ['wedge'].includes(c.type));
      default:
        return clubs;
    }
  };
  
  const appropriateClubs = getAppropriateClubs();
  
  // Determine title and other UI elements based on shot type
  const getShotTitle = () => {
    switch (shotType) {
      case 'tee': return 'Tee Shot';
      case 'approach': return 'Approach Shot';
      case 'chip': return 'Chip Shot';
      case 'bunker': return 'Bunker Shot';
      default: return 'Shot';
    }
  };
  
  // State for form
  const [selectedClub, setSelectedClub] = useState<number | undefined>(
    existingShot?.clubId || appropriateClubs[0]?.id
  );
  const [shotDistance, setShotDistance] = useState<number>(
    existingShot?.shotDistance || 0
  );
  const [outcome, setOutcome] = useState<string>(
    existingShot?.outcome || (shotType === 'tee' ? 'fairway' : 'green')
  );
  const [direction, setDirection] = useState<string>(
    existingShot?.direction || 'middle-middle'
  );
  
  // Define possible outcomes based on shot type
  const getPossibleOutcomes = (): OutcomeOption[] => {
    switch (shotType) {
      case 'tee':
        return [
          { value: 'fairway', label: 'Fairway Hit', successClass: true },
          { value: 'rough', label: 'Rough', successClass: false },
          { value: 'bunker', label: 'Bunker', successClass: false }
        ];
      case 'approach':
        return [
          { value: 'green', label: 'Green Hit (GIR)', successClass: true },
          { value: 'rough', label: 'Missed Green', successClass: false }
        ];
      default:
        return [
          { value: 'green', label: 'On Green', successClass: true },
          { value: 'rough', label: 'Off Green', successClass: false }
        ];
    }
  };
  
  const outcomes = getPossibleOutcomes();
  
  // Get min/max distance for slider based on shot type
  const getDistanceRange = () => {
    switch (shotType) {
      case 'tee': return { min: 150, max: 350, default: 265 };
      case 'approach': return { min: 50, max: 250, default: 150 };
      case 'chip': return { min: 5, max: 50, default: 20 };
      case 'bunker': return { min: 5, max: 50, default: 15 };
      default: return { min: 0, max: 350, default: 150 };
    }
  };
  
  const distanceRange = getDistanceRange();
  
  // Handle save
  const handleSave = () => {
    const shotData: Partial<Shot> = {
      holeId,
      shotNumber,
      clubId: selectedClub,
      clubName: clubs.find(c => c.id === selectedClub)?.name || 'Unknown Club',
      distanceToTarget,
      shotDistance,
      shotType,
      outcome,
      direction,
      successfulStrike: outcome === 'fairway' || outcome === 'green'
    };
    
    onSaveShot(shotData);
  };

  return (
    <Card className="bg-white rounded-xl shadow-md p-4 mb-4">
      <CardContent className="p-0">
        <h4 className="font-medium text-lg mb-3">{getShotTitle()}</h4>
        
        {/* Club Selection */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-neutral-dark mb-2">Club Selection</label>
          <div className="grid grid-cols-4 gap-2">
            {appropriateClubs.map((club) => (
              <Button
                key={club.id}
                type="button"
                variant={selectedClub === club.id ? 'default' : 'outline'}
                className={`px-3 py-2 ${selectedClub === club.id ? 'bg-[#2D582A]' : ''}`}
                onClick={() => {
                  setSelectedClub(club.id);
                  setTimeout(() => handleSave(), 300);
                }}
              >
                {club.name}
              </Button>
            ))}
          </div>
        </div>
        
        {/* Distance Slider */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-neutral-dark mb-2">
            {distanceToTarget ? 'Shot Distance (yds)' : 'Distance to Target (yds)'}
          </label>
          <div className="flex items-center">
            <Slider
              className="flex-grow"
              min={distanceRange.min}
              max={distanceRange.max}
              step={1}
              value={[shotDistance || distanceRange.default]}
              onValueChange={(values) => {
                setShotDistance(values[0]);
                setTimeout(() => handleSave(), 300);
              }}
            />
            <span className="ml-4 font-medium text-lg min-w-[60px] text-right">
              {shotDistance || distanceRange.default} yds
            </span>
          </div>
        </div>
        
        {/* Shot Outcome */}
        <div className="mb-4">
          <label className="block text-sm font-medium text-neutral-dark mb-2">Shot Outcome</label>
          <div className={`grid grid-cols-${outcomes.length} gap-2`}>
            {outcomes.map((outcomeOption) => (
              <Button
                key={outcomeOption.value}
                type="button"
                variant={outcome === outcomeOption.value ? 'default' : 'outline'}
                className={cn(
                  "px-3 py-3", 
                  outcome === outcomeOption.value && outcomeOption.successClass && "bg-green-100 border border-green-600 text-green-700",
                  outcome === outcomeOption.value && !outcomeOption.successClass && "bg-[#2D582A] text-white"
                )}
                onClick={() => {
                  setOutcome(outcomeOption.value);
                  setTimeout(() => handleSave(), 300);
                }}
              >
                {outcomeOption.label}
              </Button>
            ))}
          </div>
        </div>
        
        {/* Shot Direction (only for tee and approach shots) */}
        {['tee', 'approach'].includes(shotType) && (
          <div>
            <label className="block text-sm font-medium text-neutral-dark mb-2">Shot Direction</label>
            <div className="grid grid-cols-3 gap-2 mb-2">
              <div className="text-center text-sm mb-1 font-medium text-neutral-dark">Distance</div>
              <div className="text-center text-sm mb-1 font-medium text-neutral-dark">Line</div>
              <div className="text-center text-sm mb-1 font-medium text-neutral-dark">Outcome</div>
            </div>
            <div className="grid grid-cols-3 gap-2 mb-3">
              {/* Distance Option */}
              <div className="flex flex-col space-y-2">
                <Button
                  type="button"
                  variant={direction.startsWith('long') ? 'default' : 'outline'}
                  className={`px-2 py-2 ${direction.startsWith('long') ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    const line = direction.includes('left') ? 'left' : direction.includes('right') ? 'right' : 'middle';
                    setDirection(`long-${line}`);
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">add</span>
                  Long
                </Button>
                <Button
                  type="button"
                  variant={direction.startsWith('middle') || direction === 'center' ? 'default' : 'outline'}
                  className={`px-2 py-2 ${direction.startsWith('middle') || direction === 'center' ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    const line = direction.includes('left') ? 'left' : direction.includes('right') ? 'right' : 'middle';
                    setDirection(`middle-${line}`);
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">drag_handle</span>
                  Middle
                </Button>
                <Button
                  type="button"
                  variant={direction.startsWith('short') ? 'default' : 'outline'}
                  className={`px-2 py-2 ${direction.startsWith('short') ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    const line = direction.includes('left') ? 'left' : direction.includes('right') ? 'right' : 'middle';
                    setDirection(`short-${line}`);
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">remove</span>
                  Short
                </Button>
              </div>
              
              {/* Direction Option */}
              <div className="flex flex-col space-y-2">
                <Button
                  type="button"
                  variant={direction.endsWith('left') ? 'default' : 'outline'}
                  className={`px-2 py-2 ${direction.endsWith('left') ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    const distance = direction.startsWith('short') ? 'short' : direction.startsWith('long') ? 'long' : 'middle';
                    setDirection(`${distance}-left`);
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">chevron_left</span>
                  Left
                </Button>
                <Button
                  type="button"
                  variant={direction.endsWith('middle') || direction === 'center' ? 'default' : 'outline'}
                  className={`px-2 py-2 ${direction.endsWith('middle') || direction === 'center' ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    const distance = direction.startsWith('short') ? 'short' : direction.startsWith('long') ? 'long' : 'middle';
                    setDirection(`${distance}-middle`);
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">keyboard_double_arrow_up</span>
                  Center
                </Button>
                <Button
                  type="button"
                  variant={direction.endsWith('right') ? 'default' : 'outline'}
                  className={`px-2 py-2 ${direction.endsWith('right') ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    const distance = direction.startsWith('short') ? 'short' : direction.startsWith('long') ? 'long' : 'middle';
                    setDirection(`${distance}-right`);
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">chevron_right</span>
                  Right
                </Button>
              </div>
              
              {/* Bunker Option */}
              <div className="flex flex-col space-y-2">
                <Button
                  type="button"
                  variant={outcome === 'fairway' || outcome === 'green' ? 'default' : 'outline'}
                  className={cn(
                    "px-2 py-2",
                    (outcome === 'fairway' || outcome === 'green') && "bg-green-100 border border-green-600 text-green-700"
                  )}
                  onClick={() => {
                    setOutcome(shotType === 'tee' ? 'fairway' : 'green');
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">check_circle</span>
                  Good
                </Button>
                <Button
                  type="button"
                  variant={outcome === 'rough' ? 'default' : 'outline'}
                  className={`px-2 py-2 ${outcome === 'rough' ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    setOutcome('rough');
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">grass</span>
                  Rough
                </Button>
                <Button
                  type="button"
                  variant={outcome === 'bunker' ? 'default' : 'outline'}
                  className={`px-2 py-2 ${outcome === 'bunker' ? 'bg-[#2D582A]' : ''}`}
                  onClick={() => {
                    setOutcome('bunker');
                    setTimeout(() => handleSave(), 300);
                  }}
                >
                  <span className="material-icons mr-1 text-sm">waves</span>
                  Bunker
                </Button>
              </div>
            </div>
            
            {/* Visual Indicator */}
            <div className="relative w-full h-[120px] bg-neutral-lightest rounded-lg border border-neutral-light">
              {/* Central fairway line */}
              <div className="absolute left-1/2 top-0 bottom-0 w-1 bg-[#88B04B] transform -translate-x-1/2"></div>
              
              {/* Horizontal dividers for distance sectors */}
              <div className="absolute top-1/3 left-0 right-0 h-[1px] bg-gray-300"></div>
              <div className="absolute top-2/3 left-0 right-0 h-[1px] bg-gray-300"></div>
              
              {/* Shot marker */}
              <div 
                className={`absolute w-6 h-6 bg-[#2D582A] rounded-full flex items-center justify-center
                  ${direction.endsWith('left') ? 'left-[25%]' : direction.endsWith('right') ? 'left-[75%]' : 'left-[50%]'}
                  ${direction.startsWith('short') ? 'top-[83.5%]' : direction.startsWith('long') ? 'top-[16.5%]' : 'top-[50%]'}
                  transform -translate-x-1/2 -translate-y-1/2`}
              >
                <span className="material-icons text-white text-sm">sports_golf</span>
              </div>
              
              {/* Add bunker if applicable */}
              {outcome === 'bunker' && (
                <div className="absolute right-2 bottom-2 text-yellow-600">
                  <span className="material-icons">waves</span>
                </div>
              )}
            </div>
          </div>
        )}
        
        {/* Auto-saves when any control is changed */}
      </CardContent>
    </Card>
  );
};

export default ShotEntry;
