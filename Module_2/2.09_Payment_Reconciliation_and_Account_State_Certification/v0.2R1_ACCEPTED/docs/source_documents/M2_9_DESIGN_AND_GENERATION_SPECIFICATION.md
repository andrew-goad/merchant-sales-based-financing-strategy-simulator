# M2.9 Design and Generation Specification

M2.9 independently reconciles the accepted M2.8 evidence chain.

```text
Expected net processed = scheduled − returned + retry
Expected ending exposure = source exposure − expected net processed
```

The seven-event temporary cycle reconciles to:

```text
Scheduled amount              $194.25
Returned amount                $27.75
Retry amount                   $27.75
Expected net processed        $194.25
Observed processed            $194.25
Reconciliation variance         $0.00
Active ending exposure        $323.79
```

The return and retry rows form one synthetic exception case, open for one day and resolved by retry. No unresolved exception remains. The review-hold record is certified as a review-hold state rather than misclassified as a payment exception.

Final account certification:

```text
57 CERTIFIED_CLOSED_NO_PROCESSING
1 CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY
1 CERTIFIED_REVIEW_HOLD
Total certified exposure      $785.48
```
