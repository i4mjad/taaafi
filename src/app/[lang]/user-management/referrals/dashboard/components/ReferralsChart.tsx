'use client';

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useTranslation } from '@/contexts/TranslationContext';

interface ChartDataPoint {
  date: string;
  referrals: number;
  verified: number;
}

interface ReferralsChartProps {
  data: ChartDataPoint[];
}

export function ReferralsChart({ data }: ReferralsChartProps) {
  const { t } = useTranslation();

  // Format date for display
  const formattedData = data.map(item => ({
    ...item,
    displayDate: new Date(item.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t('modules.userManagement.referralDashboard.chart.title')}</CardTitle>
        <CardDescription>
          {t('modules.userManagement.referralDashboard.chart.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="px-2 sm:px-6">
        <ResponsiveContainer width="100%" height={300} className="sm:h-[350px]">
          <LineChart data={formattedData} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
            <XAxis 
              dataKey="displayDate" 
              fontSize={11}
              tickLine={false}
              axisLine={false}
              tick={{ fill: 'hsl(var(--muted-foreground))' }}
            />
            <YAxis 
              fontSize={11}
              tickLine={false}
              axisLine={false}
              tick={{ fill: 'hsl(var(--muted-foreground))' }}
            />
            <Tooltip 
              contentStyle={{ 
                backgroundColor: 'hsl(var(--card))',
                border: '1px solid hsl(var(--border))',
                borderRadius: '8px'
              }}
            />
            <Legend 
              wrapperStyle={{ paddingTop: '10px' }}
              iconType="line"
            />
            <Line 
              type="monotone" 
              dataKey="referrals" 
              stroke="hsl(217, 91%, 60%)" 
              strokeWidth={2}
              dot={false}
              name={t('modules.userManagement.referralDashboard.chart.totalReferrals')}
            />
            <Line 
              type="monotone" 
              dataKey="verified" 
              stroke="hsl(142, 71%, 45%)" 
              strokeWidth={2}
              dot={false}
              name={t('modules.userManagement.referralDashboard.chart.verified')}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

