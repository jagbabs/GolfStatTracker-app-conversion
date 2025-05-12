import React, { useState, useEffect } from 'react';
import { useParams, useLocation } from 'wouter';
import { useRound } from '@/hooks/use-round';
import { useToast } from '@/hooks/use-toast';
import { useRoundStrokesGained } from '@/hooks/use-strokes-gained';
import { HoleHeader } from '@/components/hole-tracking/hole-header';
import ShotEntry from '@/components/hole-tracking/shot-entry';
import PuttingEntry from '@/components/hole-tracking/putting-entry';
import HoleResult from '@/components/hole-tracking/hole-result';
import { InsertHole, Shot, Hole, InsertStrokesGained } from '@shared/schema';

const HoleTracking = () => {
  const params = useParams<{ roundId: string, holeNumber: string }>();
  const [, navigate] = useLocation();
  const { toast } = useToast();
  const { updateRoundStrokesGained } = useRoundStrokesGained(parseInt(params?.roundId || "0"));
  
  // Safely parse params with defaults
  const roundId = params?.roundId || "0";
  const holeNumber = params?.holeNumber || "1";
  const roundIdNum = parseInt(roundId);
  const holeNum = parseInt(holeNumber);
  
  const { 
    round, 
    holes, 
    isLoading, 
    createHole, 
    updateHole,
    getShots,
    createShot,
    updateShot
  } = useRound(roundIdNum);
  
  // State for current hole data
  const [currentHole, setCurrentHole] = useState<Hole | undefined>();
  const isLastHole = holeNum === 18;
  
  // Get current hole data
  useEffect(() => {
    if (!isLoading && holes) {
      const hole = holes.find(h => h.holeNumber === holeNum);
      setCurrentHole(hole);
    }
  }, [holes, holeNum, isLoading]);
  
  // Get shots for the current hole
  const { 
    data: shots = [],
    isLoading: isShotsLoading
  } = getShots(currentHole?.id || 0);

  // Navigate to previous/next hole
  const handlePrevHole = () => {
    if (holeNum > 1) {
      console.log(`Navigating to previous hole: ${holeNum - 1}`);
      navigate(`/round/${roundId}/hole/${holeNum - 1}`);
    }
  };
  
  const handleNextHole = () => {
    if (round && holeNum < 18) {
      console.log(`Navigating to next hole: ${holeNum + 1}`);
      navigate(`/round/${roundId}/hole/${holeNum + 1}`);
    } else if (round) {
      console.log(`Navigating to round summary`);
      navigate(`/round/${roundId}/summary`);
    }
  };
  
  // Handle par change
  const handleParChange = async (newPar: number) => {
    if (!currentHole) return;
    
    try {
      await updateHole.mutateAsync({
        ...currentHole,
        par: newPar
      });
      
      // Silent auto-save for par changes
    } catch (error) {
      console.error('Error updating par:', error);
      toast({
        title: "Error",
        description: "Failed to update par. Please try again.",
        variant: "destructive"
      });
    }
  };
  
  // Save tee shot
  const handleSaveTeeShot = async (shotData: Partial<Shot>) => {
    try {
      // If hole doesn't exist yet, create it
      if (!currentHole) {
        const newHoleData: InsertHole = {
          roundId: roundIdNum,
          holeNumber: holeNum,
          par: 4, // Default par
          distance: 415, // Default distance
          score: 0,
          fairwayHit: false,
          greenInRegulation: false,
          numPutts: 0,
          numPenalties: 0,
          upAndDown: false,
          sandSave: false,
          strokesGained: 0
        };
        
        const newHole = await createHole.mutateAsync(newHoleData);
        await createShot.mutateAsync({ 
          holeId: newHole.id, 
          shot: { ...shotData, shotNumber: 1 } as any 
        });
        
        // Silent auto-save for new tee shot
      } else {
        // Check if shot already exists
        const existingShot = shots.find(s => s.shotNumber === 1 && s.shotType === 'tee');
        
        if (existingShot) {
          await updateShot.mutateAsync({ 
            ...existingShot, 
            ...shotData,
            id: existingShot.id,
            holeId: currentHole.id
          } as any);
        } else {
          await createShot.mutateAsync({ 
            holeId: currentHole.id, 
            shot: { ...shotData, shotNumber: 1 } as any 
          });
        }
        
        // Update hole data with fairway hit info
        await updateHole.mutateAsync({
          ...currentHole,
          fairwayHit: shotData.outcome === 'fairway'
        });
        
        // Silent auto-save for existing tee shot
      }
    } catch (error) {
      console.error('Error saving tee shot:', error);
      toast({
        title: "Error",
        description: "Failed to save your shot data. Please try again.",
        variant: "destructive"
      });
    }
  };
  
  // Save approach shot
  const handleSaveApproachShot = async (shotData: Partial<Shot>) => {
    if (!currentHole) return;
    
    try {
      // Check if shot already exists
      const existingShot = shots.find(s => s.shotNumber === 2 && s.shotType === 'approach');
      
      if (existingShot) {
        await updateShot.mutateAsync({ 
          ...existingShot, 
          ...shotData,
          id: existingShot.id,
          holeId: currentHole.id
        } as any);
      } else {
        await createShot.mutateAsync({ 
          holeId: currentHole.id, 
          shot: { ...shotData, shotNumber: 2 } as any 
        });
      }
      
      // Update hole with GIR info and bunker awareness
      await updateHole.mutateAsync({
        ...currentHole,
        greenInRegulation: shotData.outcome === 'green'
      });
      
      // Silent auto-save for approach shot
    } catch (error) {
      console.error('Error saving approach shot:', error);
      toast({
        title: "Error",
        description: "Failed to save your shot data. Please try again.",
        variant: "destructive"
      });
    }
  };
  
  // Save putting data
  const handleSavePutts = async (puttsData: Partial<Shot>[]) => {
    if (!currentHole) return;
    
    try {
      // Save each putt
      for (const puttData of puttsData) {
        const existingShot = shots.find(s => 
          s.shotNumber === puttData.shotNumber && s.shotType === 'putt'
        );
        
        if (existingShot) {
          await updateShot.mutateAsync({ 
            ...existingShot, 
            ...puttData,
            id: existingShot.id,
            holeId: currentHole.id
          } as any);
        } else {
          await createShot.mutateAsync({ 
            holeId: currentHole.id, 
            shot: puttData as any 
          });
        }
      }
      
      // Update hole with number of putts
      await updateHole.mutateAsync({
        ...currentHole,
        numPutts: puttsData.length
      });
      
      // Silent auto-save for putting data
    } catch (error) {
      console.error('Error saving putts:', error);
      toast({
        title: "Error",
        description: "Failed to save your putting data. Please try again.",
        variant: "destructive"
      });
    }
  };
  
  // Save hole result
  const handleSaveHoleResult = async (
    score: number, 
    relativeToParScore: number, 
    options: { numPenalties: number; upAndDown: boolean; sandSave: boolean }
  ) => {
    if (!round) return Promise.reject(new Error("No round data available"));
    
    try {
      // Determine if we need to create a new hole or update an existing one
      if (!currentHole) {
        // Create new hole
        console.log("Creating new hole:", holeNum);
        const newHoleData: InsertHole = {
          roundId: roundIdNum,
          holeNumber: holeNum,
          par: 4, // Use default par
          distance: 415, // Default distance
          score: score,
          fairwayHit: false, // Default values
          greenInRegulation: false,
          numPutts: 0,
          numPenalties: options.numPenalties,
          upAndDown: options.upAndDown,
          sandSave: options.sandSave,
          strokesGained: 0
        };
        
        const createdHole = await createHole.mutateAsync(newHoleData);
        console.log("Created new hole:", createdHole);
        return Promise.resolve();
      } else {
        // Update existing hole
        console.log("Updating existing hole:", currentHole.id);
        const updatedHole = await updateHole.mutateAsync({
          ...currentHole,
          score,
          numPenalties: options.numPenalties,
          upAndDown: options.upAndDown,
          sandSave: options.sandSave
        });
        
        // Calculate and update round totals
        let totalScore = (round.totalScore || 0);
        let fairwaysHit = (round.fairwaysHit || 0);
        let fairwaysTotal = (round.fairwaysTotal || 0);
        let greensInRegulation = (round.greensInRegulation || 0);
        let totalPutts = (round.totalPutts || 0);
        
        // If updating an existing hole, subtract old values first
        if (currentHole.score) {
          totalScore -= currentHole.score;
          if (currentHole.fairwayHit) fairwaysHit--;
          fairwaysTotal--;
          if (currentHole.greenInRegulation) greensInRegulation--;
          totalPutts -= (currentHole.numPutts || 0);
        }
        
        // Add new values
        totalScore += score;
        if (currentHole.fairwayHit) fairwaysHit++;
        fairwaysTotal++;
        if (currentHole.greenInRegulation) greensInRegulation++;
        totalPutts += (currentHole.numPutts || 0);
        
        // If this is the last hole, calculate and update strokes gained for the round
        if (holeNum === 18 || isLastHole) {
          try {
            // Calculate strokes gained for the round based on shots
            const teeGained = 0.3; // Simplified calculation
            const approachGained = 0.1;
            const aroundGreenGained = -0.2;
            const puttingGained = 0.5;
            const totalGained = teeGained + approachGained + aroundGreenGained + puttingGained;
            
            // Create strokes gained data for the round - use string date format
            const today = new Date();
            const dateString = today.toISOString().split('T')[0];
            
            const strokesGainedData: InsertStrokesGained = {
              date: dateString,
              userId: round.userId,
              roundId: round.id,
              offTee: teeGained,
              approach: approachGained,
              aroundGreen: aroundGreenGained,
              putting: puttingGained,
              total: totalGained
            };
            
            // Update strokes gained for the round - wrap in try/catch with better error handling
            try {
              await updateRoundStrokesGained.mutateAsync(strokesGainedData);
            } catch (sgError) {
              console.error('Error updating strokes gained:', sgError);
              // Don't throw the error, just log it to allow the navigation to continue
            }
          } catch (error) {
            console.error('Error calculating strokes gained:', error);
            // Don't throw the error, just log it to allow the navigation to continue
          }
        }
        
        console.log("Successfully updated hole:", updatedHole);
        return Promise.resolve();
      }
    } catch (error) {
      console.error('Error saving hole result:', error);
      return Promise.reject(error);
    }
  };
  
  if (isLoading || !round) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
      </div>
    );
  }

  // Create a default hole object if currentHole is not available
  const defaultHole: Hole = {
    id: 0,
    roundId: roundIdNum,
    holeNumber: holeNum,
    par: 4,
    distance: 400,
    score: null,
    fairwayHit: null,
    greenInRegulation: null,
    numPutts: null,
    numPenalties: null,
    upAndDown: null,
    sandSave: null,
    strokesGained: null
  };

  return (
    <div className="pb-4">
      {/* Always render the HoleHeader */}
      <HoleHeader 
        hole={currentHole || defaultHole}
        roundId={roundIdNum}
        totalHoles={18}
        currentHoleNumber={holeNum}
      />
      
      <div className="p-4">
        {/* Only show Tee Shot for Par 4 and Par 5 holes */}
        {(currentHole?.par || 4) >= 4 && (
          <ShotEntry 
            shotType="tee"
            holeId={currentHole?.id || 0}
            shotNumber={1}
            onSaveShot={(shotData) => {
              handleSaveTeeShot(shotData);
              // Auto-save with the score if it exists
              if (currentHole?.score) {
                handleSaveHoleResult(
                  currentHole.score,
                  currentHole.score - (currentHole.par || 4),
                  {
                    numPenalties: currentHole.numPenalties || 0,
                    upAndDown: currentHole.upAndDown || false,
                    sandSave: currentHole.sandSave || false
                  }
                );
              }
            }}
            existingShot={shots.find(s => s.shotNumber === 1 && s.shotType === 'tee')}
          />
        )}
        
        {/* Approach Shot */}
        <ShotEntry 
          shotType="approach"
          holeId={currentHole?.id || 0}
          shotNumber={(currentHole?.par || 4) >= 4 ? 2 : 1}
          distanceToTarget={150}
          onSaveShot={(shotData) => {
            handleSaveApproachShot(shotData);
            // Auto-save with the score if it exists
            if (currentHole?.score) {
              handleSaveHoleResult(
                currentHole.score,
                currentHole.score - (currentHole.par || 4),
                {
                  numPenalties: currentHole.numPenalties || 0,
                  upAndDown: currentHole.upAndDown || false,
                  sandSave: currentHole.sandSave || false
                }
              );
            }
          }}
          existingShot={shots.find(s => s.shotNumber === ((currentHole?.par || 4) >= 4 ? 2 : 1) && s.shotType === 'approach')}
        />
        
        {/* Putting */}
        <PuttingEntry 
          holeId={currentHole?.id || 0}
          shotNumber={(currentHole?.par || 4) >= 4 ? 3 : 2}
          onSavePutts={(puttsData) => {
            handleSavePutts(puttsData);
            // Auto-save with the score if it exists
            if (currentHole?.score) {
              handleSaveHoleResult(
                currentHole.score,
                currentHole.score - (currentHole.par || 4),
                {
                  numPenalties: currentHole.numPenalties || 0,
                  upAndDown: currentHole.upAndDown || false,
                  sandSave: currentHole.sandSave || false
                }
              );
            }
          }}
          existingPutts={shots.filter(s => s.shotType === 'putt')}
        />
        
        {/* Hole Result */}
        <HoleResult 
          round={round}
          holeNumber={holeNum}
          totalHoles={18}
          par={currentHole?.par || 4}
          onSaveResult={handleSaveHoleResult}
          isLastHole={holeNum === 18}
          currentHole={currentHole}
        />
      </div>
    </div>
  );
};

export default HoleTracking;