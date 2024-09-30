import pycc
import cccorelib
import numpy as np

CC = pycc.GetInstance()
dish = pycc.ccDish(0.5, 0.02, 0)
dish.showColors(True)

print(dish.getTransformation())

CC.addToDB(dish)
CC.updateUI()
