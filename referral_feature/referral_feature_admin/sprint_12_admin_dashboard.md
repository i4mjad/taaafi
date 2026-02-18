# Sprint 12: Admin Dashboard Overview Page

**Status**: Not Started
**Previous Sprint**: `../sprint_11_revenuecat_rewards.md`
**Next Sprint**: `sprint_13_fraud_queue.md`
**Estimated Duration**: 8-10 hours

---

## Objectives
Create the main admin dashboard for the referral program with key metrics, charts, and real-time stats.

---

## Prerequisites

### Verify Sprint 11 Completion
- [ ] All mobile features complete
- [ ] Referral program fully functional

### Codebase Checks
1. Find Next.js admin app location
2. Check existing admin page structure
3. Verify Firebase Admin SDK setup
4. Check authentication middleware
5. Review existing dashboard patterns

---

## Tasks

### Task 1: Create Dashboard Page Route

**File**: `app/admin/referrals/dashboard/page.tsx`

Server Component for admin dashboard.

---

### Task 2: Create Admin API Routes

**File**: `app/api/admin/referrals/stats/route.ts`

```typescript
export async function GET(request: NextRequest) {
  // Verify admin authentication
  const token = request.headers.get('authorization')?.split('Bearer ')[1];
  if (!token || !(await verifyAdmin(token))) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // Fetch aggregate stats
  const stats = await getAggregateStats();

  return NextResponse.json(stats);
}

async function getAggregateStats() {
  const db = admin.firestore();

  // Query referralVerifications collection
  const allVerifications = await db.collection('referralVerifications').get();

  const stats = {
    totalReferrals: allVerifications.size,
    totalVerified: allVerifications.docs.filter(d => d.data().verificationStatus === 'verified').length,
    totalPending: allVerifications.docs.filter(d => d.data().verificationStatus === 'pending').length,
    totalBlocked: allVerifications.docs.filter(d => d.data().verificationStatus === 'blocked').length,

    // Fraud stats
    flaggedForReview: allVerifications.docs.filter(d =>
      d.data().fraudScore >= 40 && d.data().fraudScore < 71
    ).length,
    autoBlocked: allVerifications.docs.filter(d => d.data().fraudScore >= 71).length,

    // Reward stats
    totalRewardsDistributed: await getTotalRewardsDistributed(),

    // Conversion stats
    conversionRate: calculateConversionRate(allVerifications.docs)
  };

  return stats;
}
```

---

### Task 3: Create Stats Cards Component

**File**: `app/admin/referrals/dashboard/components/StatsCards.tsx`

```typescript
interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  trend?: { value: number; isPositive: boolean };
  icon?: React.ReactNode;
}

export function StatsCard({ title, value, subtitle, trend, icon }: StatsCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{value}</p>
          {subtitle && (
            <p className="text-sm text-gray-500 mt-1">{subtitle}</p>
          )}
        </div>
        {icon && (
          <div className="text-gray-400">{icon}</div>
        )}
      </div>
      {trend && (
        <div className={`mt-4 flex items-center text-sm ${trend.isPositive ? 'text-green-600' : 'text-red-600'}`}>
          {trend.isPositive ? '↑' : '↓'} {Math.abs(trend.value)}% from last month
        </div>
      )}
    </div>
  );
}

export function StatsCards({ stats }: { stats: AggregateStats }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <StatsCard
        title="Total Referrals"
        value={stats.totalReferrals}
        subtitle="All-time signups"
        icon={<Users size={24} />}
      />
      <StatsCard
        title="Verified Users"
        value={stats.totalVerified}
        subtitle={`${stats.conversionRate}% conversion`}
        icon={<CheckCircle size={24} />}
      />
      <StatsCard
        title="Pending Review"
        value={stats.flaggedForReview}
        subtitle="Needs admin action"
        icon={<AlertCircle size={24} />}
      />
      <StatsCard
        title="Blocked (Fraud)"
        value={stats.totalBlocked}
        subtitle="Auto + manual blocks"
        icon={<XCircle size={24} />}
      />
    </div>
  );
}
```

---

### Task 4: Create Referrals Over Time Chart

**File**: `app/admin/referrals/dashboard/components/ReferralsChart.tsx`

Using Recharts:

```typescript
'use client';

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

interface ReferralsChartProps {
  data: { date: string; referrals: number; verified: number }[];
}

export function ReferralsChart({ data }: ReferralsChartProps) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-semibold mb-4">Referrals Over Time</h3>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip />
          <Line type="monotone" dataKey="referrals" stroke="#8884d8" name="Total Referrals" />
          <Line type="monotone" dataKey="verified" stroke="#82ca9d" name="Verified" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
```

**API Route**: `app/api/admin/referrals/chart-data/route.ts`

Fetch daily referral counts for last 30 days.

---

### Task 5: Create Top Referrers Table

**File**: `app/admin/referrals/dashboard/components/TopReferrersTable.tsx`

