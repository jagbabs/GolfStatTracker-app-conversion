import React from 'react';
import { useLocation } from 'wouter';
import { useRound } from '@/hooks/use-round';
import { useRoundStrokesGained } from '@/hooks/use-strokes-gained';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { HorizontalScorecard } from '@/components/rounds/horizontal-scorecard';
import { formatDate, formatRelativeScore, getStrokesGainedColor } from '@/lib/utils';

interface RoundStrokesGainedCardProps {
  roundId: number;
}

// Create the StrokesGained component
const RoundStrokesGainedCard = ({ roundId }: RoundStrokesGainedCardProps) => {
  const { strokesGained, isLoading } = useRoundStrokesGained(roundId);
  
  // Default values if no strokes gained data is available
  const sgData = strokesGained || {
    offTee: 0,
    approach: 0,
    aroundGreen: 0,
    putting: 0,
    total: 0
  };
  
  const formatStrokesGained = (value: number | null): string => {
    if (value === null) return '0.0';
    return value > 0 ? `+${value.toFixed(1)}` : value.toFixed(1);
  };
  
  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardContent className="p-4">
        <h3 className="text-xl font-semibold mb-4">Strokes Gained</h3>
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
      </CardContent>
    </Card>
  );
};

const RoundSummary = ({ params }: { params: { id: string } }) => {
  const roundId = parseInt(params.id, 10);
  const [, navigate] = useLocation();
  const { round, holes, isLoading } = useRound(roundId);
  
  if (isLoading) {
    return (
      <div className="p-4">
        <Card className="bg-white rounded-xl shadow-md p-4">
          <CardContent className="p-0">
            <h2 className="text-xl font-medium mb-4">Loading round data...</h2>
          </CardContent>
        </Card>
      </div>
    );
  }
  
  if (!round) {
    return (
      <div className="p-4">
        <Card className="bg-white rounded-xl shadow-md p-4">
          <CardContent className="p-0">
            <h2 className="text-xl font-medium mb-4">Round not found</h2>
            <Button onClick={() => navigate('/rounds')}>Back to Rounds</Button>
          </CardContent>
        </Card>
      </div>
    );
  }
  
  return (
    <div className="p-4">
      <div className="mb-4 flex justify-between items-center">
        <h2 className="text-2xl font-display font-semibold text-neutral-darkest">Round Summary</h2>
        <Button
          variant="outline"
          onClick={() => navigate('/rounds')}
          className="flex items-center"
        >
          <span className="material-icons mr-1 text-sm">arrow_back</span>
          Back to Rounds
        </Button>
      </div>
      
      {/* Round Header */}
      <Card className="bg-white rounded-xl shadow-md mb-6">
        <CardContent className="p-4">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <h3 className="text-sm text-neutral-500">Course</h3>
              <p className="text-lg font-medium">{round.courseName}</p>
            </div>
            
            <div>
              <h3 className="text-sm text-neutral-500">Date</h3>
              <p className="text-lg font-medium">{formatDate(round.date)}</p>
            </div>
            
            <div>
              <h3 className="text-sm text-neutral-500">Tees</h3>
              <p className="text-lg font-medium capitalize">{round.teeBox}</p>
            </div>
            
            <div>
              <h3 className="text-sm text-neutral-500">Score</h3>
              <p className="text-lg font-medium">
                {round.totalScore || '-'} 
                {round.relativeToPar !== undefined && round.relativeToPar !== null && (
                  <span className="ml-2">{formatRelativeScore(round.relativeToPar)}</span>
                )}
              </p>
            </div>
            
            <div>
              <h3 className="text-sm text-neutral-500">Weather</h3>
              <p className="text-lg font-medium capitalize">{round.weather || '-'}</p>
            </div>
            
            <div>
              <h3 className="text-sm text-neutral-500">Fairways Hit</h3>
              <p className="text-lg font-medium">{round.fairwaysHit || 0} / {round.fairwaysTotal || 0}</p>
            </div>
            
            <div>
              <h3 className="text-sm text-neutral-500">GIR</h3>
              <p className="text-lg font-medium">{round.greensInRegulation || 0} / 18</p>
            </div>
          </div>
          
          {round.notes && (
            <div className="mt-4 pt-4 border-t">
              <h3 className="text-sm text-neutral-500">Notes</h3>
              <p className="text-base">{round.notes}</p>
            </div>
          )}
          
          <div className="mt-4 flex space-x-3">
            <Button 
              onClick={() => navigate(`/round/${roundId}/hole/1`)}
              className="bg-[#2D582A]"
            >
              <span className="material-icons mr-1 text-sm">play_arrow</span>
              Continue Round
            </Button>
            
            <Button 
              variant="outline"
              onClick={() => navigate(`/round/${roundId}/edit`)}
            >
              <span className="material-icons mr-1 text-sm">edit</span>
              Edit Details
            </Button>
          </div>
        </CardContent>
      </Card>
      
      {/* Scorecard */}
      <HorizontalScorecard round={round} holes={holes} />
      
      {/* Strokes Gained Analysis */}
      {holes.length > 0 && (
        <RoundStrokesGainedCard roundId={round.id} />
      )}
      
      {/* Shot Distribution and Analysis */}
      {holes.length > 0 && (
        <Card className="bg-white rounded-xl shadow-md mb-6">
          <CardContent className="p-4">
            <h3 className="text-xl font-semibold mb-4">Shot Distribution</h3>
            <p className="text-neutral-dark italic">Detailed shot distribution charts will appear here once you've logged more shots.</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default RoundSummary;