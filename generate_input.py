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
numPeers = "num-peers "+ str(size)
numDocs = "num-docs " +str(docs)
maxTicks = "maxTicks " + str(ticks)   #default is 2000

infile = open('set_variables.txt')
outfile = open('set_variables.nls', 'w')

replacements = {'num-peers ':numPeers, 'num-docs':numDocs, 'maxTicks 2000':maxTicks}  #using a dic() for storing the variables to update the file

for line in infile:
    for src, target in replacements.iteritems():
        line = line.replace(src, target)
    outfile.write(line)

infile.close()
outfile.close()
if ticks == '':
    ticks == 2000
print("You now have a network of %d peers and %d docuements, the simulation will run for %d ticks" % (size, docs, ticks))


##def replaceAll(file,searchExp,replaceExp):
##    for line in fileinput.input(file, inplace=1):
##        if searchExp in line:
##            line = line.replace(searchExp,replaceExp)
##        sys.stdout.write(line)
##
##fin = open("set_variables.txt")
##fout = open("set_variables.nls", "wt")
##for line in fin:
##    fout.write( line.replace('num-peers', 'num-peers 20') )
##    fout.write( line.replace('num-docs', 'num-docs 40') )
##fin.close()
##fout.close()
              
#replace('set_variables.nls', "num-peers",size)
 
##if __name__ == '__main__':
##    if len(sys.argv) == 4:
##        replace(sys.argv[1], sys.argv[2], sys.argv[3])
##    else:
##        print """Invalid command
##Usage: python replacelinesinfile.py [source_file_path] [pattern] [substring]
##""" 
