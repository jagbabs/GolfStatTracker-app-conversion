import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import ExportToSheets from '@/components/google/export-to-sheets';

interface ConnectedAccount {
  id: string;
  service: string;
  icon: string;
  iconColor: string;
  connected: boolean;
}

const ConnectedAccounts = () => {
  const { toast } = useToast();
  const [showGoogleSheets, setShowGoogleSheets] = useState(false);
  
  const handleConnectNew = () => {
    setShowGoogleSheets(true);
  };

  return (
    <>
      {showGoogleSheets ? (
        <ExportToSheets 
          userId={1} 
          onBack={() => setShowGoogleSheets(false)} 
        />
      ) : (
        <Card className="bg-white rounded-xl shadow-md mb-6">
          <CardHeader>
            <CardTitle className="font-display font-medium text-lg">Connected Accounts</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex justify-between items-center py-2">
                <div className="flex items-center">
                  <span className="material-icons text-green-500 mr-3">insert_chart</span>
                  <div>
                    <p className="font-medium">Google Sheets</p>
                    <p className="text-sm text-neutral-dark">Export your golf data</p>
                  </div>
                </div>
                <Button 
                  variant="outline" 
                  className="text-[#2D582A] text-sm font-medium"
                  onClick={handleConnectNew}
                >
                  Connect
                </Button>
              </div>
              
              <div className="flex justify-between items-center py-2">
                <div className="flex items-center">
                  <span className="material-icons text-neutral-medium mr-3">add_circle</span>
                  <p className="font-medium text-[#2D582A]">Connect New Service</p>
                </div>
                <Button 
                  variant="ghost" 
                  className="text-[#2D582A]"
                  onClick={() => {
                    toast({
                      title: "Coming Soon",
                      description: "More integrations will be available soon!",
                    });
                  }}
                >
                  <span className="material-icons">arrow_forward</span>
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </>
  );
};

export default ConnectedAccounts;
