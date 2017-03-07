#!/bin/bash
#Read the file line by line
#Declare an array containing the queries
queries=(6 7 9 12 13 14 15 16 17 21 22 24)
queriesLen=${#queries[@]}
#This function shuffles the elements of an array in-place using the 
#Knuth-Fisher-Yates shuffle algorithm. 
shuffle() {
   local i tmp size max rand

   # $RANDOM % (i+1) is biased because of the limited range of $RANDOM
   # Compensate by using a range which is a multiple of the array size.
   size=${#queries[*]}
   max=$(( 32768 / size * size ))

   for ((i=size-1; i>0; i--)); do
      while (( (rand=$RANDOM) >= max )); do :; done
      rand=$(( rand % (i+1) ))
      tmp=${queries[i]} queries[i]=${queries[rand]} queries[rand]=$tmp
   done
}


while IFS='' read -r line || [[ -n "$line" ]]; do
    #echo "Text read from file: $line"
    #Tokenize the line read to separate the different numbers
    for word in $line; do 
        #echo "Word read from file: $word"
        #Convert the floating point number read into an integer
        #IMPORTANT: the number is truncated
        workLoad=${word%.*}
        echo "$workLoad"
        #Generate the schedule for each workload
        #shuffle
        for ((i=1;i<=workLoad;i++)); do
            #The two lines below enable to chose a query randomly,
            #thus repetition can occur
            #Add zero since positions in the array begin with 0
            queryIdx="$((o + (RANDOM % queriesLen)))"
            query=${queries[queryIdx]}
            #The line below uses the fact that the queries array
            #has been shuffled, thus avoiding the possible repetition
            #of a query. However, there must be sufficient queries in
            #order to fulfill the schedule.
            #query=${queries[i]}
            printf "%s "  "$query"
        done
        echo ""
    done
done < "$1"
