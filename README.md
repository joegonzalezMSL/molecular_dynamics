# molecular_dynamics
Codes and scripts for processing molecular dynamics simulations

All of the input scripts contain the following user defined variables. Use `sed` or something similar to edit them to suit your run.
```
_SAMPLE_ = structure file in the format of a normal LAMMPS data file
_P_      = pressure of the simulation in GPa
_T_      = temperature of the system, the initialization temperature is 2x this value. Adjust accordingly when running amorphous materials 
``` 
