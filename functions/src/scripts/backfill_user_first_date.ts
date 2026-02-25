import * as admin from 'firebase-admin';
import * as fs from 'node:fs';
import * as path from 'node:path';

type DateSource =
  | 'firestore.creationTime'
  | 'auth.metadata.creationTime'
  | 'legacy.relapseArrays'
  | 'firestore.lastDeviceUpdate';

interface ScriptArgs {
  commit: boolean;
  limit: number;
  startAfter?: string;
  uidsFile?: string;
  output: string;
}

interface UserDecision {
  uid: string;
  resolved: boolean;
  source?: DateSource;
  userFirstDateIso?: string;
  reason?: string;
  nullPlusFields: string[];
}

interface RepairReport {
  startedAt: string;
  finishedAt?: string;
  dryRun: boolean;
  args: {
    limit: number;
    startAfter?: string;
    uidsFile?: string;
  };
  totals: {
    scanned: number;
    resolved: number;
    unresolved: number;
    updated: number;
  };
  bySource: Record<DateSource, number>;
  nullPlusAudit: {
    usersWithNullPlusFields: number;
    users: Array<{
      uid: string;
      fields: string[];
    }>;
  };
  unresolved: Array<{
    uid: string;
    reason: string;
  }>;
  processed: UserDecision[];
  checkpoint: {
    lastProcessedUid?: string;
  };
}

const DEFAULT_LIMIT = 500;

function parseArgs(argv: string[]): ScriptArgs {
  const args: ScriptArgs = {
    commit: false,
    limit: DEFAULT_LIMIT,
    output: path.resolve(
      process.cwd(),
      `backfill_user_first_date_${new Date().toISOString().replace(/[:.]/g, '-')}.json`
    ),
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--commit') {
      args.commit = true;
      continue;
    }
    if (arg === '--limit') {
      const value = Number(argv[++i]);
      if (!Number.isFinite(value) || value <= 0) {
        throw new Error('--limit must be a positive number');
      }
      args.limit = Math.floor(value);
      continue;
    }
    if (arg === '--start-after') {
      args.startAfter = argv[++i];
      continue;
    }
    if (arg === '--uids-file') {
      args.uidsFile = argv[++i];
      continue;
    }
    if (arg === '--output') {
      args.output = path.resolve(process.cwd(), argv[++i]);
      continue;
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  return args;
}

function ensureOutputDir(outputPath: string): void {
  const dir = path.dirname(outputPath);
  fs.mkdirSync(dir, { recursive: true });
}

function parseDateValue(value: unknown): Date | null {
  if (!value) return null;

  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }

  if (value instanceof admin.firestore.Timestamp) {
    const d = value.toDate();
    return Number.isNaN(d.getTime()) ? null : d;
  }

  if (typeof value === 'string') {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }

  if (typeof value === 'number') {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }

  if (
    typeof value === 'object' &&
    value !== null &&
    'toDate' in (value as Record<string, unknown>) &&
    typeof (value as { toDate: unknown }).toDate === 'function'
  ) {
    try {
      const d = (value as { toDate: () => Date }).toDate();
      return Number.isNaN(d.getTime()) ? null : d;
    } catch {
      return null;
    }
  }

  return null;
}

function parseEarliestLegacyDate(data: Record<string, unknown>): Date | null {
  const fields = [
    'userRelapses',
    'userWatchingWithoutMasturbating',
    'userMasturbatingWithoutWatching',
  ];

  const allDates: Date[] = [];

  for (const field of fields) {
    const value = data[field];
    if (!Array.isArray(value)) continue;
    for (const entry of value) {
      if (typeof entry !== 'string') continue;
      const date = parseDateValue(entry);
      if (date) allDates.push(date);
    }
  }

  if (allDates.length === 0) return null;
  allDates.sort((a, b) => a.getTime() - b.getTime());
  return allDates[0];
}

