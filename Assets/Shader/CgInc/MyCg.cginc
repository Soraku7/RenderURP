#ifdef MY_CGINC
#define MY_CGINC

float3 TriColAmbient(float3 n , float3 uCol , float3 sCol , float3 dCol)
{
    float uMask = max(n.g , 0.0);
    float dMask = max(-n.g , 0.0);
    float sMask = 1.0 - uMask - dMask;

    float3 envCol = uCol * uMask + sCol * sMask + dCol * dMask;
    return envCol;
}

#endif