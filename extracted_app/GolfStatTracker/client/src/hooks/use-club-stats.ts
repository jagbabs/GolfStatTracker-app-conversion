import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Shot, Club } from '@shared/schema';
import { apiRequest } from '@/lib/queryClient';

export interface ClubStats {
  clubId: number;
  clubName: string;
  clubType: string;
  totalShots: number;
  averageDistance: number;
  minDistance: number;
  maxDistance: number;
  accuracy: number; // percentage of shots that were "successful"
  dispersion: { 
    left: number;
    center: number;
    right: number;
    long: number;
    short: number;
    target: number;
  };
  outcomes: {
    [key: string]: number; // fairway, rough, green, bunker, hazard, OB percentages or putting-specific outcomes
  };
}

export function useClubStats(userId: number = 1) {
  const [clubStats, setClubStats] = useState<ClubStats[]>([]);
  
  // Get all shots from the API
  const { 
    data: shots = [],
    isLoading: isShotsLoading,
    isError: isShotsError,
    error: shotsError
  } = useQuery<Shot[]>({
    queryKey: ['/api/shots'],
  });
  
  // Get clubs data
  const {
    data: clubs = [],
    isLoading: isClubsLoading,
    isError: isClubsError,
    error: clubsError
  } = useQuery<Club[]>({
    queryKey: ['/api/clubs'],
  });
  
  // Calculate club statistics when shots data changes
  useEffect(() => {
    if (shots.length === 0 || clubs.length === 0) {
      return;
    }
    
    // Initialize stats for each club
    const clubStatsMap = new Map<number, ClubStats>();
    
    clubs.forEach(club => {
      clubStatsMap.set(club.id, {
        clubId: club.id,
        clubName: club.name,
        clubType: club.type,
        totalShots: 0,
        averageDistance: 0,
        minDistance: Number.MAX_SAFE_INTEGER,
        maxDistance: 0,
        accuracy: 0,
        dispersion: {
          left: 0,
          center: 0,
          right: 0,
          long: 0,
          short: 0,
          target: 0
        },
        outcomes: {}
      });
    });
    
    // Process each shot to collect statistics
    shots.forEach(shot => {
      if (!shot.clubId) return;
      
      const clubStat = clubStatsMap.get(shot.clubId);
      if (!clubStat) return;
      
      // Update total shots count
      clubStat.totalShots++;
      
      // Update distance stats if available
      if (shot.shotDistance) {
        const totalDistance = clubStat.averageDistance * (clubStat.totalShots - 1);
        clubStat.averageDistance = (totalDistance + shot.shotDistance) / clubStat.totalShots;
        clubStat.minDistance = Math.min(clubStat.minDistance, shot.shotDistance);
        clubStat.maxDistance = Math.max(clubStat.maxDistance, shot.shotDistance);
      }
      
      // Update accuracy
      if (shot.successfulStrike) {
        const successfulShots = Math.round(clubStat.accuracy * (clubStat.totalShots - 1) / 100);
        clubStat.accuracy = ((successfulShots + 1) / clubStat.totalShots) * 100;
      }
      
      // Update directional dispersion
      if (shot.direction) {
        clubStat.dispersion[shot.direction as keyof typeof clubStat.dispersion]++;
      }
      
      // Update shot outcome distribution
      if (shot.outcome) {
        clubStat.outcomes[shot.outcome] = (clubStat.outcomes[shot.outcome] || 0) + 1;
      }
    });
    
    // Convert dispersion counts to percentages
    clubStatsMap.forEach((stat) => {
      if (stat.totalShots > 0) {
        stat.dispersion.left = (stat.dispersion.left / stat.totalShots) * 100;
        stat.dispersion.center = (stat.dispersion.center / stat.totalShots) * 100;
        stat.dispersion.right = (stat.dispersion.right / stat.totalShots) * 100;
        stat.dispersion.long = (stat.dispersion.long / stat.totalShots) * 100;
        stat.dispersion.short = (stat.dispersion.short / stat.totalShots) * 100;
        stat.dispersion.target = (stat.dispersion.target / stat.totalShots) * 100;
        
        // For putter clubs, customize the outcomes
        if (stat.clubType.toLowerCase() === 'putter') {
          // Map original outcomes to putting-specific outcomes if needed
          const puttOutcomes: Record<string, number> = {
            'holed': 0,
            'acceptable': 0, 
            'bad': 0
          };
          
          // Convert existing outcomes to putting-specific terminology
          Object.entries(stat.outcomes).forEach(([outcome, percentage]) => {
            if (outcome === 'hole') {
              puttOutcomes['holed'] += percentage;
            } else if (outcome === 'green' || outcome === 'fairway') {
              puttOutcomes['acceptable'] += percentage;
            } else {
              puttOutcomes['bad'] += percentage;
            }
          });
          
          stat.outcomes = puttOutcomes;
        }
        
        // Convert outcome counts to percentages for all clubs
        Object.keys(stat.outcomes).forEach(outcome => {
          stat.outcomes[outcome] = (stat.outcomes[outcome] / stat.totalShots) * 100;
        });
      }
      
      // Fix edge cases
      if (stat.minDistance === Number.MAX_SAFE_INTEGER) {
        stat.minDistance = 0;
      }
    });
    
    // Convert map to array and sort by club type and name
    const statsArray = Array.from(clubStatsMap.values());
    setClubStats(statsArray);
    
  }, [shots, clubs]);
  
  return {
    clubStats,
    isLoading: isShotsLoading || isClubsLoading,
    isError: isShotsError || isClubsError,
    error: shotsError || clubsError
  };
}