import pycc
import cccorelib
import numpy as np

CC = pycc.GetInstance()

print(cccorelib.GeometricalAnalysisTools.ComputeGravityCenter(CC.ccGenericPointCloud))
