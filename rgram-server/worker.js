// R Gram registry — Cloudflare Worker + KV (binding: RGRAM_KV; optional env RGRAM_ADMINS="id1,id2").
//
//   GET  /v1/profiles?ids=1,2,3   -> {"profiles": {"1": {"banner": "https://…", "premium": true}}}
//   GET  /v1/banner/<userId>      -> the banner JPEG
//   PUT  /v1/me                   -> {"userId": 1, "banner": "<base64 jpeg>" | null}   header X-RGram-Token
//
// A user appears in the registry only after their R Gram app has called PUT /v1/me, so "has a record"
// means "uses R Gram". R Premium is granted by the operator by setting "premium": true on the record
// (KV key `u:<id>`), e.g. from your own payment/approval flow; it is not tied to Telegram Premium.
//
// SECURITY LIMIT: the first token that claims a userId owns that record (trust-on-first-use). The
// server cannot prove the caller really owns that Telegram account. For stronger binding add a
// verification step (e.g. a bot the user messages with a one-time code) before accepting PUT /v1/me.

const MAX_BANNER_BYTES = 450_000;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cors = { "access-control-allow-origin": "*" };

    if (request.method === "GET" && url.pathname === "/v1/profiles") {
      const ids = (url.searchParams.get("ids") || "").split(",").filter((s) => /^\d{1,15}$/.test(s)).slice(0, 100);
      const profiles = {};
      for (const id of ids) {
        const rec = await env.RGRAM_KV.get(`u:${id}`, "json");
        if (rec) {
          profiles[id] = {
            banner: rec.hasBanner ? `${url.origin}/v1/banner/${id}?v=${rec.v || 0}` : null,
            premium: !!rec.premium,
          };
        }
      }
      return Response.json({ profiles }, { headers: cors });
    }

    const bannerMatch = url.pathname.match(/^\/v1\/banner\/(\d{1,15})$/);
    if (request.method === "GET" && bannerMatch) {
      const data = await env.RGRAM_KV.get(`b:${bannerMatch[1]}`, "arrayBuffer");
      if (!data) return new Response("not found", { status: 404 });
      return new Response(data, { headers: { "content-type": "image/jpeg", "cache-control": "public, max-age=3600", ...cors } });
    }

    if (request.method === "PUT" && url.pathname === "/v1/me") {
      const token = request.headers.get("X-RGram-Token") || "";
      if (token.length < 16) return new Response("bad token", { status: 401 });
      let body;
      try { body = await request.json(); } catch { return new Response("bad json", { status: 400 }); }
      const id = String(body.userId || "");
      if (!/^\d{1,15}$/.test(id)) return new Response("bad userId", { status: 400 });

      const rec = (await env.RGRAM_KV.get(`u:${id}`, "json")) || { token, premium: false, hasBanner: false, v: 0 };
      if (rec.token !== token) return new Response("forbidden", { status: 403 });

      if (body.banner === null) {
        await env.RGRAM_KV.delete(`b:${id}`);
        rec.hasBanner = false;
      } else if (typeof body.banner === "string") {
        const bytes = Uint8Array.from(atob(body.banner), (c) => c.charCodeAt(0));
        if (bytes.length > MAX_BANNER_BYTES) return new Response("too large", { status: 413 });
        if (!(bytes[0] === 0xff && bytes[1] === 0xd8)) return new Response("not a jpeg", { status: 415 });
        await env.RGRAM_KV.put(`b:${id}`, bytes);
        rec.hasBanner = true;
      }
      rec.v = (rec.v || 0) + 1;
      await env.RGRAM_KV.put(`u:${id}`, JSON.stringify(rec));
      return Response.json({
        profiles: { [id]: { banner: rec.hasBanner ? `${url.origin}/v1/banner/${id}?v=${rec.v}` : null, premium: !!rec.premium } },
      }, { headers: cors });
    }

    return new Response("not found", { status: 404 });
  },
};
