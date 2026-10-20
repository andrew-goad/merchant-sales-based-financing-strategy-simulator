# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 37 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-36.md)

<a id="m-4c2752e0-e882-4b54-991c-fbf658dd3112"></a>
## Assistant · C109-M00789

C109-M00789 · 2026-09-03T01:32:34.227395-04:00 · active path

Preceding visible parent: [C109-M00788](part-36.md#m-ed82daf3-ba65-4b88-8ba9-71c55fbf7c14)

<!-- BEGIN_SOURCE_MESSAGE -->
This is the right correction. I inspected the updated DAX itself, and the editorial changes are implemented as described: natural returning-merchant grammar, negative liquidity rendered with `ABS()`, cleaner NSF/negative-balance wording, business-facing straight-through language, modeled post-financing liquidity, and the revised approval Decision language. [export reference: filecite | turn153file0 | L9-L23] [export reference: filecite | turn153file1 | L28-L38] [export reference: filecite | turn153file2 | L43-L52] [export reference: filecite | turn153file3 | L58-L68]

There is one important integration point I caught before you install it: **do not update the entire uploaded 14-measure file over your current C2 model as-is.** The updated file is based on the original narrative package, so its two QA measures do **not** include the strengthened R1 QA logic we added after discovering the Cartesian-query defect. The current QA patch explicitly checks exact final-decision row count and missing/unrecognized outcomes through `_DecisionRows`; that logic needs to remain. [export reference: filecite | turn155file0 | L31-L41]

The safest and fastest path is therefore to update **only the three visible narrative measures**. I prepared that bounded file from the exact updated DAX you received:

Download the 3-measure visible narrative wording patch (historical reference: `sandbox:[session]/MSBF_R26_P03_VISIBLE_NARRATIVE_WORDING_PATCH_R2_20260903.dax`; referenced bytes not established here)

If you want a single consolidated source file for final evidence/audit, I also created a merged version containing the new editorial DAX **plus the strengthened QA R1 measures**:

Download the merged 14-measure narrative file (historical reference: `sandbox:[session]/MSBF_R26_P03_PLAIN_LANGUAGE_NARRATIVES_EDITORIAL_R2_QA_R1_MERGED_20260903.dax`; referenced bytes not established here)

For physical implementation, I recommend the 3-measure patch:

1. In **DAX Query View**, open a new query and paste the complete `VISIBLE_NARRATIVE_WORDING_PATCH_R2` file.
2. Click **Run** first. It should return one confirmation row stating that the patch contains **3 measures**.
3. Click **Update model with changes**. It should show **3 changes**, not 14.
4. Keep all measures in your existing `P03 | Application Journey` display folder.
5. Return to P03 and verify that the three existing visuals still bind to:
   - `R26 P03 Merchant Operating Evidence Narrative`
   - `R26 P03 Structure Assessment Narrative`
   - `R26 P03 Decision Narrative`
6. Re-run the already-corrected QA query. Required results remain **2 rows / 0 rows / 1,500 rows**, with all 1,500 inventory rows `PASS`.
7. Visually inspect 749 / Baseline first. Its evidence paragraph should now say liquidity was **“negative at $170”**, not `-$170`; it should say **“No NSF events were observed”**; the structure assessment should say **“no revised terms or additional review were needed”** and identify **modeled post-financing liquidity**; and the Decision should no longer use “strongest supportable path.”
8. Then spot-check 738 Baseline/Recession Energy and one representative case from each remaining outcome class.

The technical rationale should remain untouched. That layer is intentionally the exact source-owned `evidence_why_text`, `underwriting_why_text`, and `decision_why_text`; the business-facing prose changes only the three visible narrative measures. [export reference: filecite | turn148file4 | L10-L15]

At this point I would treat P03 as **semantic architecture complete, lifecycle integration complete, QA framework complete, visible wording in final editorial refinement**. No source, strategy, lifecycle, monitoring, or R26 authority change is implicated.
<!-- END_SOURCE_MESSAGE -->


<a id="m-41fa9e89-3c69-498c-882c-b7f8fd24ecc5"></a>
## Assistant · C109-M00790

C109-M00790 · 2026-09-02T14:35:15.021873-04:00 · alternate branch

Preceding visible parent: [C109-M00703](part-32.md#m-e81cc52e-eced-4377-9388-99c0fdfc9b0a)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that’s the issue I see too. Once we add **Structure search** as its own block, P03 starts explaining essentially the same decision three different ways. That adds technical detail without giving the executive three genuinely different insights.

I’d simplify it to **three narrative blocks total**, each answering a distinct question:

1. **Merchant operating evidence**  
   *What did we observe about the merchant?*  
   Keep this separate because it presents the underlying evidence rather than interpreting the decision.

2. **Decision assessment**  
   Rename the current **Structure assessment narrative** to this.  
   *How did the strategy evaluate the request?*  
   This is where capacity, obligations, liquidity, risk tier, expected loss, risk-adjusted contribution, economic hurdle, etc. belong.

3. **Decision rationale**  
   Rename `P03 Decision Readout` to this.  
   *What did we ultimately decide, and why?*  
   This is also the natural home for the **candidate-search result whenever alternative structure search occurred**.

That gives you a much cleaner progression:

**Evidence → Assessment → Decision**

For the example we're looking at, the assessment explains that the requested economics fell below the governed hurdle. The decision rationale then explains what happened because of that assessment:

> The requested structure did not meet the governed economic hurdle. Alternative structure search evaluated [X] candidates; the selected proposal was identified on the review frontier and requires manual authorization.

That’s much more useful than adding another block between assessment and decision.

I’d also deliberately remove **“structure” from the narrative headings**. The page already has a **Proposed structure** section showing the actual terms. Repeating “structure” throughout the narratives makes the page feel more complicated than the underlying story actually is.

So I’d freeze the visible narrative headings as:

**Merchant operating evidence**  
**Decision assessment**  
**Decision rationale**

Then the overall P03 story becomes very intuitive:

**Merchant request** → what they asked for  
**Proposed structure** → what the strategy proposes, when applicable  
**Merchant operating evidence** → what we know about the merchant  
**Decision assessment** → how the request evaluated  
**Decision rationale** → what we decided and why, including alternative-search results when relevant

I think that’s the cleaner final architecture.
<!-- END_SOURCE_MESSAGE -->


<a id="m-10ddc1a2-5ce7-4475-b659-194748a745a4"></a>
## Assistant · C109-M00791

C109-M00791 · 2026-09-02T13:24:12.660454-04:00 · alternate branch

Preceding visible parent: [C109-M00676](part-31.md#m-6c2b4ae4-67d6-4c59-9003-7721d4dd5a4d)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes, **probably**, and I would approach it in this order:

## Option 1 — try native wrapping first
This is the simplest path.

### Step 1: Select the left profile visual
Click the full left profile card stack.

### Step 2: Apply settings specifically to **Industry**
On the right, under **Format visual**:

- **Apply settings to** → choose **Industry**

### Step 3: Turn on value text wrapping
Under **Value**:

- confirm **Text wrap = On**

You already appear to have that on in the screenshot, which is good.

### Step 4: Increase the value font slightly
Still under **Value**:

- increase **Font size** from **9** to **10**
- if 10 still looks too small, try **11**, but I would test **10 first**

### Step 5: Force the wrap by narrowing the profile visual a bit
Because Power BI usually won’t wrap text unless it needs to.

- click the left profile visual
- drag the **right edge slightly left**
- watch whether **Professional Services** breaks into:
  - `Professional`
  - `Services`

### Step 6: If needed, make the visual a little taller
If wrapping occurs but the second line gets cramped:

- drag the **bottom edge down slightly**
- or reduce **Padding** a little under the card formatting

---

# If Option 1 works
That is the cleanest solution.

My suggested final settings would be:

- **Value font size:** 10
- **Text wrap:** On
- **Visual width:** just narrow enough for “Professional Services” to split to two lines
- **Padding:** leave as-is unless the rows start feeling cramped

---

# Option 2 — if Power BI refuses to wrap the Industry value cleanly
Sometimes the card visual is inconsistent with wrapped value text.  
If that happens, use a **display measure/column with manual line breaks**.

This is the more controlled solution.

## Step 1: Create an Industry display measure
Create a new measure like this, adjusting table/column names to your model:

```DAX
P03 Industry Display =
VAR x = SELECTEDVALUE('YourTable'[Industry])
RETURN
    SWITCH(
        x,
        "Professional Services", "Professional" & UNICHAR(10) & "Services",
        "Healthcare Services", "Healthcare" & UNICHAR(10) & "Services",
        "Construction & Skilled Trades", "Construction &" & UNICHAR(10) & "Skilled Trades",
        x
    )
```

## Step 2: Replace the Industry field in the profile visual
In the left profile visual:

- remove the current **Industry** field
- add **P03 Industry Display**

## Step 3: Keep the label as “Industry”
Under formatting:

- **Apply settings to** → **Industry**
- make sure the label still reads **Industry**

## Step 4: Set formatting
Under **Value**:

- **Font size = 10**
- **Text wrap = On**

This gives you a much more reliable two-line result.

---

# My recommendation
I would do this:

## Recommended path
1. **Try native wrap first**
2. Set **Industry value font to 10**
3. Narrow the left profile visual slightly
4. If it still does not behave well, switch to a **display measure with UNICHAR(10)**

---

# Important design note
Be careful with the other possible industry values.

For example:

- **Healthcare Services**
- **Construction & Skilled Trades**
- **Restaurant & Food Service**

If you raise the font too much, some of those may become **3 lines** or feel crowded.

So my preferred target would be:

- **font size 10**
- **2 lines where needed**
- avoid going to 11 unless it still looks balanced

---

# Bottom line
**Yes — it is possible.**  
The best first attempt is:

- **Value → Text wrap = On**
- **Value font = 10**
- **slightly narrow the left profile visual**

If that does not give a stable result, use a **display measure with manual line breaks**.

If you want, I can give you the **exact DAX display measure** for all of your industry names in final polished form.
<!-- END_SOURCE_MESSAGE -->
