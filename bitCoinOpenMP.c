#ifdef fail
        #!/bin/bash
        # NOTE you can chmod 0755 this file and then execute it to compile (or just copy and paste)
        gcc -o hashblock hashblock.c -lssl
        exit 0
#endif
 
#include <openssl/sha.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <omp.h>
 

typedef struct block_header {
        unsigned int    version;
        
        unsigned char   prev_block[32];
        unsigned char   merkle_root[32];
        unsigned int    timestamp;
        unsigned int    bits;
        unsigned int    nonce;
} block_header;
 
double When()
{
    struct timeval tp;
    gettimeofday(&tp, NULL);
    return ((double) tp.tv_sec + (double) tp.tv_usec * 1e-6);
}

void hex2bin(unsigned char* dest, unsigned char* src)
{
        unsigned char bin;
        int c, pos;
        char buf[3];
 
        pos=0;
        c=0;
        buf[2] = 0;
        while(c < strlen(src))
        {
                
                buf[0] = src[c++];
                buf[1] = src[c++];
                
                dest[pos++] = (unsigned char)strtol(buf, NULL, 16);
        }
       
}
 


 

void byte_swap(unsigned char* data, int len) {
        int c;
        unsigned char tmp[len];
       
        c=0;
        while(c<len)
        {
                tmp[c] = data[len-(c+1)];
                c++;
        }
       
        c=0;
        while(c<len)
        {
                data[c] = tmp[c];
                c++;
        }
}
 
int main() {
    
    block_header header;
   
    
    unsigned char hash1[SHA256_DIGEST_LENGTH];
    unsigned char hash2[SHA256_DIGEST_LENGTH];
   
    
    SHA256_CTX sha256_pass1, sha256_pass2;

    
    double start = When();
    double timer = When() - start;
    unsigned int counter =0;
    #pragma omp parallel private(header)
    {
        
        
        header.version =        2;
        hex2bin(header.prev_block,              "000000000000000117c80378b8da0e33559b5997f2ad55e2f7d18ec1975b9717");
        hex2bin(header.merkle_root,             "871714dcbae6c8193a2bb9b2a69fe1c0440399f38d94b3a0f1b447275a29978a");
        header.timestamp =      1392872245;
        header.bits =           419520339;
        header.nonce =          0;
       
        
        byte_swap(header.prev_block, 32); 
        byte_swap(header.merkle_root, 32); 
       
        
        
        
        while ( timer < 60.0){
            #pragma omp critical 
            {
                header.nonce = counter;
                counter ++; 
                if ( counter % 800000 == 0){
                    timer = (When() - start);
                }
            }
      
            
            SHA256_Init(&sha256_pass1);
            
            SHA256_Update(&sha256_pass1, (unsigned char*)&header, sizeof(block_header));
            
            SHA256_Final(hash1, &sha256_pass1);
               
            SHA256_Init(&sha256_pass2);
            SHA256_Update(&sha256_pass2, hash1, SHA256_DIGEST_LENGTH);
            SHA256_Final(hash2, &sha256_pass2);
            
        }
    }
       printf("number of hashs per second = %f\n",counter / 60.0 );

 
        return 0;
}
