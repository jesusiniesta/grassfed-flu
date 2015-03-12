
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <limits.h>

#define max(x,y) (x>y)?x:y
#define min(x,y) (x<y)?x:y

#define d2r (M_PI / 180.0)

//calculate haversine distance for linear distance
double haversine_km(double long1, double lat1, double long2, double lat2)
{
    double dlong = (long2 - long1) * d2r;
    double dlat = (lat2 - lat1) * d2r;
    double a = pow(sin(dlat/2.0), 2) + cos(lat1*d2r) * cos(lat2*d2r) * pow(sin(dlong/2.0), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    double d = 6367 * c;

    return d;
}

double haversine_nounit(double long1, double lat1, double long2, double lat2)
{
    double dlong = (long2 - long1) * d2r;
    double dlat = (lat2 - lat1) * d2r;
    double a = pow(sin(dlat/2.0), 2) + cos(lat1*d2r) * cos(lat2*d2r) * pow(sin(dlong/2.0), 2);
    
    // since atan and product are order-preserving operations, I can stop here

    return a;
}

typedef struct 
{
    uint  * timestamp;
    float * lon;
    float * lat;
    uint  * town_idx;
} Tweets_t;

Tweets_t Tweets_init(uint n) {
	Tweets_t t;
	t.timestamp = calloc(n, sizeof(uint));
	t.lon       = calloc(n, sizeof(float));
	t.lat       = calloc(n, sizeof(float));
	t.town_idx  = calloc(n, sizeof(uint));
	return t;
}

void Tweets_free(Tweets_t t) {
	free(t.lon);
	free(t.lat);
	free(t.timestamp);
	free(t.town_idx);
}

typedef struct 
{
    float * lon;
    float * lat;
} Towns_t;

Towns_t Towns_init(uint n) {
	Towns_t t;
	t.lon       = calloc(n, sizeof(float));
	t.lat       = calloc(n, sizeof(float));
	return t;
}

void Towns_free(Towns_t t) {
	free(t.lon);
	free(t.lat);
}

int main (int argc, char ** argv) 
{
	if (argc < 5) {
        printf("wrong invocation\n\n./program num_tweets tweets_file num_towns towns_file\n\nfor example:\n\t./get_towns `wc -l test_tweets.csv` `wc -l test_towns.csv`\n");
        return -1;
    }

    int num_tweets  = atoi(argv[1]);
	char* tweets_fn = argv[2];
	int num_towns   = atoi(argv[3]);
	char* towns_fn  = argv[4];

    printf("get_towns:");
    printf("\tnum_tweets=%d\n", num_tweets);
    printf("\ttweets_fn =%s\n", tweets_fn);
    printf("\tnum_towns =%d\n", num_towns);
    printf("\ttowns_fn  =%s\n", towns_fn);

	Towns_t towns   = Towns_init(num_towns);
	Tweets_t tweets = Tweets_init(num_tweets);

	//read
	FILE *ftweets, *ftowns;

	ftweets = fopen(tweets_fn, "r");
	ftowns = fopen(towns_fn, "r");

	uint rownum=0;
    char * line = NULL;
    size_t len = 0;
    size_t read;

    while ((read = getline(&line, &len, ftweets)) != -1) {
        sscanf(line, "%d,%f,%f", &(tweets.timestamp[rownum]), &(tweets.lat[rownum]), &(tweets.lon[rownum]));
        ++ rownum;
    }

    rownum=0;
    while ((read = getline(&line, &len, ftowns)) != -1) {
        sscanf(line, "%f,%f", &(towns.lat[rownum]), &(towns.lon[rownum]));
        ++ rownum;
    }

    if (line) {
        free(line);
    }

    // show:
//     printf("first tweets:\n");
//     for (rownum=0; rownum < 10; rownum++) {
//     	printf("%d\t:\t%d - %f - %f\n", rownum, tweets.timestamp[rownum], tweets.lat[rownum], tweets.lon[rownum]);
//     }
//     printf("\nfirst towns:\n");
//     for (rownum=0; rownum < 10; rownum++) {
//     	printf("%d\t:\t%f - %f\n", rownum,  towns.lat[rownum], towns.lon[rownum]);
//     }
//     printf("\n");


	// find closest
	uint i,j,min_j;
	float d, min_d;

	for (i=0; i<5 /*num_tweets*/; i++) {
		min_d = UINT_MAX;
		for (j=0; j<5 /*num_towns*/; j++) {
			d = haversine_nounit(tweets.lon[i], tweets.lat[i], towns.lon[j], towns.lat[j]);
                           d, tweets.lon[i], tweets.lat[i], towns.lon[j], towns.lat[j]);
			if (d < min_d) {
				min_d = d;
				min_j = j;
			}
		}
		tweets.town_idx[i] = min_j;
	}

	// print results
	for (rownum=0; rownum<5; rownum++) {
		printf("%d - %d\n", rownum, tweets.town_idx[rownum]);
	}

    Tweets_free(tweets);
    Towns_free(towns);

	return 0;
}
