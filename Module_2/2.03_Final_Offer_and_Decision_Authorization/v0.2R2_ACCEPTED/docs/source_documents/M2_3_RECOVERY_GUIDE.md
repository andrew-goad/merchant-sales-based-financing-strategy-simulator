# M2.3 Recovery Guide

If Program 150 fails before commit: click Stop, run `ROLLBACK;`, execute 148A, and verify `recovery_status = PASS` before continuing.

If validation or reporting fails after Program 150 commits, preserve the generated population and correct only downstream validation/reporting source. Do not regenerate accepted source records unless a physical generation defect is proven.
