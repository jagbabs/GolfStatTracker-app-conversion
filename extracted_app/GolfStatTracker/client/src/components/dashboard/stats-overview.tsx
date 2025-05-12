import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useQuery } from '@tanstack/react-query';
import { Round } from '@shared/schema';
import { 
  calculateFairwayPercentage,
  calculateGIRPercentage,
  calculateAveragePutts,
  getStrokesGainedColor
} from '@/lib/utils';

const StatsOverview = () => {
  const { data: rounds = [] } = useQuery<Round[]>({
    queryKey: ['/api/rounds'],
  });

  // Get the most recent rounds (last 3 months)
  const recentRounds = rounds.filter(round => {
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
    return new Date(round.date) >= threeMonthsAgo;
  });

  // Get the rounds from the previous 3 months for comparison
  const previousPeriodRounds = rounds.filter(round => {
    const sixMonthsAgo = new Date();
    const threeMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
    return new Date(round.date) >= sixMonthsAgo && new Date(round.date) < threeMonthsAgo;
  });

  // Calculate metrics
  const avgDriveDistance = recentRounds.length > 0 
    ? Math.round(recentRounds.reduce((acc, round) => acc + 265, 0) / recentRounds.length)
    : 0;
  
  const prevAvgDriveDistance = previousPeriodRounds.length > 0
    ? Math.round(previousPeriodRounds.reduce((acc, round) => acc + 260, 0) / previousPeriodRounds.length)
    : 0;

  const fairwayHitPercentage = recentRounds.length > 0
    ? calculateFairwayPercentage(
        recentRounds.reduce((acc, round) => acc + (round.fairwaysHit || 0), 0),
        recentRounds.reduce((acc, round) => acc + (round.fairwaysTotal || 0), 0)
      )
    : 0;
  
  const prevFairwayHitPercentage = previousPeriodRounds.length > 0
    ? calculateFairwayPercentage(
        previousPeriodRounds.reduce((acc, round) => acc + (round.fairwaysHit || 0), 0),
        previousPeriodRounds.reduce((acc, round) => acc + (round.fairwaysTotal || 0), 0)
      )
    : 0;

  const girPercentage = recentRounds.length > 0
    ? calculateGIRPercentage(
        recentRounds.reduce((acc, round) => acc + (round.greensInRegulation || 0), 0),
        recentRounds.reduce((acc, round) => acc + 18, 0)
      )
    : 0;
  
  const prevGirPercentage = previousPeriodRounds.length > 0
    ? calculateGIRPercentage(
        previousPeriodRounds.reduce((acc, round) => acc + (round.greensInRegulation || 0), 0),
        previousPeriodRounds.reduce((acc, round) => acc + 18, 0)
      )
    : 0;

  const avgPutts = recentRounds.length > 0
    ? calculateAveragePutts(
        recentRounds.reduce((acc, round) => acc + (round.totalPutts || 0), 0),
        recentRounds.reduce((acc, round) => acc + 18, 0)
      )
    : 0;
  
  const prevAvgPutts = previousPeriodRounds.length > 0
    ? calculateAveragePutts(
        previousPeriodRounds.reduce((acc, round) => acc + (round.totalPutts || 0), 0),
        previousPeriodRounds.reduce((acc, round) => acc + 18, 0)
      )
    : 0;

  // Calculate differences for trends
  const driveDiff = avgDriveDistance - prevAvgDriveDistance;
  const fairwayDiff = fairwayHitPercentage - prevFairwayHitPercentage;
  const girDiff = girPercentage - prevGirPercentage;
  const puttsDiff = prevAvgPutts - avgPutts; // Lower is better for putts

  // Sample strokes gained data (would come from API in real implementation)
  const strokesGained = {
    offTee: 0.7,
    approach: -0.3,
    aroundGreen: 0.2,
    putting: 1.4
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader>
        <CardTitle className="font-display font-medium text-lg">Performance Overview</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div className="bg-neutral-lightest rounded-lg p-3">
            <p className="text-neutral-medium text-sm mb-1">Avg. Drive Distance</p>
            <p className="text-xl font-medium">{avgDriveDistance} yds</p>
            {driveDiff !== 0 && (
              <p className={`text-xs ${driveDiff >= 0 ? 'text-success' : 'text-error'} flex items-center`}>
                <span className="material-icons text-xs mr-1">
                  {driveDiff >= 0 ? 'arrow_upward' : 'arrow_downward'}
                </span>
                {driveDiff >= 0 ? '+' : ''}{driveDiff} yds from last month
              </p>
            )}
          </div>
          <div className="bg-neutral-lightest rounded-lg p-3">
            <p className="text-neutral-medium text-sm mb-1">Fairways Hit</p>
            <p className="text-xl font-medium">{fairwayHitPercentage}%</p>
            {fairwayDiff !== 0 && (
              <p className={`text-xs ${fairwayDiff >= 0 ? 'text-success' : 'text-error'} flex items-center`}>
                <span className="material-icons text-xs mr-1">
                  {fairwayDiff >= 0 ? 'arrow_upward' : 'arrow_downward'}
                </span>
                {fairwayDiff >= 0 ? '+' : ''}{fairwayDiff}% from last month
              </p>
            )}
          </div>
          <div className="bg-neutral-lightest rounded-lg p-3">
            <p className="text-neutral-medium text-sm mb-1">Greens in Regulation</p>
            <p className="text-xl font-medium">{girPercentage}%</p>
            {girDiff !== 0 && (
              <p className={`text-xs ${girDiff >= 0 ? 'text-success' : 'text-error'} flex items-center`}>
                <span className="material-icons text-xs mr-1">
                  {girDiff >= 0 ? 'arrow_upward' : 'arrow_downward'}
                </span>
                {girDiff >= 0 ? '+' : ''}{girDiff}% from last month
              </p>
            )}
          </div>
          <div className="bg-neutral-lightest rounded-lg p-3">
            <p className="text-neutral-medium text-sm mb-1">Avg. Putts Per Round</p>
            <p className="text-xl font-medium">{avgPutts}</p>
            {puttsDiff !== 0 && (
              <p className={`text-xs ${puttsDiff >= 0 ? 'text-success' : 'text-error'} flex items-center`}>
                <span className="material-icons text-xs mr-1">
                  {puttsDiff >= 0 ? 'arrow_upward' : 'arrow_downward'}
                </span>
                {puttsDiff >= 0 ? '+' : ''}{puttsDiff.toFixed(1)} from last month
              </p>
            )}
          </div>
        </div>

        {/* Strokes Gained Section */}
        <div className="mt-6">
          <h4 className="font-medium text-neutral-dark mb-2">Strokes Gained Analysis</h4>
          <div className="relative pt-1">
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm text-neutral-medium">Off the Tee</span>
              <span className={`text-sm font-medium ${getStrokesGainedColor(strokesGained.offTee)}`}>
                {strokesGained.offTee > 0 ? '+' : ''}{strokesGained.offTee.toFixed(1)}
              </span>
            </div>
            <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-neutral-light">
              <div 
                style={{width: `${50 + (strokesGained.offTee * 10)}%`}} 
                className={`shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center ${strokesGained.offTee >= 0 ? 'bg-success' : 'bg-error'}`}>
              </div>
            </div>
            
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm text-neutral-medium">Approach</span>
              <span className={`text-sm font-medium ${getStrokesGainedColor(strokesGained.approach)}`}>
                {strokesGained.approach > 0 ? '+' : ''}{strokesGained.approach.toFixed(1)}
              </span>
            </div>
            <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-neutral-light">
              <div 
                style={{width: `${50 + (strokesGained.approach * 10)}%`}} 
                className={`shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center ${strokesGained.approach >= 0 ? 'bg-success' : 'bg-error'}`}>
              </div>
            </div>
            
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm text-neutral-medium">Around the Green</span>
              <span className={`text-sm font-medium ${getStrokesGainedColor(strokesGained.aroundGreen)}`}>
                {strokesGained.aroundGreen > 0 ? '+' : ''}{strokesGained.aroundGreen.toFixed(1)}
              </span>
            </div>
            <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-neutral-light">
              <div 
                style={{width: `${50 + (strokesGained.aroundGreen * 10)}%`}} 
                className={`shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center ${strokesGained.aroundGreen >= 0 ? 'bg-success' : 'bg-error'}`}>
              </div>
            </div>
            
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm text-neutral-medium">Putting</span>
              <span className={`text-sm font-medium ${getStrokesGainedColor(strokesGained.putting)}`}>
                {strokesGained.putting > 0 ? '+' : ''}{strokesGained.putting.toFixed(1)}
              </span>
            </div>
            <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-neutral-light">
              <div 
                style={{width: `${50 + (strokesGained.putting * 10)}%`}} 
                className={`shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center ${strokesGained.putting >= 0 ? 'bg-success' : 'bg-error'}`}>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default StatsOverview;
