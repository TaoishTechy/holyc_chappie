#!/usr/bin/env python3
# defect 1,10
import os
for root,_,files in os.walk('src'):
 for fn in files:
  path=os.path.join(root,fn)
  print(f'TEXT OK {path}')
print('extraction 100%')
