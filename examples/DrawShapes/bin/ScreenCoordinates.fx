cbuffer screenProjectionBuffer : register(b0)
{
    matrix projection;
};
    
struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
    float4 col : COLOR;
};
    
struct VS_INPUT
{
    float4 pos : POSITION;
    float4 col : COLOR;
};
    
VS_OUTPUT VS_Main(VS_INPUT input)
{
    VS_OUTPUT output;
    
    output.pos = mul(projection, float4(input.pos.xy, 0.f, 1.f));
    output.col = input.col;
    
    return output;
}
    
float4 PS_Main(VS_OUTPUT input) : SV_TARGET
{
    return float4(input.col);
}