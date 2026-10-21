import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const {
      mission_id,
      patient_name,
      organ,
      destination,
      ambulance_plate,
      driver_id,
      route_points,
      event_type, // 'mission_created' or 'driver_started'
    } = await req.json();

    const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!saRaw) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not configured in Supabase.");
    }
    const sa = JSON.parse(saRaw);

    // 1. Generate Google OAuth2 Token from Service Account Key
    const pk = await jose.importPKCS8(sa.private_key, "RS256");
    const jwt = await new jose.SignJWT({
      iss: sa.client_email,
      sub: sa.client_email,
      aud: "https://oauth2.googleapis.com/token",
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    })
      .setProtectedHeader({ alg: "RS256" })
      .setIssuedAt()
      .setExpirationTime("1h")
      .sign(pk);

    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });

    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;
    if (!accessToken) {
      throw new Error("Failed to obtain Google OAuth token: " + JSON.stringify(tokenData));
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
    const targetPlate = ambulance_plate || "Emergency Unit";
    const targetDest = destination || "Apex Trauma Center";
    const targetOrgan = organ || patient_name || "Emergency Patient";
    const isDriverStart = event_type === "driver_started";

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 2. Collect ALL direct device tokens from device_tokens & users
    const [deviceRes, usersRes] = await Promise.all([
      supabase.from("device_tokens").select("token"),
      supabase.from("users").select("fcm_token").not("fcm_token", "is", null),
    ]);

    const tokenSet = new Set<string>();
    (deviceRes.data || []).forEach((d: any) => d.token && tokenSet.add(d.token));
    (usersRes.data || []).forEach((u: any) => u.fcm_token && tokenSet.add(u.fcm_token));

    console.log(`Event [${event_type || 'default'}]: Found ${tokenSet.size} active device tokens.`);

    // 3. Configure titles and sounds based on whether corridor is created or driver started
    const citizenTitle = isDriverStart
      ? "🚨 EMERGENCY GREEN CORRIDOR IN MOTION!"
      : "🚑 Green Corridor Scheduled";

    const citizenBody = isDriverStart
      ? `Ambulance ${targetPlate} has departed and is actively en route to ${targetDest}! Clear the left lane immediately!`
      : `Ambulance ${targetPlate} is scheduled for urgent transfer to ${targetDest}. Stand by for siren alerts when convoy departs.`;

    const channelId = isDriverStart ? "emergency_corridor_siren_v3" : "default";
    const soundName = isDriverStart ? "emergency_siren" : "default";
    const useDefaultSound = !isDriverStart;

    const sendPromises: Promise<any>[] = [];

    // Send direct notifications to all registered citizen devices
    for (const token of tokenSet) {
      const directMessage = {
        message: {
          token: token,
          notification: {
            title: citizenTitle,
            body: citizenBody,
          },
          android: {
            priority: "HIGH",
            notification: {
              channel_id: channelId,
              sound: soundName,
              default_sound: useDefaultSound,
              default_vibrate_timings: useDefaultSound,
              notification_priority: "PRIORITY_MAX",
              visibility: "PUBLIC",
            },
          },
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            sound: isDriverStart ? "emergency_siren" : "default",
            vehicle_number: targetPlate,
            destination: targetDest,
            mission_id: String(mission_id || ""),
            event_type: String(event_type || ""),
            route_points: JSON.stringify(route_points || []),
          },
        },
      };

      sendPromises.push(
        fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(directMessage),
        }).then(async (r) => {
          const body = await r.json();
          if (!r.ok) {
            console.warn(`Failed token ${token.slice(0, 15)}...:`, body);
          }
          return { status: r.status, body };
        }).catch((e) => ({ error: String(e) }))
      );
    }

    // 4. Also broadcast to topic 'emergency_corridor' as a distributed backup
    const topicMessage = {
      message: {
        topic: "emergency_corridor",
        notification: {
          title: citizenTitle,
          body: citizenBody,
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: channelId,
            sound: soundName,
            default_sound: useDefaultSound,
            default_vibrate_timings: useDefaultSound,
            notification_priority: "PRIORITY_MAX",
            visibility: "PUBLIC",
          },
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          sound: isDriverStart ? "emergency_siren" : "default",
          vehicle_number: targetPlate,
          destination: targetDest,
          mission_id: String(mission_id || ""),
          event_type: String(event_type || ""),
          route_points: JSON.stringify(route_points || []),
        },
      },
    };

    sendPromises.push(
      fetch(fcmUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(topicMessage),
      }).then(r => r.json()).catch(e => ({ error: String(e) }))
    );

    // 5. If driver_id is specified and mission was just created by hospital:
    // Send targeted dispatch assignment alert to the assigned driver
    let driverResult = null;
    if (driver_id && !isDriverStart) {
      const { data: driverUser } = await supabase
        .from("users")
        .select("fcm_token, name")
        .eq("id", driver_id)
        .single();

      if (driverUser && driverUser.fcm_token) {
        const driverMessage = {
          message: {
            token: driverUser.fcm_token,
            notification: {
              title: "🚨 NEW MISSION ASSIGNED - DRIVER DISPATCH",
              body: `Mission: ${targetOrgan} transfer to ${targetDest}. Open navigation HUD to start convoy.`,
            },
            android: {
              priority: "HIGH",
              notification: {
                sound: "default",
                default_sound: true,
                default_vibrate_timings: true,
                notification_priority: "PRIORITY_MAX",
                visibility: "PUBLIC",
              },
            },
            data: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              mission_id: String(mission_id || ""),
              sound: "default",
              event_type: "driver_assigned",
            },
          },
        };

        const dRes = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(driverMessage),
        });
        driverResult = await dRes.json();
      }
    }

    const directResults = await Promise.all(sendPromises);

    return new Response(
      JSON.stringify({
        success: true,
        eventType: event_type || "default",
        alertedTokensCount: tokenSet.size,
        directDeliveries: directResults,
        driverNotification: driverResult,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, error: err.message || String(err) }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});
