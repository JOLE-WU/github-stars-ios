/**
 * GitHub 高星项目 App —— 自建翻译服务（Cloudflare Workers AI）
 *
 * 使用 Meta 开源模型 @cf/meta/m2m100-1.2b 在 Cloudflare 边缘节点把英文翻译成中文。
 * 免费额度 10,000 神经元/天（约数百条翻译），国内可直连，无需 API Key。
 *
 * 部署步骤见仓库 README 的「自建翻译服务」章节。
 */

export default {
  async fetch(request, env) {
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    };

    // 处理 CORS 预检
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: cors });
    }

    // 健康检查 / 使用说明
    if (request.method !== "POST") {
      return new Response("Send POST {\"text\": \"english text\"}", { headers: cors });
    }

    try {
      const { text } = await request.json();
      if (!text || !String(text).trim()) {
        return new Response(JSON.stringify({ translatedText: "" }), {
          headers: { ...cors, "Content-Type": "application/json" }
        });
      }

      const res = await env.AI.run("@cf/meta/m2m100-1.2b", {
        text: String(text),
        source_lang: "en",
        target_lang: "zh"
      });

      const translated = (res && (res.translated_text || res.translatedText)) || text;
      return new Response(JSON.stringify({ translatedText: translated }), {
        headers: { ...cors, "Content-Type": "application/json" }
      });
    } catch (e) {
      // 任何错误都回退原文，保证 App 不崩
      return new Response(JSON.stringify({ translatedText: "", error: String(e) }), {
        headers: { ...cors, "Content-Type": "application/json" }
      });
    }
  }
};
