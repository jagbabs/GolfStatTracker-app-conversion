import React, { useState } from 'react';
import { useLocation } from 'wouter';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Hole, Round } from '@shared/schema';
import { cn } from '@/lib/utils';
import { toast } from '@/hooks/use-toast';
import { Slider } from '@/components/ui/slider';
import { Plus, Minus } from 'lucide-react';

interface HoleResultProps {
  round: Round;
  holeNumber: number;
  totalHoles: number;
  par: number;
  onSaveResult: (score: number, relativeToPar: number, options: HoleOptions) => Promise<void>;
  isLastHole: boolean;
  currentHole?: Hole;
}

interface HoleOptions {
  numPenalties: number;
  upAndDown: boolean;
  sandSave: boolean;
}

const HoleResult: React.FC<HoleResultProps> = ({
  round,
  holeNumber,
  totalHoles,
  par,
  onSaveResult,
  isLastHole,
  currentHole
}) => {
  const [, navigate] = useLocation();
  const [relativeScore, setRelativeScore] = useState<number>(currentHole?.score ? currentHole.score - par : 0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [penaltyStrokes, setPenaltyStrokes] = useState<number>(currentHole?.numPenalties || 0);
  const [upAndDown, setUpAndDown] = useState<boolean>(currentHole?.upAndDown || false);
  const [sandSave, setSandSave] = useState<boolean>(currentHole?.sandSave || false);
  
  // Get score labels
  const getScoreLabel = (relativeScore: number) => {
    switch (relativeScore) {
      case -3: return 'Albatross';
      case -2: return 'Eagle';
      case -1: return 'Birdie';
      case 0: return 'Par';
      case 1: return 'Bogey';
      case 2: return 'Double Bogey';
      case 3: return 'Triple Bogey';
      case 4: return 'Quadruple Bogey';
      default: return relativeScore < 0 ? `${Math.abs(relativeScore)} Under Par` : `${relativeScore} Over Par`;
    }
  };
  
  // Handle relative score change with silent auto-save
  const handleScoreChange = (newRelativeScore: number) => {
    setRelativeScore(newRelativeScore);
    
    // Auto-save after a brief delay without notifications
    setTimeout(async () => {
      // Calculate actual score from par and relative score
      const actualScore = par + newRelativeScore;
      const options: HoleOptions = {
        numPenalties: penaltyStrokes,
        upAndDown,
        sandSave
      };
      
      try {
        await onSaveResult(actualScore, newRelativeScore, options);
      } catch (error) {
        console.error('Error auto-saving score change:', error);
      }
    }, 300);
  };
  
  // Handle penalty strokes change with silent auto-save
  const handlePenaltyChange = (value: string) => {
    const numPenalties = parseInt(value);
    if (!isNaN(numPenalties) && numPenalties >= 0) {
      setPenaltyStrokes(numPenalties);
      
      setTimeout(async () => {
        const actualScore = par + relativeScore;
        const options: HoleOptions = {
          numPenalties,
          upAndDown,
          sandSave
        };
        
        try {
          await onSaveResult(actualScore, relativeScore, options);
        } catch (error) {
          console.error('Error auto-saving penalty change:', error);
        }
      }, 300);
    }
  };
  
  // Save hole result and navigate to next hole
  const handleNextHole = async () => {
    setIsSubmitting(true);
    try {
      // Calculate actual score from par and relative score
      const actualScore = par + relativeScore;
      const options: HoleOptions = {
        numPenalties: penaltyStrokes,
        upAndDown,
        sandSave
      };
      
      // Save the hole result (returns a Promise)
      await onSaveResult(actualScore, relativeScore, options);
      
      // Create a small delay to ensure the state is updated
      await new Promise(resolve => setTimeout(resolve, 300));
      
      // Navigate based on hole position
      if (isLastHole) {
        // If it's the last hole, go to the round summary
        navigate(`/round/${round.id}/summary`);
      } else {
        // Navigate to the next hole
        const nextHoleNumber = holeNumber + 1;
        console.log(`Navigating to next hole: /round/${round.id}/hole/${nextHoleNumber}`);
        navigate(`/round/${round.id}/hole/${nextHoleNumber}`);
      }
    } catch (error) {
      console.error('Error saving hole result:', error);
      toast({
        title: "Error Saving Score",
        description: "There was a problem saving your score. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsSubmitting(false);
    }
  };
  
  // Get the background color based on the relative score
  const getScoreColor = (score: number) => {
    if (score < 0) return "bg-green-500 bg-opacity-20 text-green-600";
    if (score === 0) return "bg-blue-500 bg-opacity-20 text-blue-600";
    if (score === 1) return "bg-yellow-500 bg-opacity-20 text-yellow-700";
    if (score === 2) return "bg-orange-500 bg-opacity-20 text-orange-600";
    return "bg-red-500 bg-opacity-20 text-red-600";
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-4">
      <CardContent className="p-4">
        <h4 className="font-medium text-lg mb-3">Hole Result</h4>
        
        <div className="mb-6">
          <div className="flex justify-between items-center mb-2">
            <div className="font-medium">Par {par} + 
              <span className={cn(
                "ml-1 px-2 py-1 rounded font-semibold",
                getScoreColor(relativeScore)
              )}>
                {relativeScore > 0 ? `+${relativeScore}` : relativeScore}
              </span>
            </div>
            <div className="text-xl font-semibold">{par + relativeScore}</div>
          </div>
          
          <div className="mb-2 text-sm text-gray-600">{getScoreLabel(relativeScore)}</div>
          
          {/* Score selector with increment/decrement */}
          <div className="flex items-center gap-3 mt-4 mb-2">
            <Button 
              type="button"
              variant="outline" 
              size="icon"
              onClick={() => handleScoreChange(Math.max(-3, relativeScore - 1))}
              className="rounded-full w-10 h-10 flex items-center justify-center"
            >
              <Minus size={18} />
            </Button>
            
            <div className="flex-1">
              <Slider
                min={-3}
                max={8}
                step={1}
                value={[relativeScore]}
                onValueChange={(values) => handleScoreChange(values[0])}
                className={cn(
                  "h-4",
                  relativeScore < 0 ? "bg-green-100" : relativeScore === 0 ? "bg-blue-100" : "bg-red-100"
                )}
              />
              
              <div className="flex justify-between text-xs mt-1 px-1">
                <span className="text-center" style={{width: '10%'}}>-3</span>
                <span className="text-center" style={{width: '10%'}}>-2</span>
                <span className="text-center" style={{width: '10%'}}>-1</span>
                <span className="text-center" style={{width: '10%'}}>E</span>
                <span className="text-center" style={{width: '10%'}}>+1</span>
                <span className="text-center" style={{width: '10%'}}>+2</span>
                <span className="text-center" style={{width: '10%'}}>+3</span>
                <span className="text-center" style={{width: '10%'}}>+8</span>
              </div>
            </div>
            
            <Button 
              type="button"
              variant="outline" 
              size="icon"
              onClick={() => handleScoreChange(Math.min(8, relativeScore + 1))}
              className="rounded-full w-10 h-10 flex items-center justify-center"
            >
              <Plus size={18} />
            </Button>
          </div>
        </div>
        
        {/* Additional hole stats */}
        <div className="mb-4 space-y-4">
          {/* Penalty strokes */}
          <div className="flex items-center space-x-2">
            <Label htmlFor="penalty-strokes" className="flex-1">Penalty Strokes:</Label>
            <Input 
              id="penalty-strokes"
              type="number" 
              min="0"
              value={penaltyStrokes}
              onChange={e => handlePenaltyChange(e.target.value)}
              className="w-20 text-center"
            />
          </div>
          
          {/* Up and Down */}
          <div className="flex items-center justify-between">
            <Label htmlFor="up-and-down" className="cursor-pointer">
              Up & Down (Got up and down from off the green)
            </Label>
            <Switch 
              id="up-and-down" 
              checked={upAndDown}
              onCheckedChange={(checked) => {
                setUpAndDown(checked);
                
                setTimeout(async () => {
                  const actualScore = par + relativeScore;
                  const options: HoleOptions = {
                    numPenalties: penaltyStrokes,
                    upAndDown: checked,
                    sandSave
                  };
                  
                  try {
                    await onSaveResult(actualScore, relativeScore, options);
                  } catch (error) {
                    console.error('Error auto-saving up and down change:', error);
                  }
                }, 300);
              }}
            />
          </div>
          
          {/* Sand Save */}
          <div className="flex items-center justify-between">
            <Label htmlFor="sand-save" className="cursor-pointer">
              Sand Save (Got up and down from bunker)
            </Label>
            <Switch 
              id="sand-save" 
              checked={sandSave}
              onCheckedChange={(checked) => {
                setSandSave(checked);
                
                setTimeout(async () => {
                  const actualScore = par + relativeScore;
                  const options: HoleOptions = {
                    numPenalties: penaltyStrokes,
                    upAndDown,
                    sandSave: checked
                  };
                  
                  try {
                    await onSaveResult(actualScore, relativeScore, options);
                  } catch (error) {
                    console.error('Error auto-saving sand save change:', error);
                  }
                }, 300);
              }}
            />
          </div>
        </div>
        
        <div className="flex gap-2">
          <Button 
            type="button" 
            variant="outline"
            className="flex-1 text-[#2D582A] border border-[#2D582A] py-3 rounded-lg font-medium shadow-md hover:bg-[#2D582A] hover:bg-opacity-10"
            onClick={() => navigate(`/round/${round.id}/summary`)}
          >
            View Scorecard
          </Button>
          
          <Button 
            type="button" 
            className="flex-1 bg-[#2D582A] text-white py-3 rounded-lg font-medium shadow-md hover:bg-[#224320]"
            onClick={handleNextHole}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <div className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
            ) : isLastHole ? 'Finish Round' : 'Next Hole'}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default HoleResult;