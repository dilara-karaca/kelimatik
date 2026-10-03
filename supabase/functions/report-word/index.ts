import { withSupabase } from "npm:@supabase/server@^1";

const supportInbox = "kelimatik.support@gmail.com";
const reasons = new Set([
  "wrong_marked_is_correct",
  "both_incorrect",
  "other",
]);

const reasonLabels: Record<string, string> = {
  wrong_marked_is_correct:
    "Yanlış diye işaretlenen yazım aslında doğru",
  both_incorrect: "Her iki yazım da hatalı",
  other: "Başka bir sorun",
};

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") {
      return Response.json({ error: "invalid" }, { status: 405 });
    }

    const apiKey = Deno.env.get("RESEND_API_KEY")?.trim();
    if (!apiKey) {
      return Response.json({ error: "unavailable" }, { status: 500 });
    }

    const user = ctx.userClaims;
    if (!user) {
      return Response.json({ error: "auth" }, { status: 401 });
    }

    let body: Record<string, unknown>;
    try {
      const parsed = await req.json();
      if (
        parsed == null || typeof parsed !== "object" || Array.isArray(parsed)
      ) {
        return Response.json({ error: "invalid" }, { status: 400 });
      }
      body = parsed as Record<string, unknown>;
    } catch {
      return Response.json({ error: "invalid" }, { status: 400 });
    }

    const wordId = body.word_id;
    const correct = typeof body.correct === "string" ? body.correct.trim() : "";
    const wrong = typeof body.wrong === "string" ? body.wrong.trim() : "";
    const reason = typeof body.reason === "string" ? body.reason : "";
    const note = typeof body.note === "string" ? body.note.trim() : "";

    if (
      typeof wordId !== "number" ||
      !Number.isInteger(wordId) ||
      wordId <= 0 ||
      !reasons.has(reason) ||
      correct.length === 0 ||
      correct.length > 200 ||
      wrong.length === 0 ||
      wrong.length > 200 ||
      (reason === "other" && (note.length === 0 || note.length > 280))
    ) {
      return Response.json({ error: "invalid" }, { status: 400 });
    }

    const { data: stored, error: storeError } = await ctx.supabaseAdmin.rpc(
      "submit_word_report",
      {
        p_user_id: user.id,
        p_word_id: wordId,
        p_correct: correct,
        p_wrong: wrong,
        p_reason: reason,
        p_note: reason === "other" ? note : null,
      },
    );

    if (storeError) {
      const message = storeError.message ?? "";
      if (message.includes("word_report_rate_limited")) {
        return Response.json({ error: "rate_limited" }, { status: 429 });
      }
      if (message.includes("word_report_invalid")) {
        return Response.json({ error: "invalid" }, { status: 400 });
      }
      return Response.json({ error: "unavailable" }, { status: 500 });
    }

    const row = stored as {
      id?: string;
      created?: boolean;
      delivered?: boolean;
    } | null;
    if (!row?.id) {
      return Response.json({ error: "unavailable" }, { status: 500 });
    }
    if (row.delivered === true) {
      return Response.json({ ok: true });
    }

    let username = "";
    const { data: profile } = await ctx.supabaseAdmin
      .from("profiles")
      .select("username")
      .eq("id", user.id)
      .maybeSingle();
    if (profile && typeof profile.username === "string") {
      username = profile.username;
    }

    const from = Deno.env.get("REPORT_FROM_EMAIL")?.trim() ||
      "Kelimatik <onboarding@resend.dev>";
    const subject = oneLine(`Kelimatik kelime bildirimi: ${correct}`).slice(
      0,
      180,
    );
    const text = [
      "Kelimatik kelime bildirimi",
      "",
      `Kelime no: ${wordId}`,
      `Doğru yazım: ${correct}`,
      `Yanlış yazım: ${wrong}`,
      `Sorun: ${reasonLabels[reason] ?? reason}`,
      `Not: ${reason === "other" ? note : "—"}`,
      "",
      `Kullanıcı: ${username || "—"}`,
      `Hesap: ${user.email ?? "—"}`,
    ].join("\n");

    const emailResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: [supportInbox],
        reply_to: user.email ?? undefined,
        subject,
        text,
      }),
    });

    if (!emailResponse.ok) {
      return Response.json({ error: "unavailable" }, { status: 502 });
    }

    const { error: markError } = await ctx.supabaseAdmin.rpc(
      "mark_word_report_delivered",
      { p_id: row.id },
    );
    if (markError) {
      return Response.json({ error: "unavailable" }, { status: 502 });
    }

    return Response.json({ ok: true });
  }),
};

function oneLine(value: string): string {
  return value.replace(/[\r\n]+/g, " ").trim();
}
