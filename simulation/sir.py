#!/usr/bin/python3.4

import click                       # arguments management
from random import random, randint # random number generation
import sys                         # stderr

##############################################################
## DATA

VERBOSE = True
def LogIf(msg, flag = VERBOSE):
    if True:
        print(msg, file=sys.stderr)

class Encounter:
    def __init__(self, u1, u2, time):
        self.u1 = u1
        self.u2 = u2
        self.time = time

class User:
    state_names = {'s': 'healthy', 'i': 'infected', 'r': 'recovered' }
    def __init__(self, id, region):
        self.id       = id
        self.state    = 's'
        self.istep    = -1
        self.rstep    = -1
        self.region   = region

    def __str__(self):
        return "user "+str(self.id)+" lives in "+self.region+" and is "+self.state_names[self.state]+" since step "+str(self.step)+""

    def shortstr(self):       return str(self.id)+"("+self.region+","+self.state+")"
    def readable_state(self): return self.state_names[self.state]
    def healthy(self):        return self.state == 's'
    def infected(self):       return self.state == 'i'
    def recovered(self):      return self.state == 'r'

def ReadUsers(filename):
    users = dict()
    for line in open(filename):
        parts = line.strip().split('|')
        users[int(parts[0])] = User(id=int(parts[0]), region=parts[4])
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
@click.option('-l', "Lambda",       default=0.4,    help='Lambda.')
@click.option('-r', "recoverytime", default=5*24*2, help='time to recovery, in steps (default=5 days).')
@click.option("-p", "printmode",    default='a',    help="a => weekly by-region aggregation; i => each infection")
@click.option("-g", "granularity",  default='p',    help="granularity, provincia (p) or comunidad (c)")


def mymain(encountersfile, usersfile, steplength, Lambda, recoverytime, printmode, granularity):

    ########################################
    ## input

    steps_per_week  = (7*24*60)/steplength # minutes
    steplength_s    = steplength*60
    granularity     = granularity.lower()

    printmode       = 'aggregation' if (len(printmode) > 0 and printmode[0].lower() == 'a') else 'infections'
    print_aggregate = printmode == 'aggregation'

    granularity     = 'provincia' if (len(granularity) > 0 and granularity[0].lower() == 'a') else 'comunidad'

    click.echo(' ****************************',                   file=sys.stderr)
    click.echo(' * encounters file:   %s'    % encountersfile,    file=sys.stderr)
    click.echo(' * users file:        %s'    % usersfile,         file=sys.stderr)
    click.echo(' * step length (min): %d'    % steplength,        file=sys.stderr)
    click.echo(' * Lambda:            %0.3f' % Lambda,            file=sys.stderr)
    click.echo(' * stepsrecovery:     %d'    % recoverytime,      file=sys.stderr)
    click.echo(' * steps per week:    %d'    % steps_per_week,    file=sys.stderr)
    click.echo(' * printmode:         '+printmode,                file=sys.stderr)
    click.echo(' *      (aggregation: '+str(print_aggregate)+')', file=sys.stderr)
    click.echo(' * granularity:       '+granularity,              file=sys.stderr)

    click.echo(' ****************************',                   file=sys.stderr)

    users = ReadUsers(usersfile)
    encounters = ReadEncounters(encountersfile)

    ########################################
    ## output

    def print_summary(week, users):
        counted_regions = set()
        per_region_count = {"s":{}, "i":{}, "r":{}, }

        for ui in users:

            istate  = users[ ui ].state
            iregion = users[ ui ].region

            if iregion not in counted_regions:
                per_region_count[ "s" ][ iregion ] = 0
                per_region_count[ "i" ][ iregion ] = 0
                per_region_count[ "r" ][ iregion ] = 0
                counted_regions.add(iregion)

            per_region_count[ istate ][ iregion ] += 1

        for iregion in counted_regions:
            print(str(week) + "|" + str(iregion) + "|" +
                   str(per_region_count["s"][iregion]) + "|" +
                   str(per_region_count["i"][iregion]) + "|" +
                   str(per_region_count["r"][iregion]) + "|")

    ########################################
    ## infect some fuckers in madrid

    madrilenos = [u for u in users.values() if u.region == 'M']

    for u in madrilenos:
        if (u.region == 'M'): # and random() < 0.5):
            u.state = 'i'
            u.istep = 0


    ########################################
    ## SEIR model

    def contact(u1, u2, step):

        if (u1.infected() and u2.healthy()):
            u2.state = 'i'
            u2.istep = step
            LogIf("\t\tuser 2, #{0}, becomes infected at step {1}".format(u2.id, u2.istep))
            return u2.id
        elif (u1.healthy() and u2.infected()):
            u1.state = 'i'
            u1.istep = step
            LogIf("\t\tuser 1, #{0}, becomes infected at step {1}".format(u1.id, u1.istep))
            return u1.id
        else:
            return 0

    ########################################
    ## simulation loop


    step = 1
    week = 1 # to track the advancement of the disease each week
    start_of_step = encounters[0].time
    next_step = start_of_step + steplength_s
    done = set()
    new_infections = 0

    infected_users = dict()

    for enc in encounters:

        # NEXT STEP
        if enc.time > next_step:

            LogIf("new week, at {0} starts week #{1}".format(next_step, step))

            start_of_step = next_step
            next_step += steplength_s
            step  += 1
            new_infections=0
            done = set()

            #infectious users may recover
            for ui in infected_users:
                if infected_users[ui] and users[ui].infected() and users[ui].istep > (step+recoverytime):
                    #~ print(str(users[ui].id)+" became infected in "+users[ui].region+"!")
                    users[ui].state = 'r'
                    users[ui].rstep = step
                    infected_users[ui] = False

            if print_aggregate:
                if ((step % steps_per_week) == 1): # first step after week change
                    week += 1
                    print_summary(week, users)

        u1 = users[enc.u1]
        u2 = users[enc.u2]

        LogIf("\t{0}, {1} from {2}, meets {3}, {4} from {5}".format(
              u1.id, u1.readable_state(), u1.region,
              u2.id, u2.readable_state(), u2.region))

        # infection?
        if ((u1.id, u2.id) not in done):
            infected = contact(u1,u2,step)
            if infected:
                new_infections+=1
                LogIf("\tañado " + str(infected) + " a la lista de infectados")
                infected_users[infected] = True

            done.add((u1.id, u2.id))

    # end of main loop

    # print final state too
    if print_aggregate:
        print_summary("end", users)
    else:
        su = sorted(users.values(), key= lambda u: u.istep)
        for u in su:
            if u.istep != -1:
                print(str(u.istep)+"|"+str(u.rstep)+"|"+str(u.id)+"|"+str(u.region))


if __name__ == '__main__':
    mymain()
