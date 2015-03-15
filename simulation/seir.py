#!/usr/bin/python3.4

import click                       # arguments management
from random import random, randint # random number generation

##############################################################
## DATA

class Encounter:
    def __init__(self, u1, u2, time):
        self.u1 = u1
        self.u2 = u2
        self.time = time

class User:
    state_names = {'s': 'healthy', 'e': 'exposed', 'i': 'infected', 'r': 'recovered' }

    def __init__(self, id, step, region):
        self.id       = id
        self.state    = 's'
        self.step     = step
        self.region   = region

    def __str__(self):
        return "user "+str(self.id)+" lives in "+self.region+" and is "+self.state_names[self.state]+" since step "+str(self.step)+""

    def readable_state(self): 
        return self.state_names[self.state]

    def healthy(self):
        return self.state == 's'
    def exposed(self):
        return self.state == 'e'
    def infected(self):
        return self.state == 'i'
    def recovered(self):
        return self.state == 'r'

def ReadUsers(filename):
    users = dict()
    for line in open(filename):
        parts = line.strip().split('|')
        users[int(parts[0])] = User(id=int(parts[0]), step=-1, region=parts[4])
    return users

def ReadEncounters(filename):
    encounters = list()
    for line in open(filename):
        parts = line.strip().split(' ')
        encounters.append(Encounter(int(parts[0]), int(parts[1]), int(parts[2])))
    return encounters




##############################################################
##

# make them global, just for fun
users = dict()
encounters = dict()

@click.command()
@click.option('--encountersfile',                   help='encounters file.' ,prompt=True)
@click.option('--usersfile',                        help='users file.', prompt=True)
@click.option('-s', "steplength",   default=30,     help='step length, in minutes (30 by default).')
@click.option('-e', "exposedtime",  default=4,      help='exposed steps.')
@click.option('-l', "Lambda",       default=0.3,    help='Lambda.')
@click.option('-r', "recoverytime", default=5*24*2, help='time to recovery, in steps (default=5 days).')

def mymain(encountersfile, usersfile, steplength, exposedtime, Lambda, recoverytime):

    ########################################
    ## input

    click.echo(' ***************************')
    click.echo(' * encounters file: %s'    % encountersfile)
    click.echo(' * users file:      %s'    % usersfile)
    click.echo(' * step length:     %d'    % steplength)
    click.echo(' * steps exposed:   %d'    % exposedtime)
    click.echo(' * Lambda:          %0.3f' % Lambda)
    click.echo(' * stepsrecovery:   %d'    % recoverytime)
    click.echo(' ***************************')

    users = ReadUsers(usersfile)
    encounters = ReadEncounters(encountersfile)

    ########################################
    ## infect some fuckers in madrid

    madrilenos = [u for u in users.values() if u.region == 'M']

    for u in madrilenos:
        if (u.region == 'M' and random() < 0.1):
            u.state = 'i'
    
    for ui in users:
        print(str(users[ui]))

    ########################################
    ## SEIR model

    def contact(u1, u2, step):
        if (u1.infected() and u2.healthy()):
            u2.state = 'e'
            u2.step = step
            print("infected" + str(u2.id) + " in " + u2.region )
            return True
        elif (u1.healthy() and u2.infected()):
            u1.state = 'e'
            u1.step = step
            print("infected" + str(u1.id) + " in " + u1.region )
            return True
        else: 
            return False

    def turn_infectious(u, step):
        if (u.exposed() and u.step > (step + exposedtime)):
            u.step = step
            u.state = 'i'

    ########################################
    ## simulation loop


    step = 1
    start_of_step = encounters[0].time
    next_step = start_of_step + steplength
    done = set()

    for enc in encounters:
        
        # NEXT STEP
        if enc.time > next_step:
            start_of_step = next_step
            next_step += steplength
            step  += 1
            done = set()
            #print("going for step " + str(step))

        u1 = users[enc.u1]
        u2 = users[enc.u2]

        # should any of both become infectious now?
        if (u1.id not in done):
            turn_infectious(u1, step)
            done.add(u1.id)

        if (u2.id not in done):
            turn_infectious(u2, step)
            done.add(u2.id)

        # infection?
        if ((u1.id, u2.id) not in done):
            contact(u1,u2,step)
            done.add((u1.id, u2.id))
        
    # end of main loop

    ########################################
    ## simulation loop
        


if __name__ == '__main__':
    mymain()
