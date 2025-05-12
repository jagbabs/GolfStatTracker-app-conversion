import React, { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Slider } from '@/components/ui/slider';
import { Button } from '@/components/ui/button';
import { Shot } from '@shared/schema';
import { cn } from '@/lib/utils';

interface PuttingEntryProps {
  holeId: number;
  shotNumber: number;
  onSavePutts: (puttsData: Partial<Shot>[]) => void;
  existingPutts?: Shot[];
}

const PuttingEntry: React.FC<PuttingEntryProps> = ({
  holeId,
  shotNumber,
  onSavePutts,
  existingPutts = []
}) => {
  const [numPutts, setNumPutts] = useState<number>(existingPutts.length || 2);
  const [firstPuttDistance, setFirstPuttDistance] = useState<number>(
    existingPutts[0]?.puttLength || 15
  );
  
  const handleNumPuttsSelect = (putts: number) => {
    setNumPutts(putts);
  };
  
  const handleSave = () => {
    const puttsData: Partial<Shot>[] = [];
    
    // First putt
    puttsData.push({
      holeId,
      shotNumber,
      clubId: undefined, // Putt doesn't need club ID
      clubName: 'Putter',
      shotType: 'putt',
      puttLength: firstPuttDistance,
      successfulStrike: numPutts === 1, // If only 1 putt, it was successful
      outcome: numPutts === 1 ? 'hole' : 'lip',
      shotDistance: 0, // Not relevant for putts
    });
    
    // Additional putts if needed
    if (numPutts >= 2) {
      puttsData.push({
        holeId,
        shotNumber: shotNumber + 1,
        clubId: undefined,
        clubName: 'Putter',
        shotType: 'putt',
        puttLength: 3, // Assume short distance for second putt
        successfulStrike: numPutts === 2, // If 2 putts total, second was successful
        outcome: numPutts === 2 ? 'hole' : 'lip',
        shotDistance: 0,
      });
    }
    
    // Third putt if needed
    if (numPutts >= 3) {
      puttsData.push({
        holeId,
        shotNumber: shotNumber + 2,
        clubId: undefined,
        clubName: 'Putter',
        shotType: 'putt',
        puttLength: 1, // Very short distance for third putt
        successfulStrike: true, // Assume third putt goes in
        outcome: 'hole',
        shotDistance: 0,
      });
    }
    
    onSavePutts(puttsData);
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardContent className="p-4">
        <h4 className="font-medium text-lg mb-3">Putting</h4>
        
        <div className="mb-4">
          <label className="block text-sm font-medium text-neutral-dark mb-2">Number of Putts</label>
          <div className="flex justify-center items-center">
            <Button
              type="button"
              variant={numPutts === 1 ? 'default' : 'outline'}
              className={cn(
                "w-12 h-12 rounded-full text-xl font-medium mr-2",
                numPutts === 1 ? "bg-[#2D582A]" : ""
              )}
              onClick={() => {
                handleNumPuttsSelect(1);
                setTimeout(() => handleSave(), 300);
              }}
            >
              1
            </Button>
            <Button
              type="button"
              variant={numPutts === 2 ? 'default' : 'outline'}
              className={cn(
                "w-12 h-12 rounded-full text-xl font-medium mr-2",
                numPutts === 2 ? "bg-[#2D582A]" : ""
              )}
              onClick={() => {
                handleNumPuttsSelect(2);
                setTimeout(() => handleSave(), 300);
              }}
            >
              2
            </Button>
            <Button
              type="button"
              variant={numPutts >= 3 ? 'default' : 'outline'}
              className={cn(
                "w-12 h-12 rounded-full text-xl font-medium",
                numPutts >= 3 ? "bg-[#2D582A]" : ""
              )}
              onClick={() => {
                handleNumPuttsSelect(3);
                setTimeout(() => handleSave(), 300);
              }}
            >
              3+
            </Button>
          </div>
        </div>
        
        <div>
          <label className="block text-sm font-medium text-neutral-dark mb-2">First Putt Distance</label>
          <div className="flex items-center">
            <Slider
              className="flex-grow"
              min={1}
              max={60}
              step={1}
              value={[firstPuttDistance]}
              onValueChange={(values) => {
                setFirstPuttDistance(values[0]);
                setTimeout(() => handleSave(), 300);
              }}
            />
            <span className="ml-4 font-medium text-lg min-w-[60px] text-right">{firstPuttDistance} ft</span>
          </div>
        </div>
        
        {/* Auto-saves when any control is changed */}
      </CardContent>
    </Card>
  );
};

export default PuttingEntry;
