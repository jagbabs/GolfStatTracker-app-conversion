import React, { useState } from 'react';
import { useLocation } from 'wouter';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import StatsOverview from '@/components/stats/stats-overview';
import StrokesGainedAnalysis from '@/components/stats/strokes-gained';
import ClubPerformance from '@/components/profile/club-performance';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';

const Stats = () => {
  const { toast } = useToast();
  const [, navigate] = useLocation();
  
  const handleExport = (format: string) => {
    toast({
      title: `Export to ${format}`,
      description: `Your data will be exported in ${format} format.`,
    });
  };

  return (
    <div className="p-4">
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-display font-semibold text-neutral-darkest mb-2">Your Statistics</h2>
          <p className="text-neutral-dark">Track your progress over time</p>
        </div>
        <Button 
          variant="outline" 
          onClick={() => navigate('/strokes-gained-test')}
          className="border border-[#2D582A] text-[#2D582A]"
        >
          Test Strokes Gained
        </Button>
      </div>
      
      <Tabs defaultValue="overview">
        <TabsList className="grid grid-cols-5 mb-6 border-b border-neutral-light rounded-none w-full bg-transparent">
          <TabsTrigger 
            value="overview" 
            className="py-3 rounded-none font-medium data-[state=active]:text-[#2D582A] data-[state=active]:border-b-2 data-[state=active]:border-[#2D582A] data-[state=inactive]:text-neutral-dark"
          >
            Overview
          </TabsTrigger>
          <TabsTrigger 
            value="tee-shots" 
            className="py-3 rounded-none font-medium data-[state=active]:text-[#2D582A] data-[state=active]:border-b-2 data-[state=active]:border-[#2D582A] data-[state=inactive]:text-neutral-dark"
          >
            Tee Shots
          </TabsTrigger>
          <TabsTrigger 
            value="approach" 
            className="py-3 rounded-none font-medium data-[state=active]:text-[#2D582A] data-[state=active]:border-b-2 data-[state=active]:border-[#2D582A] data-[state=inactive]:text-neutral-dark"
          >
            Approach
          </TabsTrigger>
          <TabsTrigger 
            value="short-game" 
            className="py-3 rounded-none font-medium data-[state=active]:text-[#2D582A] data-[state=active]:border-b-2 data-[state=active]:border-[#2D582A] data-[state=inactive]:text-neutral-dark"
          >
            Short Game
          </TabsTrigger>
          <TabsTrigger 
            value="clubs" 
            className="py-3 rounded-none font-medium data-[state=active]:text-[#2D582A] data-[state=active]:border-b-2 data-[state=active]:border-[#2D582A] data-[state=inactive]:text-neutral-dark"
          >
            Clubs
          </TabsTrigger>
        </TabsList>
        
        <TabsContent value="overview">
          <StatsOverview />
          <StrokesGainedAnalysis />
          
          {/* Export Options */}
          <Card className="bg-white rounded-xl shadow-md mb-6">
            <CardHeader>
              <CardTitle className="font-display font-medium text-lg">Export Data</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex gap-2">
                <Button 
                  variant="outline"
                  className="flex-1 flex items-center justify-center border border-[#2D582A] text-[#2D582A] font-medium py-3 rounded-lg hover:bg-[#2D582A] hover:bg-opacity-10"
                  onClick={() => handleExport('Google Sheets')}
                >
                  <span className="material-icons mr-2">cloud</span> Google Sheets
                </Button>
                <Button 
                  variant="outline"
                  className="flex-1 flex items-center justify-center border border-[#2D582A] text-[#2D582A] font-medium py-3 rounded-lg hover:bg-[#2D582A] hover:bg-opacity-10"
                  onClick={() => handleExport('CSV')}
                >
                  <span className="material-icons mr-2">download</span> CSV
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
        
        <TabsContent value="tee-shots">
          <Card className="bg-white rounded-xl shadow-md mb-6 p-6">
            <h3 className="font-medium text-lg mb-4">Tee Shot Stats</h3>
            <p className="text-neutral-dark">Coming soon! This section will show detailed analytics of your tee shots.</p>
          </Card>
        </TabsContent>
        
        <TabsContent value="approach">
          <Card className="bg-white rounded-xl shadow-md mb-6 p-6">
            <h3 className="font-medium text-lg mb-4">Approach Shot Stats</h3>
            <p className="text-neutral-dark">Coming soon! This section will show detailed analytics of your approach shots.</p>
          </Card>
        </TabsContent>
        
        <TabsContent value="short-game">
          <Card className="bg-white rounded-xl shadow-md mb-6 p-6">
            <h3 className="font-medium text-lg mb-4">Short Game Stats</h3>
            <p className="text-neutral-dark">Coming soon! This section will show detailed analytics of your short game including chipping and putting.</p>
          </Card>
        </TabsContent>
        
        <TabsContent value="clubs">
          <ClubPerformance />
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default Stats;