function readUidsFile(uidsFile: string): string[] {
  const content = fs.readFileSync(uidsFile, 'utf8').trim();
  if (!content) return [];

  if (content.startsWith('[')) {
    const parsed = JSON.parse(content);
    if (!Array.isArray(parsed)) {
      throw new Error('UIDs JSON file must contain an array');
    }
    return parsed
      .map((v) => String(v).trim())
      .filter((v) => v.length > 0);
  }

  return content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && !line.startsWith('#'));
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  ensureOutputDir(args.output);

  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const auth = admin.auth();

  const report: RepairReport = {
    startedAt: new Date().toISOString(),
    dryRun: !args.commit,
    args: {
      limit: args.limit,
      startAfter: args.startAfter,
      uidsFile: args.uidsFile,
    },
    totals: {
      scanned: 0,
      resolved: 0,
      unresolved: 0,
      updated: 0,
    },
    bySource: {
      'firestore.creationTime': 0,
      'auth.metadata.creationTime': 0,
      'legacy.relapseArrays': 0,
      'firestore.lastDeviceUpdate': 0,
    },
    nullPlusAudit: {
      usersWithNullPlusFields: 0,
      users: [],
    },
    unresolved: [],
    processed: [],
    checkpoint: {},
  };

  const usersRef = db.collection('users');
  let docs: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[] =
    [];

  if (args.uidsFile) {
    const uids = readUidsFile(args.uidsFile).slice(0, args.limit);
    for (const uid of uids) {
      const doc = await usersRef.doc(uid).get();
      if (doc.exists) {
        docs.push(
          doc as FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
        );
      } else {
        report.totals.unresolved += 1;
        report.unresolved.push({ uid, reason: 'user document not found' });
      }
    }
  } else {
    let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = usersRef
      .where('userFirstDate', '==', null)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(args.limit);

    if (args.startAfter) {
      query = query.startAfter(args.startAfter);
    }

    const snapshot = await query.get();
    docs = snapshot.docs;
  }

  let batch = db.batch();
  let batchOps = 0;

  for (const doc of docs) {
    const data = doc.data() as Record<string, unknown>;
    const uid = doc.id;
    report.totals.scanned += 1;
    report.checkpoint.lastProcessedUid = uid;

    const nullPlusFields: string[] = [];
    if (data.isPlusUser === null) nullPlusFields.push('isPlusUser');
    if (data.lastPlusCheck === null) nullPlusFields.push('lastPlusCheck');
    if (nullPlusFields.length > 0) {
      report.nullPlusAudit.usersWithNullPlusFields += 1;
      report.nullPlusAudit.users.push({ uid, fields: nullPlusFields });
    }

    let chosenDate: Date | null = null;
    let source: DateSource | undefined;

    const firestoreCreationTime = parseDateValue(data.creationTime);
    if (firestoreCreationTime) {
      chosenDate = firestoreCreationTime;
      source = 'firestore.creationTime';
    }

    if (!chosenDate) {
      try {
        const userRecord = await auth.getUser(uid);
        const authCreationTime = parseDateValue(userRecord.metadata.creationTime);
        if (authCreationTime) {
          chosenDate = authCreationTime;
          source = 'auth.metadata.creationTime';
        }
      } catch {
        // Keep fallback chain moving when auth record is unavailable.
      }
    }

    if (!chosenDate) {
      const legacyDate = parseEarliestLegacyDate(data);
      if (legacyDate) {
        chosenDate = legacyDate;
        source = 'legacy.relapseArrays';
      }
    }

    if (!chosenDate) {
      const lastDeviceUpdate = parseDateValue(data.lastDeviceUpdate);
      if (lastDeviceUpdate) {
        chosenDate = lastDeviceUpdate;
        source = 'firestore.lastDeviceUpdate';
      }
    }

    if (!chosenDate || !source) {
      const decision: UserDecision = {
        uid,
        resolved: false,
        reason: 'no valid source date found',
        nullPlusFields,
      };
      report.totals.unresolved += 1;
      report.unresolved.push({ uid, reason: decision.reason ?? 'unresolved' });
      report.processed.push(decision);
      continue;
    }

    const normalized = new Date(chosenDate.toISOString());
    const decision: UserDecision = {
      uid,
      resolved: true,
      source,
      userFirstDateIso: normalized.toISOString(),
      nullPlusFields,
    };
    report.processed.push(decision);
    report.totals.resolved += 1;
    report.bySource[source] += 1;

    if (args.commit) {
      batch.update(usersRef.doc(uid), {
        userFirstDate: admin.firestore.Timestamp.fromDate(normalized),
      });
      batchOps += 1;
      if (batchOps >= 400) {
        await batch.commit();
        report.totals.updated += batchOps;
        batch = db.batch();
        batchOps = 0;
      }
    }

    if (report.totals.scanned % 50 === 0) {
      fs.writeFileSync(args.output, JSON.stringify(report, null, 2));
    }
  }

  if (args.commit && batchOps > 0) {
    await batch.commit();
    report.totals.updated += batchOps;
  }

  report.finishedAt = new Date().toISOString();
  fs.writeFileSync(args.output, JSON.stringify(report, null, 2));

  console.log(`Done. Dry-run: ${report.dryRun}`);
  console.log(`Scanned: ${report.totals.scanned}`);
  console.log(`Resolved: ${report.totals.resolved}`);
  console.log(`Unresolved: ${report.totals.unresolved}`);
  console.log(`Updated: ${report.totals.updated}`);
  console.log(`Report: ${args.output}`);
}

main().catch((error) => {
  console.error('backfill_user_first_date failed:', error);
  process.exit(1);
});
