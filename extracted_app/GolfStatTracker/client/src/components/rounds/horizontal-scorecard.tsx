import React from 'react';
import { Hole, Round } from '@shared/schema';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { CheckIcon, XIcon, ArrowRightIcon } from 'lucide-react';

interface HorizontalScorecardProps {
  round: Round;
  holes: Hole[];
}

export function HorizontalScorecard({ round, holes }: HorizontalScorecardProps) {
  // Calculate totals and stats
  const totalFairwaysHit = holes.filter(h => h.fairwayHit).length;
  const totalFairwaysPlayed = holes.filter(h => h.fairwayHit !== null).length;
  const fairwayPercentage = totalFairwaysPlayed > 0 
    ? Math.round((totalFairwaysHit / totalFairwaysPlayed) * 100) 
    : 0;
  
  const totalGIR = holes.filter(h => h.greenInRegulation).length;
  const totalGIRPlayed = holes.filter(h => h.greenInRegulation !== null).length;
  const girPercentage = totalGIRPlayed > 0 
    ? Math.round((totalGIR / totalGIRPlayed) * 100) 
    : 0;
  
  const totalPutts = holes.reduce((sum, hole) => sum + (hole.numPutts || 0), 0);
  const holesWithPutts = holes.filter(h => h.numPutts !== null && h.numPutts > 0).length;
  const puttingAvg = holesWithPutts > 0 
    ? (totalPutts / holesWithPutts).toFixed(1) 
    : '-';
  
  // Color coding for scores based on par
  const getScoreStyle = (score: number | null, par: number) => {
    if (!score) return { backgroundColor: 'transparent', color: 'black' };
    
    if (score === par - 2) return { backgroundColor: '#9333ea', color: 'white' }; // Eagle - purple
    if (score === par - 1) return { backgroundColor: '#ef4444', color: 'white' }; // Birdie - red
    if (score === par) return { backgroundColor: 'transparent', color: 'black' }; // Par - no color
    if (score === par + 1) return { backgroundColor: '#3b82f6', color: 'white' }; // Bogey - blue
    if (score > par + 1) return { backgroundColor: '#1d4ed8', color: 'white' }; // Double+ - dark blue
    
    return { backgroundColor: 'transparent', color: 'black' };
  };

  // Sorted holes for the scorecard
  const sortedHoles = [...holes].sort((a, b) => a.holeNumber - b.holeNumber);

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="pb-2">
          <Tabs defaultValue="scorecard">
            <div className="flex justify-between items-center">
              <TabsList>
                <TabsTrigger value="scorecard" className="text-base">Scorecard</TabsTrigger>
                <TabsTrigger value="stats" className="text-base">Stats</TabsTrigger>
              </TabsList>
              <a href="#" className="text-blue-600 text-sm">See Overall Stats</a>
            </div>
            
            {/* Stats Summary Section */}
            <TabsContent value="stats" className="mt-4">
              <div className="grid grid-cols-3 gap-4 text-center">
                <div className="flex flex-col items-center">
                  <div className="text-2xl font-bold">{puttingAvg}</div>
                  <div className="text-sm text-gray-500">({totalPutts})</div>
                  <div className="text-sm">Putting Avg</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-2xl font-bold">{fairwayPercentage}%</div>
                  <div className="text-sm text-gray-500">({totalFairwaysHit}/{totalFairwaysPlayed})</div>
                  <div className="text-sm">% Hitting Fairway</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-2xl font-bold">{girPercentage}%</div>
                  <div className="text-sm text-gray-500">({totalGIR}/{totalGIRPlayed})</div>
                  <div className="text-sm">% GIR</div>
                </div>
              </div>
            </TabsContent>
            
            {/* Scorecard Content */}
            <TabsContent value="scorecard" className="px-0 py-4">
              <div className="grid grid-cols-3 gap-4 text-center mb-6">
                <div className="flex flex-col items-center">
                  <div className="text-2xl font-bold">{puttingAvg}</div>
                  <div className="text-sm text-gray-500">({totalPutts})</div>
                  <div className="text-sm">Putting Avg</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-2xl font-bold">{fairwayPercentage}%</div>
                  <div className="text-sm text-gray-500">({totalFairwaysHit}/{totalFairwaysPlayed})</div>
                  <div className="text-sm">% Hitting Fairway</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="text-2xl font-bold">{girPercentage}%</div>
                  <div className="text-sm text-gray-500">({totalGIR}/{totalGIRPlayed})</div>
                  <div className="text-sm">% GIR</div>
                </div>
              </div>
              
              <div className="overflow-hidden rounded-lg">
                {/* Scorecard Header */}
                <div className="grid grid-cols-6 bg-gray-700 text-white py-2 px-4">
                  <div className="text-left font-semibold">HOLE</div>
                  <div className="text-center font-semibold">PAR</div>
                  <div className="text-center font-semibold">GROSS</div>
                  <div className="text-center font-semibold">PUTTS</div>
                  <div className="text-center font-semibold">FAIRWAY</div>
                  <div className="text-center font-semibold">GIR</div>
                </div>
                
                {/* Scorecard Rows */}
                <div className="divide-y divide-gray-200">
                  {sortedHoles.map((hole) => {
                    const scoreStyle = getScoreStyle(hole.score, hole.par);
                    
                    return (
                      <div key={hole.id} className="grid grid-cols-6 py-3 px-4 items-center">
                        <div className="text-left">{hole.holeNumber}</div>
                        <div className="text-center">{hole.par}</div>
                        <div className="text-center">
                          <span 
                            className="inline-flex items-center justify-center w-8 h-8 rounded-full" 
                            style={{ 
                              backgroundColor: scoreStyle.backgroundColor, 
                              color: scoreStyle.color 
                            }}
                          >
                            {hole.score || '-'}
                          </span>
                        </div>
                        <div className="text-center">{hole.numPutts || '-'}</div>
                        <div className="text-center">
                          {hole.fairwayHit === null ? '-' : 
                            hole.fairwayHit ? 
                              <CheckIcon className="inline-block w-5 h-5 text-green-600" /> : 
                              hole.par === 3 ? 
                                <ArrowRightIcon className="inline-block w-5 h-5 text-gray-400" /> :
                                <XIcon className="inline-block w-5 h-5 text-red-600" />
                          }
                        </div>
                        <div className="text-center">
                          {hole.greenInRegulation === null ? '-' : 
                            hole.greenInRegulation ? 
                              <CheckIcon className="inline-block w-5 h-5 text-green-600" /> : 
                              <XIcon className="inline-block w-5 h-5 text-red-600" />
                          }
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </CardHeader>
      </Card>
    </div>
  );
}