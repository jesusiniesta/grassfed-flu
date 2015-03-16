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
    state_names = {'s': 'healthy', 'i': 'infected', 'r': 'recovered' }

    def __init__(self, id, step, region):
        self.id       = id
        self.state    = 's'
        self.step     = step
        self.region   = region

    def __str__(self):
        return "user "+str(self.id)+" lives in "+self.region+" and is "+self.state_names[self.state]+" since step "+str(self.step)+""

    def shortstr(self):
        return str(self.id)+"("+self.region+","+self.state+")"

    def readable_state(self): 
        return self.state_names[self.state]

    def healthy(self):
        return self.state == 's'
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
@click.option('-l', "Lambda",       default=0.4,    help='Lambda.')
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
        if (u.region == 'M' and random() < 0.5):
            u.state = 'i'


    ########################################
    ## SEIR model

    def contact(u1, u2, step):
        verbose= u1.infected() or u2.infected()
        if verbose:
            print(u1.shortstr() + " meets " + u2.shortstr() + " at step " +
                   str(step))

        if (u1.infected() and u2.healthy()):
            u2.state = 'i'
            u2.step = step
            #print("infected!" + str(u2.id) + " in " + u2.region )
            #print(str(u2))
            if (verbose) : print("now: " + str(u2))
            return u2.id
        elif (u1.healthy() and u2.infected()):
            u1.state = 'i'
            u1.step = step
            #print("infected!" + str(u1.id) + " in " + u1.region )
            #print(str(u1))
            if (verbose) : print("now: " + str(u1))
            return u1.id
        else: 
            return 0

    def turn_infectious(u, step):
        #print(str(u.id) + "'s been "+u.state+" for " + str(step - u.step))
        if (u.exposed() and u.step > (step + exposedtime)):
            #print("\t... and now is infectious")
            u.step = step
            u.state = 'i'
        #print(u.state)

    ########################################
    ## simulation loop


    step = 1
    start_of_step = encounters[0].time
    next_step = start_of_step + steplength
    done = set()
    new_infections = 0

    infected_users = dict()

    for enc in encounters:
        
        # NEXT STEP
        if enc.time > next_step:
            #print("finished step "+str(step)+", got " + str(new_infections) + " new infections")

            start_of_step = next_step
            next_step += steplength
            step  += 1
            new_infections=0
            done = set()
            #print("going for step " + str(step))
        
            #infectious users may recover
            for ui in infected_users:
                if infected_users[ui] and users[ui].infected() and users[ui].step > (step+recoverytime):
                    print(str(users[ui].id)+" became infected in "+users[ui].region+"!")
                    users[ui].state = 'r'
                    infected_users[ui] = False


        u1 = users[enc.u1]
        u2 = users[enc.u2]
            

        # infection?
        if ((u1.id, u2.id) not in done):
            infected = contact(u1,u2,step)
            if infected:
                new_infections+=1
                print("añado " + str(infected) + " a la lista de infectados")
                infected_users[infected] = True
            done.add((u1.id, u2.id))
        
    # end of main loop

    ########################################
    ## output
        
    for ui in users:
        print(str(users[ui]))

    counted_regions = set()
    per_region_count = {"s":{}, "e":{}, "i":{}, "r":{}, }

    for ui in users:
        
        istate  = users[ ui ].state
        iregion = users[ ui ].region 
        
        if iregion not in counted_regions:
            per_region_count[ "s" ][ iregion ] = 0
            per_region_count[ "e" ][ iregion ] = 0
            per_region_count[ "i" ][ iregion ] = 0
            per_region_count[ "r" ][ iregion ] = 0
            counted_regions.add(iregion)

        per_region_count[ istate ][ iregion ] += 1

    for iregion in counted_regions:
        print("in "+iregion+" there were \n\t" + 
               str(per_region_count["s"][iregion]) + " healthy,\n\t" + 
               str(per_region_count["e"][iregion]) + " exposed,\n\t" + 
               str(per_region_count["i"][iregion]) + " infected,\n\t" + 
               str(per_region_count["r"][iregion]) + " recovered\n\t")


if __name__ == '__main__':
    mymain()