```typescript
interface TopReferrer {
  userId: string;
  displayName: string;
  email: string;
  totalReferred: number;
  totalVerified: number;
  totalRewards: string;
}

export function TopReferrersTable({ referrers }: { referrers: TopReferrer[] }) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-semibold mb-4">Top Referrers (All Time)</h3>
      <table className="min-w-full divide-y divide-gray-200">
        <thead>
          <tr>
            <th className="px-4 py-2 text-left text-sm font-medium text-gray-500">User</th>
            <th className="px-4 py-2 text-left text-sm font-medium text-gray-500">Referred</th>
            <th className="px-4 py-2 text-left text-sm font-medium text-gray-500">Verified</th>
            <th className="px-4 py-2 text-left text-sm font-medium text-gray-500">Rewards</th>
            <th className="px-4 py-2 text-left text-sm font-medium text-gray-500">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {referrers.map((referrer) => (
            <tr key={referrer.userId}>
              <td className="px-4 py-3">
                <div>
                  <div className="font-medium">{referrer.displayName}</div>
                  <div className="text-sm text-gray-500">{referrer.email}</div>
                </div>
              </td>
              <td className="px-4 py-3">{referrer.totalReferred}</td>
              <td className="px-4 py-3">{referrer.totalVerified}</td>
              <td className="px-4 py-3">{referrer.totalRewards}</td>
              <td className="px-4 py-3">
                <Link href={`/admin/referrals/users/${referrer.userId}`} className="text-blue-600 hover:underline">
                  View Details
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

**API Route**: `app/api/admin/referrals/top-referrers/route.ts`

Query `referralStats`, order by `totalVerified`, limit 10.

---

### Task 6: Create Recent Activity Feed

**File**: `app/admin/referrals/dashboard/components/RecentActivity.tsx`

Show recent referral events:
- New signups
- Verifications completed
- Rewards redeemed
- Fraud blocks

```typescript
interface ActivityItem {
  id: string;
  type: 'signup' | 'verified' | 'reward' | 'blocked';
  message: string;
  timestamp: Date;
  userId?: string;
}

export function RecentActivity({ activities }: { activities: ActivityItem[] }) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-semibold mb-4">Recent Activity</h3>
      <div className="space-y-3">
        {activities.map((activity) => (
          <div key={activity.id} className="flex items-start space-x-3">
            <div className={`p-2 rounded ${getActivityColor(activity.type)}`}>
              {getActivityIcon(activity.type)}
            </div>
            <div className="flex-1">
              <p className="text-sm">{activity.message}</p>
              <p className="text-xs text-gray-500">{formatRelativeTime(activity.timestamp)}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

### Task 7: Create Revenue Impact Section

**File**: `app/admin/referrals/dashboard/components/RevenueImpact.tsx`

Show financial impact:
```
Revenue Impact
├── Promotional Days Given: 12,450
├── Cost Equivalent: $8,300 (at $20/month)
├── New Subscriptions: 245
├── Revenue Generated: $4,900 (first month)
└── ROI: 59%
```

Calculate based on rewards distributed vs. paid conversions.

---

### Task 8: Assemble Main Dashboard Page

**File**: `app/admin/referrals/dashboard/page.tsx`

```typescript
export default async function ReferralDashboardPage() {
  // Verify admin (server component)
  const isAdmin = await verifyAdminFromCookie();
  if (!isAdmin) {
    redirect('/admin/login');
  }

  // Fetch all data server-side
  const stats = await getAggregateStats();
  const chartData = await getChartData();
  const topReferrers = await getTopReferrers();
  const recentActivity = await getRecentActivity();

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Referral Program Dashboard</h1>
        <Link href="/admin/referrals/fraud-queue" className="btn-primary">
          Review Fraud Queue ({stats.flaggedForReview})
        </Link>
      </div>

      <StatsCards stats={stats} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ReferralsChart data={chartData} />
        <RevenueImpact stats={stats} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <TopReferrersTable referrers={topReferrers} />
        <RecentActivity activities={recentActivity} />
      </div>
    </div>
  );
}
```

---

## Testing Criteria

### Manual Testing
1. Navigate to `/admin/referrals/dashboard`
2. Verify admin auth works (non-admin redirected)
3. Check all stats display correctly
4. Verify chart loads with real data
5. Check top referrers table accuracy
6. Verify recent activity feed updates
7. Test responsive layout
8. Verify all links work

### Success Criteria
- [ ] Dashboard page loads quickly
- [ ] Stats cards show accurate data
- [ ] Charts render correctly
- [ ] Top referrers table functional
- [ ] Recent activity feed real-time
- [ ] Revenue impact calculated correctly
- [ ] Admin auth enforced
- [ ] Responsive design works
- [ ] No console errors
- [ ] All links navigate correctly

---

## Performance Optimization

- Cache stats for 5 minutes (use Next.js caching)
- Use React Server Components where possible
- Lazy load charts
- Paginate large tables
- Index Firestore queries

---

## Notes for Next Sprint

Sprint 13 will build the fraud detection review queue.

---

**Next Sprint**: `sprint_13_fraud_queue.md`
