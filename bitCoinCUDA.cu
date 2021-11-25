
//#include <openssl/sha.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/time.h>
#include "sha256.cu"
 
#define SHA256_DIGEST_SIZE 32
#define repeats  1000
#define NUM_BLOCKS 1024


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


void hex2bin(unsigned char* dest, const char* src)
{
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
 

__device__ void print_hash(unsigned char hash[])
{
   int idx;
   for (idx=0; idx < 32; idx++)
      printf("%02x",hash[idx]);
   printf("\n");
}
 

__device__ __host__ void byte_swap(unsigned char* data) {
        int c;
        unsigned char tmp[SHA256_DIGEST_SIZE];
       
        c=0;
        while(c<SHA256_DIGEST_SIZE)
        {
                tmp[c] = data[SHA256_DIGEST_SIZE-(c+1)];
                c++;
        }
       
        c=0;
        while(c<SHA256_DIGEST_SIZE)
        {
                data[c] = tmp[c];
                c++;
        }
}

__global__ void doCalc(unsigned char *dev_prev_block, unsigned char *dev_merkle_root, int seed) {
    int i;   
    block_header header;
    header.version =        2;
    header.timestamp =      1392872245;
    header.bits =           419520339;

    for(i=0;i<32;i++) {
        header.prev_block[i] = dev_prev_block[i];
        header.merkle_root[i] = dev_merkle_root[i];

    }



    unsigned char hash1[32];
    unsigned char hash2[32];
   

    SHA256_CTX sha256_pass1, sha256_pass2;

    header.nonce = (seed *  blockDim.x * NUM_BLOCKS) + blockIdx.x * blockDim.x + threadIdx.x*repeats;
  

    for(i=0;i<repeats;i++) {
        sha256_init(&sha256_pass1);

        sha256_update(&sha256_pass1, (unsigned char*)&header, sizeof(block_header));

        sha256_final(&sha256_pass1,hash1);
           
         
        sha256_init(&sha256_pass2);
        sha256_update(&sha256_pass2, hash1, SHA256_DIGEST_SIZE);
        sha256_final(&sha256_pass2, hash2);
         if ( header.nonce == 0 || header.nonce == 3 || header.nonce == 856192328 ) {
             //hexdump((unsigned char*)&header, sizeof(block_header));
             //printf("%u:\n", header.nonce);
             byte_swap(hash2);
             //printf("Target Second Pass Checksum: \n");
             //print_hash(hash2);
         }
        header.nonce++;
    }
}

int main() {
    int i = 0;
    int blocksize = 16;
    int threads = 128;

    long long hashes = 0;

    int counter = 0;

    unsigned char *dev_merkle_root, *dev_prev_block;

    unsigned char prev_block[32], merkle_root[32];

    hex2bin(prev_block,              "000000000000000117c80378b8da0e33559b5997f2ad55e2f7d18ec1975b9717");
    hex2bin(merkle_root,             "871714dcbae6c8193a2bb9b2a69fe1c0440399f38d94b3a0f1b447275a29978a");


    byte_swap(prev_block);
    byte_swap(merkle_root);

   

    cudaMalloc((void**)&dev_prev_block, 32*sizeof(unsigned char));
    cudaMemcpy(dev_prev_block, &(prev_block), 32 * sizeof(unsigned char), cudaMemcpyHostToDevice);

    cudaMalloc((void**)&dev_merkle_root, 32*sizeof(unsigned char));
    cudaMemcpy(dev_merkle_root, &(merkle_root), 32 * sizeof(unsigned char), cudaMemcpyHostToDevice);

    double start = When();
    double timer = When() - start;
    while ( timer < 60.0){

        doCalc<<< blocksize, threads >>>(dev_prev_block, dev_merkle_root, counter);
        hashes += blocksize*threads*repeats;
        counter++;
        timer = When() - start;
   
        cudaDeviceSynchronize();
    }
 
    printf("number of hashs per second = %lld\n",(long long) (hashes / (When() - start)) );

 
    return 0;
}
