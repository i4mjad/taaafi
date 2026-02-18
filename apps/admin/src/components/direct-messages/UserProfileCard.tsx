'use client';

import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { CommunityProfile } from '@/types/directMessages';
import { ExternalLink } from 'lucide-react';

interface UserProfileCardProps {
  profile: CommunityProfile;
  onViewProfile?: (cpId: string) => void;
  showActions?: boolean;
}

export function UserProfileCard({ profile, onViewProfile, showActions = true }: UserProfileCardProps) {
  return (
    <Card className="p-4">
      <div className="flex items-center gap-3">
        <Avatar className="h-12 w-12">
          <AvatarImage src={profile.photoURL} />
          <AvatarFallback>{profile.displayName[0]}</AvatarFallback>
        </Avatar>
        <div className="flex-1 min-w-0">
          <p className="font-medium truncate">{profile.displayName}</p>
          <p className="text-xs text-muted-foreground truncate">ID: {profile.id}</p>
          <p className="text-xs text-muted-foreground truncate">UID: {profile.userUID}</p>
        </div>
        {showActions && onViewProfile && (
          <Button 
            size="sm" 
            variant="outline"
            onClick={() => onViewProfile(profile.id)}
          >
            <ExternalLink className="h-4 w-4" />
          </Button>
        )}
      </div>
    </Card>
  );
}

