/**************************************************************************
 *
 * input: a file like:
 *      timespan|lat|lon|my_id|mentions(my_id)|hashtags
 *
 * * It has to be ordered by timestamp (sort will do)
 *
 * this version will NOT discard duplicated links
 *
**************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#define max(x,y) (x>y)?x:y
#define min(x,y) (x<y)?x:y

uint NUM_TWEETS = 3096327;

// Tweet structure
typedef struct 
{
    uint  timestamp;
    float lng;
    float lat;
    uint  id;
} Tweet;

/* function definitions */

float   GetDistance    ( Tweet t1, Tweet t2 );
void    PrintPair      ( Tweet a, Tweet b );
Tweet * ReadTweetsFile ( char * filename, uint * numTweets );

/* main */

uint main (uint argc, char * argv[])
{
    char * filename = NULL;
    uint   timespan;        //s
    float  max_distance;    //km
    uint   i;
    int    numTweets;
    int    lines_count;

    // inputs

    if (argc != 5) {
        printf("%d arguments received; %d expected\n", argc-1, 5-1);
        printf("examples:\n\t./get_g 3600 0.5  `wc -l  usernloc.madrid_kinda.2013-08.dat` > encounters.madrid_kinda.2013-08.el\n");
        printf("\t./get_g 1 `wc -l  usernloc.madrid_kinda.2013-08.dat` > encounters.madrid_kinda.2013-08.el\n");
        printf("that is:\n\t./get_g timespan(s) max_distance(km) lines_count input_file > output_file\n");
        printf("\t./get_g timespan(s) max_distance(km) lines_count input_file > output_file\n");
        exit(-3);
    } else {
        timespan = atoi(argv[1]);
        max_distance = atof(argv[2]);
        lines_count = atoi(argv[3]); //this is just for eyecandy; could be made optional
        filename = argv[4];

        fprintf(stderr, "%ds %fkm %s; %d lines \n", timespan, max_distance, filename, lines_count);
    }

    Tweet * t = ReadTweetsFile(filename, &numTweets);

    /* (los tweets vienen ordenados por timestamp)
     * por cada tweet Ti
     *     comprobar todos los anteriores Tj
     *        si Tj está demasiado atrás en el tiempo, dado que la lista está ordenada, no hace falta seguir 
     *        si Tj está cerca en el espacio y en el tiempo: añadir enlace    
     */
    fprintf(stderr,"\n");
    
    for (i=1; i<numTweets; ++i) 
    {
        uint j;
        uint timei = t[i].timestamp,
            useri = t[i].id;

        for (j=i-1; j>0; --j) 
        {
            uint userj = t[j].id,
                timej = t[j].timestamp;

            uint timediff = abs(timej-timei);
            if (timediff <= timespan) {

                if (userj != useri) {

                    float d = GetDistance(t[i], t[j]);
                        
                    if (d <= max_distance) {
                        PrintPair(t[i], t[j]);
                    }
                }

            } else {
                // está demasiado lejos => ya no vamos a encontrar nada
                break;
            }
        }

        // mostrar % de progreso
        if (i%5000 == 0) {
            fprintf(stderr, "%.2f%% (%d/%d)\r ", ((float)i*100)/lines_count, i, lines_count);
            //printf("\a");
        }
    }
    
    fprintf(stderr,"\n");
    return 0;
}


/* ###################################################################### */



/* Distances */

//km
float CalculateDistance( float nLon1, float nLat1, float nLon2, float nLat2 )
{
    uint nRadius = 6371; // Earth's radius in Kilometers
    // Get the difference between our two points
    // then convert the difference into radians
    float nDLat = (nLat2 - nLat1) * (M_PI/180);
    float nDLon = (nLon2 - nLon1) * (M_PI/180);
    float nA = pow ( sin(nDLat/2), 2 ) + cos(nLat1) * cos(nLat2) * pow ( sin(nDLon/2), 2 );
 
    float nC = 2 * atan2( sqrt(nA), sqrt( 1 - nA ));
    float nD = nRadius * nC;
 
    return nD; // Return our calculated distance
}

float GetDistance(Tweet t1, Tweet t2) {
    return CalculateDistance(t1.lng, t1.lat, t2.lng, t2.lat);
}

/* Tweets management */

void PrintTweet(Tweet t)
{
    printf("%d %f %f %d\n", t.timestamp, t.lng, t.lat, t.id);
}

void PrintPair(Tweet a, Tweet b) 
{
    if (a.id < b.id) {
        printf("%d %d\n", a.id, b.id);
    } else {
        printf("%d %d\n", b.id, a.id);
    }
}

// reads a tweet from a string to a Tweet struct 
Tweet ReadTweet(char * csv)
{
    const char s[] = "|";
    char *token;
    uint i = 0;
    Tweet t;

    token = strtok(csv, s);

    while( token != NULL ) 
    {
        if (i == 0) {
            t.timestamp = atoi(token);
        } else if (i == 1) {
            t.lng = atof(token);
        } else if (i == 2) {
            t.lat = atof(token);
        } else if (i==3) {
            t.id = atoi(token);
        }

        token = strtok(NULL, s);
        ++i;
    }

    return t;   
}

// returns an array of tweets
Tweet * ReadTweetsFile (char * filename, uint * numTweets)
{
    Tweet * pt = NULL;
    pt = calloc(NUM_TWEETS, sizeof(Tweet));
    uint i = 0;

    FILE * fp;
    char * line = NULL;
    size_t len = 0;
    size_t read;

    fp = fopen(filename, "r");
    if (fp == NULL) {
        exit(-1);
    }

    while ((read = getline(&line, &len, fp)) != -1) {
        Tweet t = ReadTweet(line);
        pt[i] = t;

        ++i;
    }

    *numTweets = i;

    if (line) {
        free(line);
    }

    return pt;
}
