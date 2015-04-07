/**************************************************************************
 *
 * input: a file like:
 *      0         1   2    3   4      5      6        7        8     9               10
 *      timestamp|lat|long|geo|region|userid|username|hashtags|my_id|mentioned_names|mentioned_ids
 *      101|37.950413|-4.478701|2518607|OH|186837676|almudenahermoso||1|monteost4,almudenahermoso|1

 *
 * it has to be ordered by timestamp (sort will do)
 *
 * it will NOT discard duplicated links
 *
**************************************************************************/

 /* 

 TODO: 

[ ] consistent style:
    [ ] underscored_names or camelCase
[X] update progress bar to work with several threads

*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <unistd.h>
#include <omp.h>

#define max(x,y) (x>y)?x:y
#define min(x,y) (x<y)?x:y

uint MAX_NUM_TWEETS = 10000000; //3096327;

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
void    PrintPair      ( FILE *f, Tweet a, Tweet b, uint time ); 
Tweet * ReadTweetsFile ( char * filename, uint * numTweets );
void    FreeTweets (Tweet * t);

/* main */

int main (int argc, char * argv[])
{
    Tweet* t = NULL; // tweets array

    struct Global_t
    {
        uint   timespan;
        float  max_distance;
        char*  output_fn;
        uint   numTweets;
    
        char aux_file_names[4][80];
    } Global;

    ////////////////////////////////////////
    // arguments and some preparation
    {
        char* filename = NULL;
        uint i;
        
        if (argc != 5) {
            printf("%d arguments received; %d expected\n", argc-1, 5-1);
            printf("examples:\n\t%s 3600 0.5 data/tweets.201308.dat encounters.201308.dat\n", argv[0]);
            printf(           "\t%s 3600 0.5 data/tweets.201308.dat encounters.201308.dat\n",        argv[0]);
            printf("that is:\n\t%s timespan(s) max_distance(km) input_file output_file\n",                            argv[0]);
            printf(          "\t%s timespan(s) max_distance(km) input_file output_file\n",                            argv[0]);
            exit(-3);
        } else {
            Global.timespan     = atoi(argv[1]);
            Global.max_distance = atof(argv[2]);
            filename            = argv[3];
            Global.output_fn    = argv[4];

            fprintf(stderr, "%ds %fkm %s \n", Global.timespan, Global.max_distance, filename);
        }

        t = ReadTweetsFile(filename, &(Global.numTweets));

        // name the auxiliary files
        for (i=0;i<4;++i) {
            sprintf(Global.aux_file_names[i], "aux_getg_%d.tmp", i);
        }
    }

    ///////////////////////////////////////////////////
    // algorithm
    /* (los tweets vienen ordenados por timestamp)
     * por cada tweet Ti
     *     comprobar todos los anteriores Tj
     *        si Tj está demasiado atrás en el tiempo, dado que la lista está ordenada, no hace falta seguir 
     *        si Tj está cerca en el espacio y en el tiempo: añadir enlace    
     */
    {

        uint i;
        FILE* aux_files[4] = {NULL,NULL,NULL,NULL};
        uint per_thread_count[4] = { 0, 0, 0, 0 };
        char bar[] = "          ";

        // open the auxilary files
        for (i=0;i<4;++i) {
            aux_files[i] = fopen(Global.aux_file_names[i], "w");
        }

        omp_set_num_threads(4);

        #pragma omp parallel for
        for (i=1; i<(Global.numTweets); ++i) 
        {
            int tid = omp_get_thread_num();
            FILE * f = aux_files[tid];

            uint j;
            uint timei = t[i].timestamp,
                 useri = t[i].id;

            for (j=i-1; j>0; --j) 
            {
                uint userj = t[j].id,
                     timej = t[j].timestamp;

                uint timediff = abs(timej-timei);
                if (timediff <= Global.timespan) {

                    if (userj != useri) {

                        float d = GetDistance(t[i], t[j]);
                            
                        if (d <= Global.max_distance) {
                            PrintPair(f, t[i], t[j], abs(timei+timej)/2);
                        }
                    }

                } else {
                    // está demasiado lejos => ya no vamos a encontrar nada
                    break;
                }
            }

            // mostrar % de progreso
            per_thread_count[tid] ++;
            if ((per_thread_count[tid] % 30000 + tid*10000) == 0) {
                uint total = per_thread_count[0] + per_thread_count[1] + per_thread_count[2] + per_thread_count[3];
                uint j;
                float percent = ((float)total*100)/(Global.numTweets);
                int   ipercent = (int)(percent / 10.0);
                for (j=0; j<ipercent; ++j) {
                    bar[j] = 'O';
                }
                fprintf(stderr, "[%s] %.2f%% (%d/%d)\r ", bar, percent, total, (Global.numTweets));
                //printf("\a");
            }
        }

        for (i=0; i<4; i++) {
            fclose(aux_files[i]);
        }
    }

    ///////////////////////////////////////////////////
    // reduce
    {
        FILE*  output_file = fopen(Global.output_fn, "w"); 
        char   line[666];
        uint   i;

        for (i=0; i<4; i++) {
            FILE * fp = fopen(Global.aux_file_names[i], "r");

            while (fgets(line, sizeof(line), fp)) {
                fprintf(output_file, "%s", line);    
            }

            fclose(fp);
            remove(Global.aux_file_names[i]);
        }

        fclose(output_file);

    }
    
    FreeTweets(t);
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

void PrintPair(FILE *f, Tweet a, Tweet b, uint time) 
{
    if (a.id < b.id) {
        fprintf(f, "%d\t%d\t%d\n", a.id, b.id, time);
    } else {
        fprintf(f, "%d\t%d\t%d\n", b.id, a.id, time);
    }
}

// reads a tweet from a string to a Tweet struct 
Tweet ReadTweet(char * csv)
{
    char *token=NULL, *string=NULL, *tofree=NULL;
    uint i = 0;
    Tweet t;

    tofree = string = strdup(csv);

    while ((token = strsep(&string, "|")) != NULL)
    {
        switch (i) {
            case 0:
                t.timestamp = atoi(token);
                break;
            case 1:
                t.lng = atof(token);
                break;
            case 2:
                t.lat = atof(token);
                break;
            case 10:
                t.id = atoi(token);
                break;

        }

        ++i;
    }

    free(tofree);

    return t;
}

void FreeTweets (Tweet * t)
{
    free(t);
}

// returns an array of tweets
Tweet * ReadTweetsFile (char * filename, uint * numTweets)
{
    Tweet * pt = NULL;
    pt = calloc(MAX_NUM_TWEETS, sizeof(Tweet));
    uint i = 0;
    FILE * fp;
    char line[666];

    fp = fopen(filename, "r");

    while (fgets(line, sizeof(line), fp)) {
        pt[i] = ReadTweet(line);
        ++i;
    }

    *numTweets = i;

    return pt;
}
