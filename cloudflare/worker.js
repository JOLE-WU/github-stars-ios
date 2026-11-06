/**
 * SGit —— 自建翻译服务（Cloudflare Workers AI）
 *
 * 用 Meta 开源模型 @cf/meta/m2m100-1.2b 在 Cloudflare 边缘节点把英文翻译成中文。
 * 免费额度 10,000 神经元/天，国内可直连，无需 API Key。
 *
 * 部署：在 cloudflare/ 目录执行  wrangler deploy
 * 诊断：浏览器打开 *.workers.dev 会返回 JSON，其中 ai_binding 应为 true。
 */

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status: status || 200,
    headers: { ...CORS, "Content-Type": "application/json; charset=utf-8" }
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS });
    }

    // GET：健康检查 + 绑定诊断
    if (request.method !== "POST") {
      return json({
        ok: true,
        service: "SGit translate worker",
        ai_binding: !!env.AI,
        model: "@cf/meta/m2m100-1.2b",
        hint: 'Send POST {"text": "english text"}'
      });
    }

    if (!env.AI) {
      return json({
        translatedText: "",
        error: "AI binding missing：wrangler.toml 需包含 [ai] binding = \"AI\"，然后重新 wrangler deploy"
      }, 500);
    }

    let text;
    try {
      const body = await request.json();
      text = String((body && body.text) || "").trim();
    } catch (e) {
      return json({ translatedText: "", error: "invalid JSON body" }, 400);
    }
    if (!text) return json({ translatedText: "" });

    // m2m100 在 Workers AI 上以「完整语言名」最稳妥；
    // 不同时期后端对语言代码(zh)的兼容性不一致，故依次尝试多种写法。
    const targets = ["chinese", "Chinese", "zh", "zh-CN"];
    let lastErr = "";
    for (const target_lang of targets) {
      try {
        const res = await env.AI.run("@cf/meta/m2m100-1.2b", {
          text: text,
          source_lang: "english",
          target_lang: target_lang
        });
        const t = res && (res.translated_text || res.translatedText);
        if (t && t !== text) {
          return json({ translatedText: t, used_lang: target_lang });
        }
        lastErr = "target_lang=" + target_lang + " 返回空或原文";
      } catch (e) {
        lastErr = "target_lang=" + target_lang + " → " + String((e && e.message) || e);
      }
    }
    return json({ translatedText: "", error: lastErr || "翻译失败" });
  }
};
