# Social-Network-Simulation
This is a simulation of a social sharing network using NetLogo. Netlogo is an agent-based programming tool designed for modeling networks,  real world scenarios, emerging phenomenoms, and much more.

Note: we're still working on the simulation, so for now it's not perfect, and there is yet lot of stuff to be added in future versions (e.g. more metrics, plotting, adding automatic generation for predefined graphs for example a small world, etc).

## What's in the folder?

You will need to download all the files and put them in the same repo (unless you change the repos in the <code> __includes </code> for the .nls files inside of the NetLogo file) to run the simulation, here's a brief description of each file:
* generate_input.py: python script for generating the necessary parameters to run the simulation (i.e. number of peers, documents and number of ticks), you'll need to run this file first to generate the parameters for the simulation, else they will be set on default (40 peers, 120 documents, 3000 ticks).
* set_variables.nls: generated file by the python script containing the procedure used to initiate the global variables, this file is included and used by the main NetLogo simulation.
* set_variables.txt: text file used as a template to generate the global variables (you can used this file to modify other global variables if you wish).
* social-network-simulation.nlogo: this is the file for the NetLogo simulation (you will need to install NetLogo 5.1.0 to run it).

## HOW TO USE IT

Before running the simulation the user must click on the set-up button to set the network for the first time.
First you have to pay attention to the python file that comes with the simulation, it will generate the global variable for the size of the network (although we can use sliders for that, but we discarded of them to make the GUI less cluttered).

The user can choose among the different metrics for ranking documents, and behaviors for the peers. The ranking metrics are the strategies used to rank the documents (peer similarity, document popularity, etc), and the peer behavior, is the behavior of the peer toward the list of ranked documents, will he like the top K documents (good behavior), or rather choose from the bottom of the list min K (bad behavior), or it can be chosen at random (random behavior).

Like behavior: 
- standard: this is the behavior of the peer if he will like the top K regardless of the similarity in labels or not.
- relevant: the peer will only like the documents that he finds relevant to him.
- like miss: the peer will only like the miss in the top K (this behavior is relevant if we have a different type of peers and they have a different utility function for calculating their score, e.g. malicious peers)

You will notice in the GUI sliders for choosing populations, these are used to make use of predefined profiles for the peers: what this means, is for example is we have 40 peers and the user chose 50% of "Crowd Followers", we will end up with 20 peers that are crowd followers, i.e. use the same metric (document popularity) and have the same behavior.

The profiles make use of the ranking metrics:
* The crowd followers use document popularity.
* The friend followers use peer similarity.
* Random peers (follow random predefined strategies).
* The attackers for now use a random strategy (each one of them picks a strategy at random) as their goal is not liking documents but distributing their files in the network.

We have the switch "dynamic_network" which if set at ON, will enable peers to join and disconnect from the network, it's important to note that a disconnected peer cut off all his connections (links), and then when he's online again he restores them.

The button step runs the simulation for one tick.

The button go runs the simulation until the user stops it or it stops by itself if the user definer a limit of ticks (using the python script) and the switch "stop?" is set to ON.

"Verbose?" is useful if the user want to see the output on the console (although it can make the simulation slower depending on the size of the network).

"filter-list?" if is set ON, the ranked list will be filtered, and the peer will only get document he doesn't already like in the final ranked list, otherwise without the filtering he will get the list as is.

We have implemented two utility functions (score-metrics) to calculate the score for the peers. Both functions increment the score for a peer when he gets a hit in the top K, the difference between the two, is that one (Hachemi-score) decrements the score when there is a miss in the top K, and the other one (Babak-score) doesn't.

"popular-p-filter?" is used to filter out popular peers without documents, or in the case that active peer is the most popular one, so he doesn't figure in the list of peers.

"stop?" this switch enables the simulation to stop after a set of ticks predefined by the user (e.g. if maximum ticks is 3000 and switch is ON, then the simulation would automatically stops when it reached 3000 ticks, otherwise it will run until it's manually stopped)

"adapt?" if activated, runs a function for the peers to let them change their strategy and adapt if they run into a set of consecutive failures (set 5 by default, but you can easily change than in set_variables.nls)

## Things to notice and try

When you run the simulation you can see that there are different colors for each population of peers, crowd followers are green, friend followers are violet, random peers are orange, and attackers are red. (note that ou can change any of these colors as they are variables in set_variables.txt then generate the .nls file)

You can trie adjusting the number of peers and documents, and change the distribution of documents accross the network, and see what happens. You can play with the populations, set different sizes and see how they fare by comparing their scores. There are many things to try, seing as there are various parameters you can change, now it's up to your imagination.

## EXTENDING THE MODEL

This model is surely not complete, and there are different ways to extend it: adding new metrics for ranking, adding new behaviors, than means new population of peers (e.g. some ideas, anti-social peers: peers that don't follow anyone, advertiser peers: peers that want other peers to like their documents and have a different utility function for calculating their score).

There are also some improvements to be made in regards of the current code, we would like to optimize the code so it runs faster, for example instead of going through all the peers, we can choose a new efficient method for selecting just a few, or maybe filtering peers that are too far on the graph (distant neighbors) or are not reachable.

## NETLOGO FEATURES

We have made extensive use of lists and and special features of agents and agentsets, especially for ranking and filtering.


