import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { ThemeProvider } from "@/components/ui/theme-provider";

import AppShell from "@/components/layout/app-shell";
import Dashboard from "@/pages/dashboard";
import Rounds from "@/pages/rounds";
import Stats from "@/pages/stats";
import Profile from "@/pages/profile";
import HoleTracking from "@/pages/hole-tracking";
import EditRound from "@/pages/edit-round";
import RoundSummary from "@/pages/round-summary";
import StrokesGainedTest from "@/pages/strokes-gained-test";
import ExportSuccess from "@/pages/export-success";
import NotFound from "@/pages/not-found";

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider defaultTheme="light" storageKey="golf-tracker-theme">
        <TooltipProvider>
          <AppShell>
            <Switch>
              <Route path="/" component={Dashboard} />
              <Route path="/rounds" component={Rounds} />
              <Route path="/stats" component={Stats} />
              <Route path="/profile" component={Profile} />
              <Route path="/round/:roundId/hole/:holeNumber" component={HoleTracking} />
              <Route path="/round/:id/edit" component={EditRound} />
              <Route path="/round/:id/summary" component={RoundSummary} />
              <Route path="/strokes-gained-test" component={StrokesGainedTest} />
              <Route path="/export-success" component={ExportSuccess} />
              <Route component={NotFound} />
            </Switch>
          </AppShell>
          <Toaster />
        </TooltipProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
