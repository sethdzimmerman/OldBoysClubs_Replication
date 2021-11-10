## Overview Linking process:
- Pre-clean inputs (First, Last, Year, Age, HS)
- Assemble candidate pairs based on sufficient name and year match
- Assembling features (pre-cleaned inputs of all RB and CR entries)
- Compute similarity scores for each feature for all candidate pairs 
- Classifier (weights) using ~700 labels (coded by Mckay a while ago) either from old run or train new using current features
- Based on classifier, predict for each candidate pair probability (given features) of a legit match
- Keep the best match for each RB and CR ID
- Keep only matches with proba > .4


## Changes
- Pre-cleaning of names 
    - Suffixes, 
    - composite last names, 
    - alphanumerics
- Pre-cleaning of HS 
    - Remove geographical reference, 
    - map a few common schools that are reference differently to a common reference (Philips Academy vs Andover), 
    - Remove generic suffix (school, high school, hs))
- Classifier:
    - Use old weights (as done before)
    - vs re-train based on new pre-cleaned inputs
- Computing similarity scores:
    - Use all first and middle names instead of only very first name as `first`
    - Set `hs_score` to mean if HS string is missing for a match (instead of 0)
    - Added a `first_only_score` which is the top match of any first/middle name in CR name for the very first name in RB name
    - Added sorted Initials of first name (this didn't work so well)

## Promising versions
- Don't retrain classifier, fix HS scores
    - 940 additions, 58 deletions
    - Based on random sample of 50 additions, 68% are legit
    - 34% deletions are legit
- Retrain classifier, fix HS scores, add the `first_only_score` (but keep the `first_all_score` as well)
    - 724 additions, 186 deletions
    - Based on random sample of 50 additions/deletions, 98% of additions and 32% of deletions are legit


## What else could be done
- Construct link as intersection of these two versions
    - That would be 727 additions , 163 deletions
- Restrict eligible prob. scores more (would delete legit matches as well though)
    - ~100 in old version and 200 in new version are between .4 and .5 prob. scores with a fair share of them illegit .14
- Make more labels
- Leave it be and decide to go with either old classifier (new inputs) and accept a couple of illegit additions or the new classifier (new inputs) and accepts a few illegitimate deletions
