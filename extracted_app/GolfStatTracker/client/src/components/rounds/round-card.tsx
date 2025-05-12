import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Round } from '@shared/schema';
import { formatDate, formatRelativeScore, calculateFairwayPercentage, calculateGIRPercentage } from '@/lib/utils';

interface RoundCardProps {
  round: Round;
  onView: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onViewScorecard?: () => void;
}

const RoundCard: React.FC<RoundCardProps> = ({ 
  round, 
  onView,
  onEdit,
  onDelete,
  onViewScorecard
}) => {
  return (
    <Card className="bg-white rounded-xl shadow-md overflow-hidden">
      <CardContent className="p-4">
        <div className="flex justify-between items-start">
          <div>
            <h3 className="font-medium text-lg text-neutral-darkest">{round.courseName}</h3>
            <p className="text-sm text-neutral-dark">{formatDate(round.date)}</p>
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
          <div className="text-right">
            <span className="text-xl font-medium text-[#2D582A]">{round.totalScore || 'N/A'}</span>
            <p className="text-sm text-neutral-medium">
              {round.relativeToPar !== undefined && round.relativeToPar !== null ? formatRelativeScore(round.relativeToPar) : 'N/A'}
            </p>
          </div>
        </div>
      </CardContent>
      <div className="bg-neutral-lightest p-2 flex justify-between items-center">
        <div className="flex space-x-2">
          <Button 
            variant="ghost" 
            className="text-[#2D582A] text-sm font-medium flex items-center"
            onClick={onView}
          >
            <span className="material-icons text-sm mr-1">play_arrow</span> Play
          </Button>
          
          {onViewScorecard && (
            <Button 
              variant="ghost" 
              className="text-[#2D582A] text-sm font-medium flex items-center"
              onClick={onViewScorecard}
            >
              <span className="material-icons text-sm mr-1">view_list</span> Scorecard
            </Button>
          )}
        </div>
        
        <div className="flex">
          <Button 
            variant="ghost" 
            size="icon" 
            className="p-2 text-neutral-dark hover:text-[#2D582A]"
            onClick={onEdit}
          >
            <span className="material-icons">edit</span>
          </Button>
          <Button 
            variant="ghost" 
            size="icon" 
            className="p-2 text-neutral-dark hover:text-error"
            onClick={onDelete}
          >
            <span className="material-icons">delete</span>
          </Button>
        </div>
      </div>
    </Card>
  );
};

export default RoundCard;
