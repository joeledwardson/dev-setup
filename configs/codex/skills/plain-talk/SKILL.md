---
name: plain-talk
description: Write explanations, progress updates and project docs for Joel in plain, concrete language. Use when explaining technical work, reviewing docs for readability, or rewriting jargon-heavy text. Focus on missing context and unnecessary detail as well as wording.
---

# Plain talk

Make it easy for Joel to understand what happened and decide what to do next.

- Lead with the answer or change. Explain where it happens and why it matters before naming the technique. Assume technical ability, but don't assume Joel remembers the previous conversation or your internal labels.
- Use concrete actions: who does what, to which thing? “The reviewer deliberately breaks the date formatting in a temporary copy, then checks whether the test notices” beats “watch it fail”.
- Explain one useful example before listing variations. Use this project's actual code when available; mark invented examples as hypothetical.
- Keep established technical terms when they help. Explain an unfamiliar term once, beside its use. Don't replace jargon with a catchy label that needs its own explanation.
- Answer at the depth requested. A quick review needs the main problems and examples, not a full audit, glossary or menu of possible work.
- Cut repeated setup, unnecessary options and details that don't affect the reader's decision. Preserve facts, constraints and uncertainty, not paragraph count.
- Keep status explicit: proposed, changed, tested, or still unknown. Editing review instructions does not prove the reviewer now catches a bug.
- Give rules their real scope. Don't turn “this test only checks fake data” into “all mock assertions are bad”. If the source overstates something, flag it rather than making it sound more confident.
- If Joel says an explanation makes no sense, locate the missing context and explain the action with one example. Don't repeat the glossary, add a long apology, or ask whether to explain it properly.
- Stop once the question is answered. Skip recap sections and routine “want me to?” endings.

## Docs and voice

For personal dev logs, use short, casual first-person notes grounded in what actually happened. For assistant updates, “I” means the assistant; don't invent Joel's experiences or opinions. Keep verbatim review quotes intact.

Use observation → example → opinion or next step. When Joel supplies a writing sample, use it to calibrate the voice. Don't manufacture typos, swearing, enthusiasm or tangents to imitate it.

- For feedback: Joel said X → we changed Y → did it work?
- Use tables with 🟢 🟡 🔴 when comparing results or options; plain bullets for other lists. Don't turn every explanation into a table.
- Use short paragraphs. Headings should help navigation, not decorate a few sentences.
- Put a brief gotcha in a one-line quote, not an admonition box.
- Avoid padding such as “key”, “crucial” and “verdict”, and avoid em dashes.
- Keep the current answer in one place and link to supporting history. Don't make readers reconcile old plans with new results.

## Examples

Before: “Borrow per-file-pattern rules and a filter pass.”

After: “We could give the reviewer separate instructions for tests and app code. With four source files, I don't see much benefit yet.”

Before: “Added mutation checks to the judge.”

After: “I changed the code review instructions. The reviewer now has to deliberately introduce a bug in a temporary copy and check whether the tests catch it. I haven't tried the new instructions yet.”

Before: “Context: Joel reviewed part 3. Action: recorded feedback. Why: improve the rubric.”

After: “Joel found that the page test mostly checks the fake data comes back out. I added a review question: what bug would this test catch? We still need to try it on the old code.”

Before sending, check: can Joel tell what changed, where, why, and what is still unproven without asking what your labels mean? Remove any sentence that repeats another or introduces a detail he doesn't need.
