import React, { useState } from 'react';
import { useClubs } from '@/hooks/use-clubs';
import { useClubStats, ClubStats } from '@/hooks/use-club-stats';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { AlertCircle } from 'lucide-react';

const ClubPerformance: React.FC = () => {
  const { clubStats, isLoading } = useClubStats();
  const { clubs } = useClubs();
  const [selectedClubType, setSelectedClubType] = useState<string>('all');
  
  // Filter clubs based on selected type
  const filteredStats = selectedClubType === 'all' 
    ? clubStats 
    : clubStats.filter(stat => {
        const club = clubs.find(c => c.id === stat.clubId);
        return club && club.type === selectedClubType;
      });
  
  // Sort filtered stats by club name
  const sortedStats = [...filteredStats].sort((a, b) => a.clubName.localeCompare(b.clubName));
  
  const renderDistanceChart = (stat: ClubStats) => {
    // Don't show distance chart for putters
    if (stat.clubType.toLowerCase() === 'putter') {
      return (
        <div className="mb-6 p-4 flex items-center justify-center bg-neutral-50 rounded-lg">
          <AlertCircle className="text-neutral-400 mr-2" size={16} />
          <span className="text-sm text-neutral-500">Distance statistics not tracked for putters</span>
        </div>
      );
    }
    
    return (
      <div className="mb-6">
        <h4 className="text-sm font-medium text-neutral-dark mb-1">{stat.clubName}</h4>
        
        <div className="flex justify-between text-sm text-neutral-medium mb-1">
          <span>Min: {stat.minDistance} yds</span>
          <span>Avg: {stat.averageDistance.toFixed(1)} yds</span>
          <span>Max: {stat.maxDistance} yds</span>
        </div>
        
        <div className="relative pt-4 pb-6">
          {/* Min-Max range bar */}
          <div className="absolute h-2 bg-neutral-100 rounded-full w-full"></div>
          
          {/* Average position marker */}
          <div 
            className="absolute w-2 h-6 bg-[#2D582A] rounded-full" 
            style={{ 
              left: `${(stat.averageDistance - stat.minDistance) / (stat.maxDistance - stat.minDistance || 1) * 100}%`,
              top: '0px',
              transform: 'translateX(-50%)'
            }}
          />
          
          {/* Min marker */}
          <div className="absolute w-1 h-4 bg-neutral-400 rounded-full left-0 top-1"></div>
          
          {/* Max marker */}
          <div className="absolute w-1 h-4 bg-neutral-400 rounded-full right-0 top-1"></div>
        </div>
        
        <div className="mt-4">
          <span className="text-sm font-medium text-neutral-dark">Shot accuracy: </span>
          <span className="text-sm">{stat.accuracy.toFixed(1)}%</span>
          <Progress value={stat.accuracy} className="h-2 mt-1" />
        </div>
      </div>
    );
  };
  
  const renderDispersionChart = (stat: ClubStats) => {
    // Don't show dispersion chart for putters
    if (stat.clubType.toLowerCase() === 'putter') {
      return (
        <div className="mb-6 p-4 flex items-center justify-center bg-neutral-50 rounded-lg">
          <AlertCircle className="text-neutral-400 mr-2" size={16} />
          <span className="text-sm text-neutral-500">Dispersion not tracked for putters</span>
        </div>
      );
    }
    
    return (
      <div className="mb-6">
        <h4 className="text-sm font-medium text-neutral-dark mb-2">{stat.clubName} - Shot Dispersion</h4>
        
        <div className="mb-4">
          <h5 className="text-xs font-medium text-neutral-dark mb-2">Direction</h5>
          <div className="grid grid-cols-3 gap-2 mb-2">
            <div 
              className="bg-neutral-100 p-3 rounded-lg text-center relative overflow-hidden"
              style={{ height: '80px' }}
            >
              <div 
                className="absolute bottom-0 left-0 right-0 bg-red-100 transition-all duration-500"
                style={{ height: `${stat.dispersion.left}%` }}
              ></div>
              <span className="absolute inset-0 flex items-center justify-center text-neutral-dark font-medium">
                Left: {stat.dispersion.left.toFixed(1)}%
              </span>
            </div>
            
            <div 
              className="bg-neutral-100 p-3 rounded-lg text-center relative overflow-hidden"
              style={{ height: '80px' }}
            >
              <div 
                className="absolute bottom-0 left-0 right-0 bg-green-100 transition-all duration-500"
                style={{ height: `${stat.dispersion.center}%` }}
              ></div>
              <span className="absolute inset-0 flex items-center justify-center text-neutral-dark font-medium">
                Center: {stat.dispersion.center.toFixed(1)}%
              </span>
            </div>
            
            <div 
              className="bg-neutral-100 p-3 rounded-lg text-center relative overflow-hidden"
              style={{ height: '80px' }}
            >
              <div 
                className="absolute bottom-0 left-0 right-0 bg-red-100 transition-all duration-500"
                style={{ height: `${stat.dispersion.right}%` }}
              ></div>
              <span className="absolute inset-0 flex items-center justify-center text-neutral-dark font-medium">
                Right: {stat.dispersion.right.toFixed(1)}%
              </span>
            </div>
          </div>
        </div>
        
        <div>
          <h5 className="text-xs font-medium text-neutral-dark mb-2">Distance Control</h5>
          <div className="grid grid-cols-3 gap-2">
            <div 
              className="bg-neutral-100 p-3 rounded-lg text-center relative overflow-hidden"
              style={{ height: '80px' }}
            >
              <div 
                className="absolute bottom-0 left-0 right-0 bg-yellow-100 transition-all duration-500"
                style={{ height: `${stat.dispersion.short}%` }}
              ></div>
              <span className="absolute inset-0 flex items-center justify-center text-neutral-dark font-medium">
                Short: {stat.dispersion.short.toFixed(1)}%
              </span>
            </div>
            
            <div 
              className="bg-neutral-100 p-3 rounded-lg text-center relative overflow-hidden"
              style={{ height: '80px' }}
            >
              <div 
                className="absolute bottom-0 left-0 right-0 bg-green-100 transition-all duration-500"
                style={{ height: `${stat.dispersion.target}%` }}
              ></div>
              <span className="absolute inset-0 flex items-center justify-center text-neutral-dark font-medium">
                Target: {stat.dispersion.target.toFixed(1)}%
              </span>
            </div>
            
            <div 
              className="bg-neutral-100 p-3 rounded-lg text-center relative overflow-hidden"
              style={{ height: '80px' }}
            >
              <div 
                className="absolute bottom-0 left-0 right-0 bg-yellow-100 transition-all duration-500"
                style={{ height: `${stat.dispersion.long}%` }}
              ></div>
              <span className="absolute inset-0 flex items-center justify-center text-neutral-dark font-medium">
                Long: {stat.dispersion.long.toFixed(1)}%
              </span>
            </div>
          </div>
        </div>
      </div>
    );
  };
  
  const renderOutcomesChart = (stat: ClubStats) => {
    const outcomes = Object.entries(stat.outcomes);
    if (outcomes.length === 0) return null;
    
    // Define colors for different outcomes
    const outcomeColors: Record<string, string> = {
      // Regular shot outcomes
      'fairway': 'bg-green-100',
      'green': 'bg-green-100',
      'rough': 'bg-yellow-100',
      'bunker': 'bg-amber-100',
      'hazard': 'bg-red-100',
      'ob': 'bg-red-200',
      
      // Putting-specific outcomes
      'holed': 'bg-green-300',
      'acceptable': 'bg-green-100',
      'bad': 'bg-red-100'
    };
    
    return (
      <div className="mb-6">
        <h4 className="text-sm font-medium text-neutral-dark mb-2">{stat.clubName} - Outcomes</h4>
        
        <div className="space-y-2">
          {outcomes.map(([outcome, percentage]) => (
            <div key={outcome} className="flex items-center">
              <div className="w-24 text-sm">{outcome}:</div>
              <div className="flex-1 mx-2">
                <div className="h-4 bg-neutral-100 rounded-full overflow-hidden">
                  <div 
                    className={`h-full ${outcomeColors[outcome] || 'bg-blue-100'}`}
                    style={{ width: `${percentage}%` }}
                  ></div>
                </div>
              </div>
              <div className="w-16 text-sm text-right">{percentage.toFixed(1)}%</div>
            </div>
          ))}
        </div>
      </div>
    );
  };
  
  // Loading skeleton
  if (isLoading) {
    return (
      <Card className="bg-white rounded-xl shadow-md mb-6">
        <CardHeader>
          <CardTitle className="font-display font-medium text-lg">Club Performance</CardTitle>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-12 w-full mb-4" />
          <Skeleton className="h-40 w-full mb-4" />
          <Skeleton className="h-40 w-full" />
        </CardContent>
      </Card>
    );
  }
  
  // If no shots data available
  if (clubStats.length === 0 || clubStats.every(s => s.totalShots === 0)) {
    return (
      <Card className="bg-white rounded-xl shadow-md mb-6">
        <CardHeader>
          <CardTitle className="font-display font-medium text-lg">Club Performance</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-10 text-neutral-dark">
            <p>No shot data available yet.</p>
            <p className="text-sm mt-2">Start tracking your shots to see club performance analytics.</p>
          </div>
        </CardContent>
      </Card>
    );
  }
  
  // Filtered club types for the selector
  const uniqueClubTypes = Array.from(new Set(clubs.map(club => club.type)));
  const clubTypes = ['all', ...uniqueClubTypes];
  
  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="font-display font-medium text-lg">Club Performance</CardTitle>
        
        <div className="flex items-center space-x-2">
          <div className="text-sm text-neutral-medium">Filter by:</div>
          <Select 
            value={selectedClubType} 
            onValueChange={setSelectedClubType}
          >
            <SelectTrigger className="w-32">
              <SelectValue placeholder="Club Type" />
            </SelectTrigger>
            <SelectContent>
              {clubTypes.map(type => (
                <SelectItem key={type} value={type}>
                  {type.charAt(0).toUpperCase() + type.slice(1)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      
      <CardContent>
        <Tabs defaultValue="distance">
          <TabsList className="w-full mb-4">
            <TabsTrigger value="distance" className="flex-1">Distances</TabsTrigger>
            <TabsTrigger value="dispersion" className="flex-1">Dispersion</TabsTrigger>
            <TabsTrigger value="outcomes" className="flex-1">Outcomes</TabsTrigger>
          </TabsList>
          
          <TabsContent value="distance" className="space-y-4">
            {sortedStats.map(stat => (
              <div key={stat.clubId}>
                {stat.totalShots > 0 && renderDistanceChart(stat)}
              </div>
            ))}
            
            {sortedStats.length === 0 && (
              <div className="text-center py-8 text-neutral-dark">
                <p>No clubs match the selected filter.</p>
              </div>
            )}
          </TabsContent>
          
          <TabsContent value="dispersion" className="space-y-4">
            {sortedStats.map(stat => (
              <div key={stat.clubId}>
                {stat.totalShots > 0 && renderDispersionChart(stat)}
              </div>
            ))}
            
            {sortedStats.length === 0 && (
              <div className="text-center py-8 text-neutral-dark">
                <p>No clubs match the selected filter.</p>
              </div>
            )}
          </TabsContent>
          
          <TabsContent value="outcomes" className="space-y-4">
            {sortedStats.map(stat => (
              <div key={stat.clubId}>
                {stat.totalShots > 0 && renderOutcomesChart(stat)}
              </div>
            ))}
            
            {sortedStats.length === 0 && (
              <div className="text-center py-8 text-neutral-dark">
                <p>No clubs match the selected filter.</p>
              </div>
            )}
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
};

export default ClubPerformance;