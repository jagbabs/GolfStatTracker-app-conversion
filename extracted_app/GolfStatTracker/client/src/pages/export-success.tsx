import React from 'react';
import { useLocation } from 'wouter';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { CheckCircle } from 'lucide-react';

export default function ExportSuccess() {
  const [, navigate] = useLocation();
  
  return (
    <div className="p-4 flex flex-col items-center justify-center min-h-[80vh]">
      <Card className="w-full max-w-md bg-white shadow-lg rounded-xl overflow-hidden">
        <CardHeader className="pb-2 text-center bg-green-50">
          <div className="mx-auto w-16 h-16 mb-2 flex items-center justify-center">
            <CheckCircle size={48} className="text-green-600" />
          </div>
          <CardTitle className="text-2xl text-neutral-darkest">Authentication Successful</CardTitle>
        </CardHeader>
        <CardContent className="pt-6">
          <p className="text-center text-neutral-dark mb-4">
            Your Google account has been successfully connected to the Golf Tracker app.
          </p>
          <p className="text-center text-neutral-dark">
            You can now export your golf data to Google Sheets for backup and further analysis.
          </p>
        </CardContent>
        <CardFooter className="flex justify-center pb-6">
          <Button 
            onClick={() => navigate('/profile')}
            className="bg-green-600 hover:bg-green-700"
          >
            Return to Profile
          </Button>
        </CardFooter>
      </Card>
    </div>
  );
}