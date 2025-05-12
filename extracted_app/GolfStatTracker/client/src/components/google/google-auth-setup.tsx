import React, { useState } from 'react';
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useToast } from '@/hooks/use-toast';
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { apiRequest } from '@/lib/queryClient';

// Form schema for Google auth credentials
const googleCredentialsSchema = z.object({
  clientId: z.string().min(1, 'Client ID is required'),
  clientSecret: z.string().min(1, 'Client Secret is required'),
  redirectUri: z.string().min(1, 'Redirect URI is required')
});

type GoogleCredentialsFormValues = z.infer<typeof googleCredentialsSchema>;

interface GoogleAuthSetupProps {
  onCredentialsSaved?: () => void;
  onBack?: () => void;
}

export default function GoogleAuthSetup({ onCredentialsSaved, onBack }: GoogleAuthSetupProps) {
  const { toast } = useToast();
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // Default values for the form
  const defaultValues: Partial<GoogleCredentialsFormValues> = {
    redirectUri: window.location.origin + '/api/google/callback'
  };
  
  // Initialize the form
  const form = useForm<GoogleCredentialsFormValues>({
    resolver: zodResolver(googleCredentialsSchema),
    defaultValues,
  });
  
  // Handle form submission
  const onSubmit = async (data: GoogleCredentialsFormValues) => {
    setIsSubmitting(true);
    
    try {
      const response = await apiRequest('POST', '/api/google/credentials', data);
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to save credentials');
      }
      
      toast({
        title: "Credentials Saved",
        description: "Google credentials have been saved successfully."
      });
      
      if (onCredentialsSaved) {
        onCredentialsSaved();
      }
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to save credentials",
        variant: "destructive"
      });
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <div>
          <CardTitle>Google Sheets Integration</CardTitle>
          <CardDescription>
            Set up your Google OAuth credentials to enable exporting data to Google Sheets.
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
        <Form {...form}>
          <form id="google-credentials-form" onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="clientId"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Client ID</FormLabel>
                  <FormControl>
                    <Input placeholder="Your Google OAuth Client ID" {...field} />
                  </FormControl>
                  <FormDescription>
                    Obtain this from the Google Cloud Console.
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="clientSecret"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Client Secret</FormLabel>
                  <FormControl>
                    <Input 
                      type="password"
                      placeholder="Your Google OAuth Client Secret" 
                      {...field} 
                    />
                  </FormControl>
                  <FormDescription>
                    This is kept secure and never shared.
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="redirectUri"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Redirect URI</FormLabel>
                  <FormControl>
                    <Input 
                      placeholder="The callback URL for Google OAuth" 
                      {...field} 
                    />
                  </FormControl>
                  <FormDescription>
                    Add this to your authorized redirect URIs in Google Cloud Console.
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
          </form>
        </Form>
      </CardContent>
      <CardFooter className="flex justify-between">
        <Button
          type="button"
          variant="outline"
          onClick={() => form.reset()}
        >
          Reset
        </Button>
        <Button
          type="submit"
          form="google-credentials-form"
          disabled={isSubmitting}
          className="bg-green-600 hover:bg-green-700"
        >
          {isSubmitting ? "Saving..." : "Save Credentials"}
        </Button>
      </CardFooter>
      
      <div className="px-6 pb-6">
        <div className="bg-neutral-lightest p-4 rounded-lg mt-4">
          <h4 className="font-medium mb-2">How to Set Up Google Credentials</h4>
          <ol className="list-decimal list-inside space-y-2 text-sm text-neutral-dark">
            <li>Go to the <a href="https://console.cloud.google.com/" target="_blank" rel="noopener noreferrer" className="text-green-600 hover:underline">Google Cloud Console</a></li>
            <li>Create a new project or select an existing one</li>
            <li>Navigate to "APIs & Services" &gt; "Credentials"</li>
            <li>Click "Create Credentials" and select "OAuth client ID"</li>
            <li>Set the application type to "Web application"</li>
            <li>Add the redirect URI shown above to the authorized redirect URIs</li>
            <li>Copy the Client ID and Client Secret to the form above</li>
          </ol>
        </div>
      </div>
    </Card>
  );
}