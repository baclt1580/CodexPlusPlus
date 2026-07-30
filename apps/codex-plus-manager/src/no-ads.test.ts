import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { describe, it } from "node:test";

describe("no-ad distribution", () => {
  it("does not expose or load recommendations in the manager", async () => {
    const source = await readFile(new URL("./App.tsx", import.meta.url), "utf8");

    assert.doesNotMatch(source, /id: "recommendations"/);
    assert.doesNotMatch(source, /call<[^>]+>\("load_ads"\)/);
  });

  it("does not expose or fetch ads in the injected Codex menu", async () => {
    const source = await readFile(new URL("../../../assets/inject/renderer-inject.js", import.meta.url), "utf8");

    assert.doesNotMatch(source, /data-codex-plus-tab="(?:sponsor|support)"/);
    assert.doesNotMatch(source, /fetchCodexPlusAds/);
  });
});
