import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import { getStrokesGainedColor } from '@/lib/utils';
import { useRoundStrokesGained } from '@/hooks/use-strokes-gained';
import { InsertStrokesGained } from '@shared/schema';

// This component demonstrates how stroke gained data is represented
// It allows generating test data for an existing round
const StrokesGainedTestUI = ({ roundId = 6 }: { roundId?: number }) => {
  const { toast } = useToast();
  const { 
    strokesGained,
    isLoading, 
    updateRoundStrokesGained,
  } = useRoundStrokesGained(roundId);
  
  // Format strokes gained values with sign and rounding
  const formatStrokesGained = (value: number | null): string => {
    if (value === null) return '0.0';
    return value > 0 ? `+${value.toFixed(1)}` : value.toFixed(1);
  };
  
  // Default values if no strokes gained data is available
  const sgData = strokesGained || {
    offTee: 0,
    approach: 0,
    aroundGreen: 0,
    putting: 0,
    total: 0
  };
  
  // Generate positive test data
  const generatePositiveData = async () => {
    try {
      const testData: InsertStrokesGained = {
        date: new Date().toISOString().split('T')[0],
        userId: 1,
        roundId: roundId,
        offTee: 0.8,
        approach: 1.2,
        aroundGreen: 0.3,
        putting: 1.5,
        total: 3.8
      };
      
      await updateRoundStrokesGained.mutateAsync(testData);
      toast({
        title: 'Test Data Generated',
        description: 'Positive strokes gained data has been created successfully.',
      });
    } catch (error) {
      console.error('Error generating test data:', error);
      toast({
        title: 'Error',
        description: 'Failed to generate test data',
        variant: 'destructive',
      });
    }
  };
  
  // Generate mixed test data
  const generateMixedData = async () => {
    try {
      const testData: InsertStrokesGained = {
        date: new Date().toISOString().split('T')[0],
        userId: 1,
        roundId: roundId,
        offTee: 0.7,
        approach: -1.2,
        aroundGreen: 0.4,
        putting: -0.3,
        total: -0.4
      };
      
      await updateRoundStrokesGained.mutateAsync(testData);
      toast({
        title: 'Test Data Generated',
        description: 'Mixed strokes gained data has been created successfully.',
      });
    } catch (error) {
      console.error('Error generating test data:', error);
      toast({
        title: 'Error',
        description: 'Failed to generate test data',
        variant: 'destructive',
      });
    }
  };
  
  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader>
        <CardTitle>Strokes Gained Test</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="mb-4 space-y-2">
          <p>This component demonstrates how strokes gained data is represented in the app.</p>
          <p>Current round ID: {roundId}</p>
          <div className="flex space-x-2 mt-4">
            <Button onClick={generatePositiveData}>
              Generate Positive Data
            </Button>
            <Button onClick={generateMixedData}>
              Generate Mixed Data
            </Button>
          </div>
        </div>
        
        <h3 className="text-xl font-semibold mb-4 mt-8">Current Strokes Gained Data</h3>
        {isLoading ? (
          <div className="py-8 flex items-center justify-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
          </div>
        ) : (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-neutral-lightest p-3 rounded-lg">
                <div className="text-sm text-neutral-medium">Off the Tee</div>
                <div className={`text-lg font-medium ${getStrokesGainedColor(sgData.offTee)}`}>
                  {formatStrokesGained(sgData.offTee)}
                </div>
              </div>
              <div className="bg-neutral-lightest p-3 rounded-lg">
                <div className="text-sm text-neutral-medium">Approach</div>
                <div className={`text-lg font-medium ${getStrokesGainedColor(sgData.approach)}`}>
                  {formatStrokesGained(sgData.approach)}
                </div>
              </div>
              <div className="bg-neutral-lightest p-3 rounded-lg">
                <div className="text-sm text-neutral-medium">Around Green</div>
                <div className={`text-lg font-medium ${getStrokesGainedColor(sgData.aroundGreen)}`}>
                  {formatStrokesGained(sgData.aroundGreen)}
                </div>
              </div>
              <div className="bg-neutral-lightest p-3 rounded-lg">
                <div className="text-sm text-neutral-medium">Putting</div>
                <div className={`text-lg font-medium ${getStrokesGainedColor(sgData.putting)}`}>
                  {formatStrokesGained(sgData.putting)}
                </div>
              </div>
            </div>
            <div className="bg-neutral-lightest p-3 rounded-lg">
              <div className="text-sm text-neutral-medium">Total Strokes Gained</div>
              <div className={`text-xl font-semibold ${getStrokesGainedColor(sgData.total)}`}>
                {formatStrokesGained(sgData.total)}
              </div>
            </div>
          </div>
        )}
        
        <div className="mt-8 p-4 border rounded-lg bg-gray-50">
          <h4 className="font-medium mb-2">How Strokes Gained Works</h4>
          <p className="text-sm text-gray-600 mb-2">
            Strokes gained measures player performance against a baseline of expected scores from different positions.
          </p>
          <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
            <li><span className="font-medium">Off the Tee</span>: Measures tee shot performance</li>
            <li><span className="font-medium">Approach</span>: Measures approach shots to the green</li>
            <li><span className="font-medium">Around Green</span>: Measures chips, pitches, and bunker shots</li>
            <li><span className="font-medium">Putting</span>: Measures putting performance on the green</li>
            <li><span className="font-medium">Total</span>: Sum of all strokes gained categories</li>
          </ul>
          <p className="text-sm text-gray-600 mt-2">
            Positive values indicate better than average performance, negative values indicate worse than average.
          </p>
        </div>
      </CardContent>
    </Card>
  );
};

export default StrokesGainedTestUI;