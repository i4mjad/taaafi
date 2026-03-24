'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import {
  Smartphone,
  AlertTriangle,
  Shield,
  Users,
  RefreshCw,
  Loader2,
  ExternalLink,
} from 'lucide-react';
import { collection, query, where, getDocs, doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import Link from 'next/link';

interface DeviceInfo {
  deviceId: string;
  isBanned: boolean;
  banReason?: string;
  banId?: string;
  bannedUserId?: string;
  otherUsers: Array<{
    uid: string;
    displayName?: string;
    email?: string;
  }>;
}

interface DeviceHistoryCardProps {
  userId: string;
  userDevices: string[];
  lang: string;
}

export default function DeviceHistoryCard({ userId, userDevices, lang }: DeviceHistoryCardProps) {
  const [devices, setDevices] = useState<DeviceInfo[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasEvasionRisk, setHasEvasionRisk] = useState(false);

  const analyzeDevices = async () => {
    if (!userDevices || userDevices.length === 0) return;

    setLoading(true);
    try {
      const deviceInfos: DeviceInfo[] = [];

      for (const deviceId of userDevices) {
        const info: DeviceInfo = {
          deviceId,
          isBanned: false,
          otherUsers: [],
        };

        // Check if device is in bannedDevices collection
        const bannedDeviceDoc = await getDoc(doc(db, 'bannedDevices', deviceId));
        if (bannedDeviceDoc.exists()) {
          const data = bannedDeviceDoc.data();
          if (data?.isActive) {
            info.isBanned = true;
            info.banReason = data.reason;
            info.banId = data.banId;
            info.bannedUserId = data.userId;
          }
        }

        // Find other users who share this device
        const usersQuery = query(
          collection(db, 'users'),
          where('devicesIds', 'array-contains', deviceId)
        );
        const usersSnapshot = await getDocs(usersQuery);

        for (const userDoc of usersSnapshot.docs) {
          if (userDoc.id !== userId) {
            const userData = userDoc.data();
            info.otherUsers.push({
              uid: userDoc.id,
              displayName: userData.displayName || userData.username,
              email: userData.email,
            });
          }
        }

        deviceInfos.push(info);
      }

      setDevices(deviceInfos);

      // Determine evasion risk:
      // 1. Any device banned by a DIFFERENT user
      const hasBannedSharedDevice = deviceInfos.some(
        d => d.isBanned && d.bannedUserId && d.bannedUserId !== userId
      );
      // 2. Shares device with another user AND any device is banned
      const sharesDeviceWithOther = deviceInfos.some(d => d.otherUsers.length > 0);
      const hasAnyBannedDevice = deviceInfos.some(d => d.isBanned);

      setHasEvasionRisk(hasBannedSharedDevice || (sharesDeviceWithOther && hasAnyBannedDevice));
    } catch (error) {
      console.error('Error analyzing devices:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (userDevices && userDevices.length > 0) {
      analyzeDevices();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId, userDevices]);

  if (!userDevices || userDevices.length === 0) {
    return null;
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Smartphone className="h-5 w-5 text-blue-600" />
            <CardTitle className="text-lg">Device History</CardTitle>
            {hasEvasionRisk && (
              <Badge variant="destructive" className="flex items-center gap-1">
                <AlertTriangle className="h-3 w-3" />
                Ban Evasion Risk
              </Badge>
            )}
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={analyzeDevices}
            disabled={loading}
          >
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {hasEvasionRisk && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4">
            <div className="flex items-center gap-2 text-red-700 font-medium text-sm mb-1">
              <AlertTriangle className="h-4 w-4" />
              Ban Evasion Detected
            </div>
            <p className="text-xs text-red-600">
              This user shares a device with a banned account. Consider issuing a device ban to prevent further evasion.
            </p>
          </div>
        )}

        {loading ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-gray-400" />
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs">Device ID</TableHead>
                <TableHead className="text-xs">Status</TableHead>
                <TableHead className="text-xs">Shared With</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {devices.map((device) => (
                <TableRow key={device.deviceId}>
                  <TableCell className="font-mono text-xs max-w-[200px] truncate">
                    {device.deviceId}
                  </TableCell>
                  <TableCell>
                    {device.isBanned ? (
                      <Badge variant="destructive" className="text-xs">
                        <Shield className="h-3 w-3 mr-1" />
                        Banned
                      </Badge>
                    ) : (
                      <Badge variant="secondary" className="text-xs">Clean</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    {device.otherUsers.length > 0 ? (
                      <div className="space-y-1">
                        {device.otherUsers.map((user) => (
                          <Link
                            key={user.uid}
                            href={`/${lang}/user-management/users/${user.uid}`}
                            className="flex items-center gap-1 text-xs text-blue-600 hover:underline"
                          >
                            <Users className="h-3 w-3" />
                            {user.displayName || user.email || user.uid.substring(0, 8)}
                            <ExternalLink className="h-2.5 w-2.5" />
                          </Link>
                        ))}
                      </div>
                    ) : (
                      <span className="text-xs text-gray-400">No other users</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
