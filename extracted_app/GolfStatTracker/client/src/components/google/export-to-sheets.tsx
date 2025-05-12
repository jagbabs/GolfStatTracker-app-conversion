import React, { useState, useEffect } from 'react';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { apiRequest } from '@/lib/queryClient';
import GoogleAuthSetup from './google-auth-setup';

interface ExportToSheetsProps {
  userId: number;
  onBack?: () => void;
}

export default function ExportToSheets({ userId, onBack }: ExportToSheetsProps) {
  const { toast } = useToast();
  const [isExporting, setIsExporting] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authUrl, setAuthUrl] = useState<string | null>(null);
  const [spreadsheetUrl, setSpreadsheetUrl] = useState<string | null>(null);
  const [showSetup, setShowSetup] = useState(false);
  
  // Check if the user is authenticated with Google
  const checkAuthStatus = async () => {
    try {
      const response = await apiRequest('GET', `/api/google/status/${userId}`);
      
      if (!response.ok) {
        throw new Error('Failed to check authentication status');
      }
      
      const data = await response.json();
      setIsAuthenticated(data.isAuthenticated);
      setAuthUrl(data.authUrl);
    } catch (error) {
      console.error('Error checking auth status:', error);
    }
  };
  
  // Handle export button click
  const handleExport = async () => {
    setIsExporting(true);
    setSpreadsheetUrl(null);
    
    try {
      const response = await apiRequest('POST', `/api/google/export/${userId}`);
      const data = await response.json();
      
      if (!response.ok) {
        if (data.needsAuth) {
          setIsAuthenticated(false);
          setAuthUrl(data.authUrl);
          throw new Error('Authentication required to export data');
        } else {
          throw new Error(data.message || 'Failed to export data');
        }
      }
      
      setSpreadsheetUrl(data.url);
      toast({
        title: "Export Successful",
        description: "Your golf data has been exported to Google Sheets.",
      });
    } catch (error: any) {
      toast({
        title: "Export Failed",
        description: error.message || "Failed to export data to Google Sheets",
        variant: "destructive"
      });
    } finally {
      setIsExporting(false);
    }
  };
  
  // Handle Google authorization
  const handleAuthorize = () => {
    if (authUrl) {
      window.location.href = authUrl;
    }
  };
  
  // Run on component mount
  useEffect(() => {
    checkAuthStatus();
  }, [userId]);
  
  if (showSetup) {
    return (
      <GoogleAuthSetup 
        onCredentialsSaved={() => {
          setShowSetup(false);
          checkAuthStatus();
        }}
        onBack={() => setShowSetup(false)}
      />
    );
  }
  
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <div>
          <CardTitle>Export to Google Sheets</CardTitle>
          <CardDescription>
            Export your golf data to Google Sheets for advanced analysis and backup.
          </CardDescription>
        </div>
        {onBack && (
          <Button 
            variant="ghost" 
            size="sm" 
            onClick={onBack}
            className="h-8 w-8 p-0"
          >
            <span className="material-icons">arrow_back</span>
          </Button>
        )}
      </CardHeader>
      <CardContent>
        {!isAuthenticated ? (
          <Alert className="mb-4 bg-amber-50 border-amber-200">
            <AlertTitle>Authentication Required</AlertTitle>
            <AlertDescription>
              You need to authorize the app to access your Google Sheets account before exporting data.
            </AlertDescription>
          </Alert>
        ) : (
          <Alert className="mb-4 bg-green-50 border-green-200">
            <AlertTitle>Ready to Export</AlertTitle>
            <AlertDescription>
              Your account is connected to Google Sheets. Click "Export Data" to create a new spreadsheet with your golf data.
            </AlertDescription>
          </Alert>
        )}
        
        {spreadsheetUrl && (
          <div className="mt-4">
            <Alert className="bg-green-50 border-green-200">
              <AlertTitle>Export Complete</AlertTitle>
              <AlertDescription>
                <p>Your data has been exported to Google Sheets.</p>
                <a 
                  href={spreadsheetUrl} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="text-green-600 hover:underline font-medium mt-2 inline-block"
                >
                  Open Spreadsheet →
                </a>
              </AlertDescription>
            </Alert>
          </div>
        )}
      </CardContent>
      <CardFooter className="flex flex-col sm:flex-row gap-2 items-stretch sm:items-center">
        {!isAuthenticated ? (
          <>
            <Button 
              onClick={handleAuthorize}
              className="bg-green-600 hover:bg-green-700 flex-1"
            >
              Authorize with Google
            </Button>
            <Button 
              onClick={() => setShowSetup(true)}
              variant="outline"
              className="flex-1"
            >
              Set Up Credentials
            </Button>
          </>
        ) : (
          <>
            <Button 
              onClick={handleExport}
              disabled={isExporting}
              className="bg-green-600 hover:bg-green-700 flex-1"
            >
              {isExporting ? "Exporting..." : "Export Data to Google Sheets"}
            </Button>
            <Button 
              onClick={() => setShowSetup(true)}
              variant="outline"
              className="flex-1 sm:flex-initial"
            >
              Update Credentials
            </Button>
          </>
        )}
      </CardFooter>
    </Card>
  );
}