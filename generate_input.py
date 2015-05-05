import fileinput
from tempfile import mkstemp
from shutil import move
from os import remove
import sys
 
def replace(source_file_path, pattern, substring):
    fh, target_file_path = mkstemp()
    with open(target_file_path, 'w') as target_file:
        with open(source_file_path, 'r') as source_file:
            for line in source_file:
                target_file.write(line.replace(pattern, substring))
                remove(source_file_path)
                move(target_file_path, source_file_path)

print("How many peers do you want?")
size = input()
print("How many docs do you want?")
docs = input()
print("""For how many ticks do you want the simulation to run?
(remember there is a switch in the GUI called stop, turn in off if you want the simulation to run freely)""")
ticks = input()
print(type(ticks))
print("""Choose the number of maximum likes for each peer at the start?
(preferably proportional to the number of peers and documents in the network)""")
likes = input()

numPeers = "num-peers "+ str(size)
numDocs = "num-docs " +str(docs)
maxTicks = "maxTicks " + str(ticks)   #default is 2000
maxLikes = "max-docs-stored " + str(likes)  #default is 3

infile = open('set_variables.txt')
outfile = open('set_variables.nls', 'w')

replacements = {'num-peers ':numPeers, 'num-docs':numDocs, 'maxTicks 2000':maxTicks, 'max-docs-stored 3':maxLikes}  #using a dictionary for storing the variables to update the file

for line in infile:
    try:
        for src, target in replacements.iteritems():
            line = line.replace(src, target)
        outfile.write(line)
    except:
        try:
            for src, target in replacements.items():
                line = line.replace(src, target)
            outfile.write(line)
        except:
            print("incompatible version - apologies for hack code")

infile.close()
outfile.close()
if ticks == '':
    ticks == 2000
print("You now have a network of %d peers and %d documents, the simulation will run for %d ticks" % (int(size), int(docs), int(ticks)))
