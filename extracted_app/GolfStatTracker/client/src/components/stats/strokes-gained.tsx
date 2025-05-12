import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useStrokesGained } from '@/hooks/use-strokes-gained';
import StrokesGainedChart from './strokes-gained-chart';

const StrokesGainedAnalysis = () => {
  const { 
    strokesGained, 
    isLoading, 
    timePeriod, 
    setTimePeriod 
  } = useStrokesGained();

  const [selectedView, setSelectedView] = useState<string>('strokes-gained');

  // Handle time period change
  const handleTimePeriodChange = (value: string) => {
    switch (value) {
      case 'all':
        setTimePeriod(null);
        break;
      case '30':
        setTimePeriod(30);
        break;
      case '90':
        setTimePeriod(90);
        break;
      case '180':
        setTimePeriod(180);
        break;
      case '365':
        setTimePeriod(365);
        break;
      default:
        setTimePeriod(null);
    }
  };

  // Get appropriate period label based on selected time period
  const getPeriodLabel = () => {
    if (!timePeriod) return 'All Time';
    if (timePeriod === 30) return 'Last 30 Days';
    if (timePeriod === 90) return 'Last 3 Months';
    if (timePeriod === 180) return 'Last 6 Months';
    if (timePeriod === 365) return 'Last Year';
    return `Last ${timePeriod} Days`;
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="font-display font-medium text-lg">Strokes Gained Analysis</CardTitle>
        <Select 
          value={timePeriod ? timePeriod.toString() : 'all'} 
          onValueChange={handleTimePeriodChange}
        >
          <SelectTrigger className="w-[140px]">
            <SelectValue placeholder="Time Period" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Time</SelectItem>
            <SelectItem value="30">Last 30 Days</SelectItem>
            <SelectItem value="90">Last 90 Days</SelectItem>
            <SelectItem value="180">Last 6 Months</SelectItem>
            <SelectItem value="365">Last Year</SelectItem>
          </SelectContent>
        </Select>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="py-8 flex items-center justify-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
          </div>
        ) : (
          <StrokesGainedChart 
            strokesGained={strokesGained} 
            periodLabel={getPeriodLabel()} 
          />
        )}
      </CardContent>
    </Card>
  );
};

export default StrokesGainedAnalysis;
