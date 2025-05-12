import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useQuery } from '@tanstack/react-query';
import { Round } from '@shared/schema';
import { 
  calculateFairwayPercentage, 
  calculateGIRPercentage, 
  calculateAveragePutts, 
  filterByTimePeriod 
} from '@/lib/utils';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer
} from 'recharts';

const StatsOverview = () => {
  const [timePeriod, setTimePeriod] = useState<string>('180');
  
  const { data: rounds = [], isLoading } = useQuery<Round[]>({
    queryKey: ['/api/rounds'],
  });

  // Filter rounds by time period
  const filteredRounds = filterByTimePeriod(rounds, 'date', parseInt(timePeriod));
  
  // Group rounds by month for chart
  const roundsByMonth: Record<string, Round[]> = {};
  filteredRounds.forEach(round => {
    const date = new Date(round.date);
    const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
    if (!roundsByMonth[monthKey]) {
      roundsByMonth[monthKey] = [];
    }
    roundsByMonth[monthKey].push(round);
  });
  
  // Prepare chart data
  const chartData = Object.entries(roundsByMonth).map(([monthKey, monthRounds]) => {
    const [year, month] = monthKey.split('-').map(Number);
    const date = new Date(year, month - 1);
    const avgScore = monthRounds.reduce((sum, round) => sum + (round.totalScore || 0), 0) / monthRounds.length;
    
    return {
      month: date.toLocaleString('default', { month: 'short' }),
      avgScore: Math.round(avgScore * 10) / 10
    };
  });
  
  // Sort chart data chronologically
  chartData.sort((a, b) => {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months.indexOf(a.month) - months.indexOf(b.month);
  });
  
  // Calculate overall stats
  const avgScore = filteredRounds.length > 0
    ? Math.round((filteredRounds.reduce((sum, round) => sum + (round.totalScore || 0), 0) / filteredRounds.length) * 10) / 10
    : 0;
  
  // Calculate trend (compare current vs previous period)
  const calculateTrend = () => {
    if (filteredRounds.length === 0) return 0;
    
    const sortedRounds = [...filteredRounds].sort((a, b) => 
      new Date(b.date).getTime() - new Date(a.date).getTime()
    );
    
    const halfwayPoint = Math.floor(sortedRounds.length / 2);
    
    const recentRounds = sortedRounds.slice(0, halfwayPoint);
    const olderRounds = sortedRounds.slice(halfwayPoint);
    
    if (recentRounds.length === 0 || olderRounds.length === 0) return 0;
    
    const recentAvg = recentRounds.reduce((sum, round) => sum + (round.totalScore || 0), 0) / recentRounds.length;
    const olderAvg = olderRounds.reduce((sum, round) => sum + (round.totalScore || 0), 0) / olderRounds.length;
    
    return Math.round((olderAvg - recentAvg) * 10) / 10; // Positive means improvement
  };
  
  const scoreTrend = calculateTrend();

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="font-display font-medium text-lg">Scoring Trends</CardTitle>
        <Select value={timePeriod} onValueChange={setTimePeriod}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Select time period" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="30">Last 30 days</SelectItem>
            <SelectItem value="90">Last 90 days</SelectItem>
            <SelectItem value="180">Last 6 months</SelectItem>
            <SelectItem value="365">Last year</SelectItem>
            <SelectItem value="9999">All time</SelectItem>
          </SelectContent>
        </Select>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="py-8 flex items-center justify-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
          </div>
        ) : chartData.length === 0 ? (
          <div className="text-center py-6 text-neutral-dark">
            <p>No data available for the selected time period.</p>
          </div>
        ) : (
          <>
            <div className="h-60 bg-neutral-lightest rounded-lg border border-neutral-light p-3">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="month" />
                  <YAxis domain={['dataMin - 5', 'dataMax + 5']} />
                  <Tooltip 
                    formatter={(value) => [`${value}`, 'Avg Score']}
                    contentStyle={{ background: '#fff', border: '1px solid #e5e7eb', borderRadius: '0.5rem' }}
                  />
                  <Bar dataKey="avgScore" fill="#2D582A" barSize={24} radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            
            <div className="mt-4 flex justify-between items-center">
              <div>
                <span className="text-sm text-neutral-medium">Average Score:</span>
                <span className="font-medium ml-1">{avgScore}</span>
              </div>
              {scoreTrend !== 0 && (
                <div>
                  <span className="text-sm text-neutral-medium">Trend:</span>
                  <span className={`${scoreTrend > 0 ? 'text-success' : 'text-error'} font-medium ml-1 flex items-center`}>
                    <span className="material-icons text-xs mr-1">
                      {scoreTrend > 0 ? 'arrow_downward' : 'arrow_upward'}
                    </span>
                    {scoreTrend > 0 ? '-' : '+'}{Math.abs(scoreTrend)}
                  </span>
                </div>
              )}
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
};

export default StatsOverview;
