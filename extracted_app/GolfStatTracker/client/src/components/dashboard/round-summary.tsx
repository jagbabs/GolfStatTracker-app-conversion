import React from 'react';
import { useLocation } from 'wouter';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useQuery } from '@tanstack/react-query';
import { Round } from '@shared/schema';
import { formatDate, formatRelativeScore, calculateFairwayPercentage, calculateGIRPercentage } from '@/lib/utils';

const RoundSummary = () => {
  const [, navigate] = useLocation();
  const { data: rounds = [], isLoading } = useQuery<Round[]>({
    queryKey: ['/api/rounds'],
  });

  // Sort rounds by date (most recent first)
  const sortedRounds = [...rounds].sort((a, b) => 
    new Date(b.date).getTime() - new Date(a.date).getTime()
  );

  // Get only the 3 most recent rounds
  const recentRounds = sortedRounds.slice(0, 3);

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="font-display font-medium text-lg">Recent Rounds</CardTitle>
        <Button 
          onClick={() => navigate('/rounds')}
          variant="ghost" 
          className="text-[#2D582A] text-sm font-medium flex items-center h-8 px-2"
        >
          View All <span className="material-icons text-sm ml-1">arrow_forward</span>
        </Button>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="py-8 flex items-center justify-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
          </div>
        ) : recentRounds.length === 0 ? (
          <div className="text-center py-6 text-neutral-dark">
            <p>No rounds recorded yet.</p>
            <Button 
              onClick={() => navigate('/rounds')}
              variant="outline" 
              className="mt-2"
            >
              Start tracking your rounds
            </Button>
          </div>
        ) : (
          recentRounds.map((round) => (
            <div key={round.id} className="border-b border-neutral-light py-3 last:border-b-0">
              <div className="flex justify-between items-start">
                <div>
                  <h4 className="font-medium text-neutral-darkest">{round.courseName}</h4>
                  <p className="text-sm text-neutral-dark">{formatDate(round.date)}</p>
                </div>
                <div className="text-right">
                  <span className="text-lg font-medium text-[#2D582A]">{round.totalScore}</span>
                  <p className="text-sm text-neutral-medium">
                    {formatRelativeScore(round.relativeToPar || 0)}
                  </p>
                </div>
              </div>
              <div className="flex mt-2 text-sm">
                <div className="mr-4">
                  <span className="text-neutral-medium">FIR:</span>
                  <span className="font-medium">
                    {calculateFairwayPercentage(round.fairwaysHit || 0, round.fairwaysTotal || 0)}%
                  </span>
                </div>
                <div className="mr-4">
                  <span className="text-neutral-medium">GIR:</span>
                  <span className="font-medium">
                    {calculateGIRPercentage(round.greensInRegulation || 0, 18)}%
                  </span>
                </div>
                <div>
                  <span className="text-neutral-medium">Putts:</span>
                  <span className="font-medium">{round.totalPutts || 0}</span>
                </div>
              </div>
            </div>
          ))
        )}
      </CardContent>
    </Card>
  );
};

export default RoundSummary;
