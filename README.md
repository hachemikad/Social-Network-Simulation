# Social-Network-Simulation
This is a simulation of a social sharing network using NetLogo.

Note: this is an early version of the simulation, so for now it's not perfect, and there is yet lot of stuff to be added in future versions (e.g. more metrics, plotting, adding automatic generation of user input, etc).

## What's in the folder?

You will need to download all the files and put them in the same repo (unless you change the repos in the __includes for the .nls files inside of the NetLogo file) to run the simulation, here's a brief description of each file:
* generate_input.py: python script for generating the necessary parameters to run the simulation (i.e. number of peers, documents and number of ticks), you'll need to run this file first to generate the parameters for the simulation, else they will be set on default (40 peers, 120 documents, 3000 ticks).
* set_variables.nls: generated file by the python script containing the procedure used to initiate the global variables, this file is included and used by the main NetLogo simulation.
* set_variables.txt: text file used as a template to generate the global variables (you can used this file to modify other global variables if you wish).
* social-network-simulation.nlogo: this is the file for the NetLogo simulation (you will need to install NetLogo 5.1.0 to run it).


