# M1.16 Attribution Methodology

## Method
`GOVERNED_PRIMARY_TOUCH_V1`

The application contract stores first touch, last touch, primary touch, assisted-touch count, confidence, parent-channel reconciliation, fallback, reasons, and evidence status. One primary touch receives financial allocation. Assisted touches remain available for analysis but do not split cost in v1.

## Fallback
1. Supported primary campaign/source.
2. Supported last non-direct touch.
3. Supported first touch where only one valid touch exists.
4. Accepted M1.2/M1.3 parent-channel fallback.
5. `BLOCKED` for material conflict or unsupported timing.

## Limits
This method is deterministic descriptive attribution. It makes no causal-lift or production multi-touch claim.
