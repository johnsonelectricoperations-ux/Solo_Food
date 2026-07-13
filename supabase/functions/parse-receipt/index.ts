// 영수증/주문내역 → 식재료 목록 파싱 (idea.md 킬러 기능 1)
//
// 앱의 MockReceiptParser를 대체하는 실제 구현.
// LLM API 키는 이 서버(Edge Function)에만 있고 앱에는 절대 넣지 않는다.
//
// 배포: supabase functions deploy parse-receipt
// 키 설정: supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//
// 요청:  POST { imageBase64?: string, mediaType?: string, text?: string }
// 응답:  { items: [{name, emoji, section, count, daysLeft}], excluded: string[] }

import Anthropic from "npm:@anthropic-ai/sdk";

// 파싱은 짧은 구조화 출력 작업이라 상위 모델이 필수는 아니다.
// 비용을 낮추려면 "claude-haiku-4-5"로 바꿔 A/B 해볼 것.
const MODEL = "claude-opus-4-8";

const OUTPUT_SCHEMA = {
  type: "object",
  properties: {
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: { type: "string", description: "정규화된 식재료 이름 (예: '두부', '애호박')" },
          emoji: { type: "string", description: "재료를 나타내는 이모지 1개" },
          section: {
            type: "string",
            enum: ["shelf1", "shelf2", "shelf3", "door", "freezer"],
            description:
              "보관 구역: shelf1=냉장(두부/계란 등), shelf2=반찬/김치, shelf3=채소, door=음료/소스, freezer=냉동",
          },
          count: { type: "integer", description: "개수 (계란 10구면 10, 셀 수 없으면 1)" },
          daysLeft: {
            type: "integer",
            description: "구매일 기준 추정 보관 가능 일수 (예: 두부 3, 애호박 7, 냉동육 60)",
          },
        },
        required: ["name", "emoji", "section", "count", "daysLeft"],
        additionalProperties: false,
      },
    },
    excluded: {
      type: "array",
      items: { type: "string" },
      description: "식재료가 아니라서 제외한 품목의 원문 (휴지, 종량제봉투 등)",
    },
  },
  required: ["items", "excluded"],
  additionalProperties: false,
} as const;

const SYSTEM = `한국 마트 영수증과 온라인 주문내역에서 식재료를 추출하는 도우미다.
- 품명은 축약 코드일 수 있다 (예: "P)애호박1入" → 애호박 1개).
- 식재료가 아닌 품목(생활용품, 봉투, 배송비, 할인 행)은 items에 넣지 말고 excluded에 원문 그대로 담는다.
- daysLeft는 해당 재료의 일반적인 냉장/냉동 보관 가능 일수를 보수적으로 추정한다.
- 확신이 없는 품목은 빼지 말고 items에 넣는다 — 유저가 앱에서 확인·수정한다.`;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "POST only" }, { status: 405 });
  }

  const { imageBase64, mediaType, text } = await req.json();
  if (!imageBase64 && !text) {
    return Response.json({ error: "imageBase64 또는 text가 필요합니다" }, { status: 400 });
  }

  const client = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

  const content: Anthropic.ContentBlockParam[] = [];
  if (imageBase64) {
    content.push({
      type: "image",
      source: { type: "base64", media_type: mediaType ?? "image/jpeg", data: imageBase64 },
    });
    content.push({ type: "text", text: "이 영수증에서 식재료를 추출해줘." });
  } else {
    content.push({ type: "text", text: `다음 주문내역에서 식재료를 추출해줘:\n\n${text}` });
  }

  const response = await client.messages.create({
    model: MODEL,
    max_tokens: 8192,
    system: SYSTEM,
    output_config: { format: { type: "json_schema", schema: OUTPUT_SCHEMA } },
    messages: [{ role: "user", content }],
  });

  if (response.stop_reason === "refusal") {
    return Response.json({ error: "요청을 처리할 수 없습니다" }, { status: 422 });
  }

  const textBlock = response.content.find((b) => b.type === "text");
  if (!textBlock || textBlock.type !== "text") {
    return Response.json({ error: "빈 응답" }, { status: 502 });
  }

  // 구조화 출력이라 스키마에 맞는 JSON이 보장된다
  return Response.json(JSON.parse(textBlock.text));
});
