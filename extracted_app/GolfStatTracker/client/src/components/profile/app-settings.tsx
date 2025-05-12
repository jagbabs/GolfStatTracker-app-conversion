import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Button } from '@/components/ui/button';
import { useTheme } from '@/components/ui/theme-provider';
import { useToast } from '@/hooks/use-toast';

const AppSettings = () => {
  const { theme, setTheme } = useTheme();
  const { toast } = useToast();
  const [distanceUnit, setDistanceUnit] = useState<'yards' | 'meters'>('yards');
  const [dataSync, setDataSync] = useState<boolean>(true);
  
  const handleToggleDarkMode = (checked: boolean) => {
    setTheme(checked ? 'dark' : 'light');
    toast({
      title: `${checked ? 'Dark' : 'Light'} mode enabled`,
      description: `The app theme has been updated.`,
    });
  };
  
  const handleToggleDataSync = (checked: boolean) => {
    setDataSync(checked);
    toast({
      title: `Data sync ${checked ? 'enabled' : 'disabled'}`,
      description: `Automatic data backup is now ${checked ? 'active' : 'inactive'}.`,
    });
  };
  
  const handleDistanceUnitChange = (unit: 'yards' | 'meters') => {
    setDistanceUnit(unit);
    toast({
      title: `Distance unit changed to ${unit}`,
      description: `All measurements will now be shown in ${unit}.`,
    });
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader>
        <CardTitle className="font-display font-medium text-lg">App Settings</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          <div className="flex justify-between items-center">
            <div>
              <label className="block font-medium text-neutral-darkest">Dark Mode</label>
              <p className="text-sm text-neutral-dark">Switch between light and dark theme</p>
            </div>
            <Switch 
              checked={theme === 'dark'} 
              onCheckedChange={handleToggleDarkMode} 
              className="data-[state=checked]:bg-[#2D582A]"
            />
          </div>
          
          <div className="flex justify-between items-center">
            <div>
              <label className="block font-medium text-neutral-darkest">Distance Unit</label>
              <p className="text-sm text-neutral-dark">Choose your preferred measurement unit</p>
            </div>
            <div className="flex">
              <Button 
                className={`px-3 py-1 rounded-l-lg ${distanceUnit === 'yards' ? 'bg-[#2D582A]' : 'bg-white text-black'}`} 
                onClick={() => handleDistanceUnitChange('yards')}
              >
                Yards
              </Button>
              <Button 
                variant={distanceUnit === 'meters' ? 'default' : 'outline'} 
                className={`px-3 py-1 rounded-r-lg border-l-0 ${distanceUnit === 'meters' ? 'bg-[#2D582A]' : ''}`} 
                onClick={() => handleDistanceUnitChange('meters')}
              >
                Meters
              </Button>
            </div>
          </div>
          
          <div className="flex justify-between items-center">
            <div>
              <label className="block font-medium text-neutral-darkest">Data Sync</label>
              <p className="text-sm text-neutral-dark">Automatically backup your data</p>
            </div>
            <Switch 
              checked={dataSync} 
              onCheckedChange={handleToggleDataSync} 
              className="data-[state=checked]:bg-[#2D582A]"
            />
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default AppSettings;
