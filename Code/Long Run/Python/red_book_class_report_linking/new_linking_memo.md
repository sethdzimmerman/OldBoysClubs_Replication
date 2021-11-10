## Overview Linking process:
- Pre-clean inputs (First, Last, Year, Age, HS)
- Assemble candidate pairs based on sufficient name and year match
- Assembling features (pre-cleaned inputs of all RB and CR entries)
- Compute similarity scores for each feature for all candidate pairs 
- Classifier (weights) using ~700 labels (coded by Mckay a while ago) either from old run or train new using current features
- Based on classifier, predict for each candidate pair probability (given features) of a legit match
- Keep the best match for each RB and CR ID
- Keep only matches with proba > .4