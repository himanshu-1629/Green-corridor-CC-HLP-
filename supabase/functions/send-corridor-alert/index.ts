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

    console.log(`Found ${tokenSet.size} active device tokens to alert directly.`);

    // 3. Send high-priority direct push notification to EVERY device token
    // Standard Android notification ensures instant heads-up banner even when app is closed!
    const sendPromises: Promise<any>[] = [];

    for (const token of tokenSet) {
      const directMessage = {
        message: {
          token: token,
          notification: {
            title: "🚨 EMERGENCY GREEN CORRIDOR ACTIVE",
            body: `Ambulance ${targetPlate} is approaching towards ${targetDest}. Please clear the left lane immediately!`,
          },
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "emergency_corridor_siren_v3",
              sound: "emergency_siren",
              default_sound: false,
              default_vibrate_timings: false,
              notification_priority: "PRIORITY_MAX",
              visibility: "PUBLIC",
            },
          },
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            sound: "emergency_siren",
            vehicle_number: targetPlate,
            destination: targetDest,
            mission_id: String(mission_id || ""),
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
          title: "🚨 EMERGENCY GREEN CORRIDOR ACTIVE",
          body: `Ambulance ${targetPlate} en route to ${targetDest}. Please clear the left lane immediately!`,
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "emergency_corridor_siren_v3",
            sound: "emergency_siren",
            default_sound: false,
            default_vibrate_timings: false,
            notification_priority: "PRIORITY_MAX",
            visibility: "PUBLIC",
          },
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          sound: "emergency_siren",
          vehicle_number: targetPlate,
          destination: targetDest,
          mission_id: String(mission_id || ""),
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

    // 5. If driver_id is specified, send targeted driver alert
    let driverResult = null;
    if (driver_id) {
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
              title: "🚨 NEW MISSION DISPATCHED",
              body: `Mission: ${targetOrgan} transfer to ${targetDest}. Open navigation HUD now.`,
            },
            android: {
              priority: "HIGH",
              notification: {
                channel_id: "emergency_corridor_siren_v3",
                sound: "emergency_siren",
                default_sound: false,
                default_vibrate_timings: false,
                notification_priority: "PRIORITY_MAX",
                visibility: "PUBLIC",
              },
            },
            data: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              mission_id: String(mission_id || ""),
              sound: "emergency_siren",
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
