import React, { useState } from 'react';
import { useLocation } from 'wouter';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useRounds } from '@/hooks/use-round';
import RoundCard from './round-card';

const RoundList = () => {
  const [, navigate] = useLocation();
  const { rounds, isLoading, deleteRound } = useRounds();
  const [searchTerm, setSearchTerm] = useState('');
  const [courseFilter, setCourseFilter] = useState('all');
  const [sortOrder, setSortOrder] = useState('recent');

  // Get unique courses for filter
  const uniqueCourses = Array.from(new Set(rounds.map(round => round.courseName)));

  // Filter rounds based on search and course filter
  const filteredRounds = rounds.filter(round => {
    // Apply search filter
    const matchesSearch = round.courseName.toLowerCase().includes(searchTerm.toLowerCase());
    
    // Apply course filter
    const matchesCourse = courseFilter === 'all' || round.courseName === courseFilter;
    
    return matchesSearch && matchesCourse;
  });

  // Sort rounds based on selection
  const sortedRounds = [...filteredRounds].sort((a, b) => {
    switch (sortOrder) {
      case 'recent':
        return new Date(b.date).getTime() - new Date(a.date).getTime();
      case 'oldest':
        return new Date(a.date).getTime() - new Date(b.date).getTime();
      case 'best':
        return (a.relativeToPar || 0) - (b.relativeToPar || 0);
      default:
        return 0;
    }
  });

  const handleDeleteRound = (roundId: number) => {
    if (window.confirm('Are you sure you want to delete this round?')) {
      deleteRound.mutate(roundId);
    }
  };

  if (isLoading) {
    return (
      <div className="py-8 flex items-center justify-center">
        <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
      </div>
    );
  }

  return (
    <>
      <Card className="bg-white rounded-xl shadow-md mb-6">
        <CardContent className="p-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <div className="relative flex-grow">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3">
                <span className="material-icons text-neutral-medium">search</span>
              </span>
              <Input
                type="text"
                placeholder="Search courses..."
                className="pl-10 pr-4 py-2 w-full border border-neutral-light rounded-lg"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <div className="flex gap-2">
              <Select value={courseFilter} onValueChange={setCourseFilter}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="All Courses" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Courses</SelectItem>
                  {uniqueCourses.map(course => (
                    <SelectItem key={course} value={course}>{course}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={sortOrder} onValueChange={setSortOrder}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Most Recent" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="recent">Most Recent</SelectItem>
                  <SelectItem value="oldest">Oldest First</SelectItem>
                  <SelectItem value="best">Best Score</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {sortedRounds.length === 0 ? (
        <div className="text-center py-6 bg-white rounded-xl shadow-md">
          <p className="text-neutral-dark mb-2">No rounds match your filters.</p>
          {searchTerm || courseFilter !== 'all' ? (
            <Button 
              variant="outline" 
              onClick={() => {
                setSearchTerm('');
                setCourseFilter('all');
              }}
            >
              Clear filters
            </Button>
          ) : (
            <p className="text-neutral-dark">Start tracking your first round!</p>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          {sortedRounds.map(round => (
            <RoundCard
              key={round.id}
              round={round}
              onView={() => navigate(`/round/${round.id}/hole/1`)}
              onEdit={() => navigate(`/round/${round.id}/edit`)}
              onDelete={() => handleDeleteRound(round.id)}
              onViewScorecard={() => navigate(`/round/${round.id}/summary`)}
            />
          ))}
        </div>
      )}
    </>
  );
};

export default RoundList;
