import React from 'react';
import { useLocation } from 'wouter';
import { Button } from '@/components/ui/button';
import RoundSummary from '@/components/dashboard/round-summary';
import StatsOverview from '@/components/dashboard/stats-overview';
import ClubDistances from '@/components/dashboard/club-distances';
import NewRoundForm from '@/components/rounds/new-round-form';

const Dashboard = () => {
  const [, navigate] = useLocation();
  const [showNewRoundForm, setShowNewRoundForm] = React.useState(false);

  const handleStartNewRound = () => {
    setShowNewRoundForm(true);
  };

  const handleCancelNewRound = () => {
    setShowNewRoundForm(false);
  };

  return (
    <div className="p-4">
      {!showNewRoundForm ? (
        <>
          <div className="mb-6">
            <h2 className="text-2xl font-display font-semibold text-neutral-darkest mb-2">Your Golf Stats</h2>
            <p className="text-neutral-dark">Track your progress and improve your game</p>
          </div>

          <RoundSummary />
          <StatsOverview />
          <ClubDistances />

          <div className="py-4">
            <Button 
              onClick={handleStartNewRound}
              className="fixed bottom-24 right-4 w-14 h-14 rounded-full bg-[#2D582A] text-white shadow-lg flex items-center justify-center md:relative md:bottom-auto md:right-auto md:w-full md:h-12 md:rounded-lg"
            >
              <span className="material-icons md:mr-2">add</span>
              <span className="hidden md:inline">Start New Round</span>
            </Button>
          </div>
        </>
      ) : (
        <NewRoundForm onCancel={handleCancelNewRound} />
      )}
    </div>
  );
};

export default Dashboard;
