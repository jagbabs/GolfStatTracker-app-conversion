import React, { useMemo } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine, Cell } from 'recharts';
import { useStrokesGained } from '@/hooks/use-strokes-gained';
import { useIsMobile } from '@/hooks/use-mobile';

interface StrokesGainedChartProps {
  userId?: number;
}

const StrokesGainedChart = ({ userId = 1 }: StrokesGainedChartProps) => {
  const { strokesGained, isLoading } = useStrokesGained(userId);
  const isMobile = useIsMobile();
  
  // Colors for different strokes gained values
  const getBarColor = (value: number) => {
    if (value >= 1) return '#2D582A'; // Excellent (dark green)
    if (value >= 0.5) return '#52A243'; // Good (green)
    if (value >= 0) return '#98D989'; // Average (light green)
    if (value >= -1) return '#F6C28B'; // Below Average (yellow/orange)
    return '#E4572E'; // Poor (red)
  };
  
  // Format the data for the chart
  const chartData = useMemo(() => {
    if (!strokesGained || !strokesGained.length) return [];
    
    // Get the most recent strokes gained data entry
    const latestSG = strokesGained[strokesGained.length - 1];
    
    return [
      { name: 'Off Tee', value: latestSG.offTee || 0 },
      { name: 'Approach', value: latestSG.approach || 0 },
      { name: 'Around Green', value: latestSG.aroundGreen || 0 },
      { name: 'Putting', value: latestSG.putting || 0 },
      { name: 'Total', value: latestSG.total || 0 },
    ];
  }, [strokesGained]);
  
  // Calculate min and max values for Y axis
  const yAxisDomain = useMemo(() => {
    if (!chartData.length) return [-4, 4];
    
    // Ensure we have number values for calculations
    const values = chartData.map(item => typeof item.value === 'number' ? item.value : 0);
    const minValue = Math.min(...values);
    const maxValue = Math.max(...values);
    
    // Set min and max values with padding
    const min = Math.floor(Math.min(minValue, -0.5) - 0.5);
    const max = Math.ceil(Math.max(maxValue, 0.5) + 0.5);
    
    return [min, max];
  }, [chartData]);
  
  // Custom tooltip to show the exact values
  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="bg-white p-2 shadow rounded border border-neutral-light">
          <p className="font-medium">{`${data.name}: ${data.value > 0 ? '+' : ''}${data.value.toFixed(1)}`}</p>
        </div>
      );
    }
    return null;
  };
  
  if (isLoading) {
    return (
      <Card className="bg-white rounded-xl shadow-md overflow-hidden">
        <CardHeader className="pb-2">
          <CardTitle className="font-display font-medium text-lg">Strokes Gained Analysis</CardTitle>
          <CardDescription>
            Visualizing your performance relative to scratch golfer
          </CardDescription>
        </CardHeader>
        <CardContent className="p-4">
          <div className="py-8 flex items-center justify-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
          </div>
        </CardContent>
      </Card>
    );
  }
  
  if (!strokesGained || strokesGained.length === 0) {
    return (
      <Card className="bg-white rounded-xl shadow-md overflow-hidden">
        <CardHeader className="pb-2">
          <CardTitle className="font-display font-medium text-lg">Strokes Gained Analysis</CardTitle>
          <CardDescription>
            Visualizing your performance relative to scratch golfer
          </CardDescription>
        </CardHeader>
        <CardContent className="p-4">
          <p className="text-center text-neutral-medium py-8">
            No strokes gained data available. Complete a round to see this analysis.
          </p>
        </CardContent>
      </Card>
    );
  }
  
  return (
    <Card className="bg-white rounded-xl shadow-md overflow-hidden">
      <CardHeader className="pb-2">
        <CardTitle className="font-display font-medium text-lg">Strokes Gained Analysis</CardTitle>
        <CardDescription>
          Visualizing your performance relative to scratch golfer
        </CardDescription>
      </CardHeader>
      <CardContent className="p-4">
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={chartData}
              margin={{ top: 20, right: 10, left: isMobile ? 0 : -20, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" vertical={false} />
              <XAxis 
                dataKey="name" 
                tick={{ fontSize: isMobile ? 10 : 12 }}
                tickMargin={5}
                axisLine={{ stroke: '#E5E5E5' }}
              />
              <YAxis 
                domain={yAxisDomain}
                tickFormatter={(value) => value > 0 ? `+${value}` : `${value}`}
                tick={{ fontSize: isMobile ? 10 : 12 }}
                axisLine={{ stroke: '#E5E5E5' }}
              />
              <Tooltip content={<CustomTooltip />} />
              <ReferenceLine y={0} stroke="#888888" />
              <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                {chartData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={getBarColor(typeof entry.value === 'number' ? entry.value : 0)} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
        
        <div className="mt-4 pt-4 border-t border-neutral-light">
          <h4 className="font-medium text-sm mb-2">Interpretation</h4>
          <div className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-[#2D582A] mr-2"></div>
              <span>+1.0 or more: Excellent</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-[#52A243] mr-2"></div>
              <span>+0.5 to +1.0: Good</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-[#98D989] mr-2"></div>
              <span>0 to +0.5: Average</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-[#F6C28B] mr-2"></div>
              <span>-1.0 to 0: Below Average</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-[#E4572E] mr-2"></div>
              <span>Below -1.0: Poor</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default StrokesGainedChart;