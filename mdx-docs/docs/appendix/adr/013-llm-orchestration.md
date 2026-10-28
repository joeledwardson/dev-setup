---
title: "ADR-013 LLM Orchestration"
---

# ADR-013 LLM Orchestration
Right - i've asked claude + chatgpt this a million times and I'm finally getting round to actually reviewing it myself...

The top of list from chatgpt was `superpowers`, for getting agents to review etc.. (and another one I need to google is the auto updating skills one)

ok LLM tokens make a bit more sense now - also as to why GPT OSS (20b) on this laptop was unable to call even a basic tool like `glob` or `read`... ollama was set to 4k tokens (which according to claude also includes all of opencodes tools + my prompt)

Claude made this diagram which helps to explain - makes alot more sense on my laptop with real constraints of RAM

![diagram about LLM sizes](/assets/diagram-context-vs-weights.svg)
