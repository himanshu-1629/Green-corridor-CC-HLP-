import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }
  const {
    email,
    name,
    phone,
    licenseNumber,
    hospitalId,
  } = await req.json();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Generate temporary password
  const tempPassword =
    "GC" +
    Math.floor(
      100000 + Math.random() * 900000,
    );

  const { data, error } =
    await supabase.auth.admin.createUser({
      email,
      password: tempPassword,
      email_confirm: true,
    });

  if (error) {
    return new Response(
      JSON.stringify(error),
      {
        status: 400,
        headers: {
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }
await supabase.from("users").insert({
  id: data.user.id,
  name: name,
  email: email,
  phone: phone,
  license_number: licenseNumber,
  role: "Driver",
  hospital_id: hospitalId,
  is_available: true,
});
await fetch("https://api.emailjs.com/api/v1.0/email/send", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    service_id: "service_21azdn9",
    template_id: "template_w5nb4h7",
    user_id: "ydacdVHvuJ5e2SdZp",
    template_params: {
      name: name,
      email: email,
      password: tempPassword,
      hospital_name: "Green Corridor",
    },
  }),
});

  return new Response(
    JSON.stringify({
      success: true,
      email,
      password: tempPassword,
    }),
    {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    },
  );
});