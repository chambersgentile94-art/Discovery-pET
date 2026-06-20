type AlertEvent = {
  id: string;
  user_id: string;
  report_id: string;
  distance_km: number;
  push_attempts: number;
  animal_reports?: {
    title?: string;
    category?: string;
    approximate_address?: string | null;
  } | null;
};

type UserDevice = {
  id: string;
  push_token: string;
};

type FirebaseServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const firebaseServiceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';
const firebaseProjectIdOverride = Deno.env.get('FIREBASE_PROJECT_ID') ?? '';
const maxEvents = Number(Deno.env.get('MAX_ALERT_PUSH_EVENTS') ?? '25');

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Supabase server env vars are not configured.' }, 500);
  }

  if (!firebaseServiceAccountJson) {
    return jsonResponse({ error: 'FIREBASE_SERVICE_ACCOUNT_JSON is not configured.' }, 500);
  }

  const serviceAccount = JSON.parse(firebaseServiceAccountJson) as FirebaseServiceAccount;
  const firebaseProjectId = firebaseProjectIdOverride || serviceAccount.project_id;
  const accessToken = await getFirebaseAccessToken(serviceAccount);

  const events = await fetchPendingAlertEvents();
  const results = [];

  for (const event of events) {
    try {
      const devices = await fetchUserDevices(event.user_id);

      if (devices.length === 0) {
        await updateAlertEventPushState(event.id, {
          push_status: 'skipped',
          push_attempts: event.push_attempts + 1,
          push_last_error: 'User has no active push devices.',
          push_attempted_at: new Date().toISOString(),
        });
        results.push({ event_id: event.id, status: 'skipped', reason: 'no_devices' });
        continue;
      }

      const sendResults = [];
      for (const device of devices) {
        const sent = await sendFirebaseMessage({
          accessToken,
          projectId: firebaseProjectId,
          token: device.push_token,
          event,
        });
        sendResults.push(sent);
      }

      const failed = sendResults.filter((item) => !item.ok);
      if (failed.length === sendResults.length) {
        await updateAlertEventPushState(event.id, {
          push_status: 'failed',
          push_attempts: event.push_attempts + 1,
          push_last_error: failed.map((item) => item.error).join(' | ').slice(0, 1000),
          push_attempted_at: new Date().toISOString(),
        });
        results.push({ event_id: event.id, status: 'failed', sent: 0, failed: failed.length });
        continue;
      }

      await updateAlertEventPushState(event.id, {
        push_status: 'sent',
        push_attempts: event.push_attempts + 1,
        push_last_error: failed.length > 0 ? failed.map((item) => item.error).join(' | ').slice(0, 1000) : null,
        push_attempted_at: new Date().toISOString(),
        push_sent_at: new Date().toISOString(),
      });
      results.push({
        event_id: event.id,
        status: 'sent',
        sent: sendResults.length - failed.length,
        failed: failed.length,
      });
    } catch (error) {
      await updateAlertEventPushState(event.id, {
        push_status: 'failed',
        push_attempts: event.push_attempts + 1,
        push_last_error: String(error).slice(0, 1000),
        push_attempted_at: new Date().toISOString(),
      });
      results.push({ event_id: event.id, status: 'failed', error: String(error) });
    }
  }

  return jsonResponse({ processed: results.length, results });
});

async function fetchPendingAlertEvents(): Promise<AlertEvent[]> {
  const url = new URL('/rest/v1/alert_events', supabaseUrl);
  url.searchParams.set('push_status', 'eq.pending');
  url.searchParams.set('status', 'eq.pending');
  url.searchParams.set('select', 'id,user_id,report_id,distance_km,push_attempts,animal_reports(title,category,approximate_address)');
  url.searchParams.set('order', 'created_at.asc');
  url.searchParams.set('limit', String(maxEvents));

  const response = await fetch(url, {
    headers: supabaseHeaders(),
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch alert events: ${response.status} ${await response.text()}`);
  }

  return await response.json() as AlertEvent[];
}

async function fetchUserDevices(userId: string): Promise<UserDevice[]> {
  const url = new URL('/rest/v1/user_devices', supabaseUrl);
  url.searchParams.set('user_id', `eq.${userId}`);
  url.searchParams.set('is_active', 'eq.true');
  url.searchParams.set('select', 'id,push_token');

  const response = await fetch(url, {
    headers: supabaseHeaders(),
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch user devices: ${response.status} ${await response.text()}`);
  }

  return await response.json() as UserDevice[];
}

async function updateAlertEventPushState(eventId: string, payload: Record<string, unknown>) {
  const url = new URL('/rest/v1/alert_events', supabaseUrl);
  url.searchParams.set('id', `eq.${eventId}`);

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      ...supabaseHeaders(),
      'content-type': 'application/json',
      prefer: 'return=minimal',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`Failed to update alert event: ${response.status} ${await response.text()}`);
  }
}

async function sendFirebaseMessage(params: {
  accessToken: string;
  projectId: string;
  token: string;
  event: AlertEvent;
}): Promise<{ ok: boolean; error?: string }> {
  const report = params.event.animal_reports;
  const title = 'Nueva alerta cerca tuyo';
  const body = report?.title
    ? `${report.title} · ${Number(params.event.distance_km).toFixed(1)} km`
    : `Hay un nuevo reporte a ${Number(params.event.distance_km).toFixed(1)} km`;

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${params.projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${params.accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: params.token,
          notification: { title, body },
          data: {
            type: 'alert_event',
            alert_event_id: params.event.id,
            report_id: params.event.report_id,
            screen: 'alert_events',
          },
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'alerts',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    return { ok: false, error: `${response.status} ${await response.text()}` };
  }

  return { ok: true };
}

async function getFirebaseAccessToken(serviceAccount: FirebaseServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const jwtHeader = { alg: 'RS256', typ: 'JWT' };
  const jwtPayload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const unsignedJwt = `${base64UrlEncode(JSON.stringify(jwtHeader))}.${base64UrlEncode(JSON.stringify(jwtPayload))}`;
  const signature = await signJwt(unsignedJwt, serviceAccount.private_key);
  const jwt = `${unsignedJwt}.${signature}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    throw new Error(`Failed to get Firebase access token: ${response.status} ${await response.text()}`);
  }

  const data = await response.json() as { access_token?: string };
  if (!data.access_token) {
    throw new Error('Firebase access token response has no access_token.');
  }

  return data.access_token;
}

async function signJwt(content: string, privateKeyPem: string): Promise<string> {
  const keyData = pemToArrayBuffer(privateKeyPem);
  const key = await crypto.subtle.importKey(
    'pkcs8',
    keyData,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(content),
  );

  return base64UrlEncode(signature);
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');

  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

function base64UrlEncode(input: string | ArrayBuffer): string {
  const bytes = typeof input === 'string'
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);

  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function supabaseHeaders() {
  return {
    apikey: serviceRoleKey,
    authorization: `Bearer ${serviceRoleKey}`,
  };
}

function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'content-type': 'application/json',
    },
  });
}
